variable "environment" {
  description = "Environment name"
  type        = string
  default     = "env1"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "enable_monitoring" {
  description = "Enable monitoring resources"
  type        = bool
  default     = false
}

variable "instance_config" {
  description = "Instance configuration"
  type = object({
    machine_type = string
    disk_size    = number
  })
  default = {
    machine_type = "e2-medium"
    disk_size    = 20
  }
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Environment = "env1"
    Team        = "platform"
    CostCenter  = "CC-1000"
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
      replicas = 1
    },
    {
      name     = "api"
      port     = 8080
      replicas = 1
    },
  ]
}
