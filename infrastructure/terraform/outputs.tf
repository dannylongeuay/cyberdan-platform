output "cluster_id" {
  description = "DOKS cluster ID"
  value       = digitalocean_kubernetes_cluster.cluster.id
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = digitalocean_kubernetes_cluster.cluster.endpoint
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubeconfig for the DOKS cluster"
  value       = digitalocean_kubernetes_cluster.cluster.kube_config[0].raw_config
  sensitive   = true
}
