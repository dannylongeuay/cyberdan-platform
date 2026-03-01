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

This provides: `opentofu`, `kubectl`, `kustomize`, `helm`, `argocd`, `jq`, `yq`

### 2. Create the Spaces bucket for OpenTofu state

Create a state bucket in the DigitalOcean Web console

### 3. Update the repo URL in ArgoCD Applications

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
cd -
```

This creates the DOKS cluster, DNS zone, and bootstrap Kubernetes secrets.

### 3. Create a DigitalOcean managed SSL certificate

Get the certificate ID:

```bash
doctl compute certificate list | rg cyberdan
```

Update `platform/gateway/gateway.yaml` with the certificate ID.

### 4. Configure kubectl

```bash
doctl kubernetes cluster kubeconfig save cyberdan
```

### 5. Install ArgoCD

```bash
kubectl apply --server-side --force-conflicts -k ./platform/argocd/
```

Wait for ArgoCD to be ready:

```bash
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```
or
```bash
k9s
```

### 6. Apply the root Application

```bash
kubectl apply -f ./apps/root.yaml
```

ArgoCD takes over from here. It will sync all workloads automatically.

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
- **Infrastructure changes** (rare): run `tofu plan` and `tofu apply` locally

## Repository Structure

```
infrastructure/terraform/   OpenTofu configs (bootstrap only)
platform/argocd/            ArgoCD install
platform/ingress-nginx/     Helm values for ingress controller
platform/external-dns/      Helm values for DNS automation
apps/                       ArgoCD Application definitions (app-of-apps)
workloads/                  Workload manifests (Kustomize)
```
