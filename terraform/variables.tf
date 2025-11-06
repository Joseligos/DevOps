# Variables definition for Terraform configuration

variable "render_api_key" {
  description = "Render API key for authentication"
  type        = string
  sensitive   = true
}

variable "render_owner_id" {
  description = "Render Owner ID (username or team ID)"
  type        = string
}

variable "github_repo_url" {
  description = "GitHub repository URL"
  type        = string
  default     = "https://github.com/Joseligos/DevOps"
}

variable "database_url" {
  description = "PostgreSQL connection string from Railway or other provider"
  type        = string
  sensitive   = true
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "devops-crud-app"
}

variable "branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}
