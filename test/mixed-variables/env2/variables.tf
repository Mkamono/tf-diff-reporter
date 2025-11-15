variable "environment" {
  description = "Environment name"
  type        = string
  default     = "env2"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "enable_monitoring" {
  description = "Enable monitoring resources"
  type        = bool
  default     = true
}

variable "instance_config" {
  description = "Instance configuration"
  type = object({
    machine_type = string
    disk_size    = number
  })
  default = {
    machine_type = "e2-standard-2"
    disk_size    = 50
  }
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Environment = "env2"
    Team        = "platform"
    CostCenter  = "CC-2000"
    Tier        = "production"
  }
}

variable "services" {
  description = "Services to deploy"
  type = list(object({
    name     = string
    port     = number
    replicas = number
  }))
  default = [
    {
      name     = "web"
      port     = 80
      replicas = 2
    },
    {
      name     = "api"
      port     = 8080
      replicas = 3
    },
    {
      name     = "worker"
      port     = 9000
      replicas = 2
    },
  ]
}
