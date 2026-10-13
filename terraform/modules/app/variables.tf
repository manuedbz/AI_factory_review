variable "name" {
  type        = string
  description = "Nom fonctionnel de l'app (ex: report)."

  validation {
    condition     = can(regex("^[a-z0-9]{2,12}$", var.name))
    error_message = "name: 2 à 12 caractères, minuscules et chiffres (limite de 24 caractères du Key Vault)."
  }
}

variable "env" {
  type        = string
  description = "Environnement (ex: dev, prod)."

  validation {
    condition     = can(regex("^[a-z0-9]{2,5}$", var.env))
    error_message = "env: 2 à 5 caractères, minuscules et chiffres."
  }
}

variable "rg_name" {
  type        = string
  description = "Resource group où créer les ressources."
}

variable "location" {
  type    = string
  default = "francecentral"
}

variable "container_app_environment_id" {
  type        = string
  description = "Id du Container Apps Environment partagé (prérequis)."
}

variable "image" {
  type        = string
  description = "Image Docker à déployer. Le défaut est une image de démonstration."
  default     = "mcr.microsoft.com/k8se/quickstart:latest"
}

variable "target_port" {
  type    = number
  default = 80
}

variable "cpu" {
  type    = number
  default = 0.25
}

variable "memory" {
  type    = string
  default = "0.5Gi"
}

variable "min_replicas" {
  type        = number
  description = "0 = l'app s'éteint sans trafic (coût nul)."
  default     = 0
}

variable "max_replicas" {
  type    = number
  default = 2
}

variable "external_ingress" {
  type        = bool
  description = "true : accessible depuis l'extérieur de l'environnement."
  default     = false
}

variable "kv_public_access" {
  type    = bool
  default = false
}

variable "dns" {
  type = object({
    zone_name = string
    rg_name   = string
  })
  description = "Zone DNS privée où enregistrer l'app. null = pas d'enregistrement DNS."
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
