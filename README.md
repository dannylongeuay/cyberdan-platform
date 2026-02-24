# cyberdan-platform

Manage infrastructure and workloads for the cyberdan platform.

## Prerequisites

- [Nix](https://nixos.org/) with flakes enabled
- [direnv](https://direnv.net/)
- A DigitalOcean account with an API token
- A DigitalOcean Spaces access key pair (for OpenTofu state)
- The `cyberdan.dev` domain pointed to DigitalOcean nameservers

## Manual Setup

These steps must be completed before bootstrapping the cluster.

### 1. Enter the development shell

```bash
direnv allow
# or
nix develop
```

This provides: `opentofu`, `kubectl`, `kustomize`, `helm`, `argocd`, `sops`, `age`, `jq`, `yq`

### 2. Generate an age keypair

```bash
age-keygen -o age.key
```

Save the public key (starts with `age1...`) and store the private key (`age.key`) in a password manager as a backup.

### 3. Update `.sops.yaml`

Replace `AGE_PUBLIC_KEY` with your actual age public key:

```yaml
creation_rules:
  - path_regex: \.enc\.yaml$
    age: age1your_actual_public_key_here
```

### 4. Create a DigitalOcean managed SSL certificate

Create a certificate for `cyberdan.dev` and `*.cyberdan.dev` in the DigitalOcean console, then get the certificate ID:

```bash
doctl compute certificate list
```

Update `platform/ingress-nginx/values.yaml` with the certificate ID.

### 5. Create the Spaces bucket for OpenTofu state

```bash
doctl spaces create cyberdan-tofu-state --region nyc3
```

### 6. Update the repo URL in ArgoCD Applications

Update the `repoURL` field in all files under `apps/` to point to your GitHub repository.

## Bootstrap

### 1. Set environment variables

```bash
# DigitalOcean API token (used by OpenTofu and passed into the cluster)
export TF_VAR_do_token="your_do_api_token"

# Spaces credentials (used by the S3 backend)
export AWS_ACCESS_KEY_ID="your_spaces_access_key"
export AWS_SECRET_ACCESS_KEY="your_spaces_secret_key"
```

### 2. Provision the infrastructure

```bash
cd infrastructure/terraform
tofu init
tofu plan
tofu apply
```

This creates the DOKS cluster, DNS zone, and bootstrap Kubernetes secrets.

### 3. Configure kubectl

```bash
tofu output -raw kubeconfig > ~/.kube/config
# or merge into existing config:
# doctl kubernetes cluster kubeconfig save cyberdan
```

### 4. Create the age key secret

```bash
kubectl create secret generic sops-age \
  --namespace=argocd \
  --from-file=keys.txt=../../age.key
```

### 5. Install ArgoCD

```bash
kubectl apply -k ../../platform/argocd/
```

Wait for ArgoCD to be ready:

```bash
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

### 6. Apply the root Application

```bash
kubectl apply -f ../../apps/root.yaml
```

ArgoCD takes over from here. It will sync ingress-nginx, ExternalDNS, and all workloads automatically.

### 7. Access the ArgoCD UI (optional)

```bash
# Get the initial admin password
argocd admin initial-password -n argocd

# Port-forward the ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then visit `https://localhost:8080` (username: `admin`).

## Steady State

After bootstrapping, everything is driven by commits to `main`:

- **Add a workload**: create manifests in `workloads/<name>/` and an ArgoCD Application in `apps/<name>.yaml`
- **Update a workload**: modify its manifests and push
- **Add/update a secret**: encrypt with `sops --encrypt --in-place secret.enc.yaml` and push
- **Infrastructure changes** (rare): run `tofu plan` and `tofu apply` locally

## Repository Structure

```
infrastructure/terraform/   OpenTofu configs (bootstrap only)
platform/argocd/            ArgoCD install with KSOPS plugin
platform/ingress-nginx/     Helm values for ingress controller
platform/external-dns/      Helm values for DNS automation
apps/                       ArgoCD Application definitions (app-of-apps)
workloads/                  Workload manifests (Kustomize)
```
