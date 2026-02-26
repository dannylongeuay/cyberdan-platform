provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.cluster.endpoint
  token = digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
  )
}

# Use the latest patch version of the current stable K8s release
data "digitalocean_kubernetes_versions" "current" {}

# --- Kubernetes Cluster ---

resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = var.cluster_name
  region  = var.region
  version = data.digitalocean_kubernetes_versions.current.latest_version

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count
  }

  auto_upgrade  = true
  surge_upgrade = true
}

# --- DNS ---

resource "digitalocean_domain" "domain" {
  name = var.domain
}

resource "digitalocean_certificate" "cert" {
  name    = "cyberdan-domain-cert"
  type    = "lets_encrypt"
  domains = ["cyberdan.dev", "*.cyberdan.dev"]
}

# --- Bootstrap Kubernetes Secrets ---

# ArgoCD namespace (created here so bootstrap secrets can be placed in it)
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [digitalocean_kubernetes_cluster.cluster]
}

resource "kubernetes_namespace" "external_dns" {
  metadata {
    name = "external-dns"
  }

  depends_on = [digitalocean_kubernetes_cluster.cluster]
}

# DO API token for ExternalDNS
resource "kubernetes_secret" "do_token" {
  metadata {
    name      = "digitalocean-token"
    namespace = kubernetes_namespace.external_dns.metadata.0.name
  }

  data = {
    token = var.do_token
  }

  depends_on = [digitalocean_kubernetes_cluster.cluster]
}
