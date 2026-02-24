variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
  default     = "cyberdan"
}

variable "node_size" {
  description = "Droplet size for worker nodes"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "domain" {
  description = "Domain name for the platform"
  type        = string
  default     = "cyberdan.dev"
}
