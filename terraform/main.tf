# Terraform Infrastructure as Code for DevOps CRUD App
# This configures the required providers and their versions

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    render = {
      source  = "renderinc/render"
      version = "~> 1.0"
    }
  }
}

# Configure the Render provider with API key
provider "render" {
  api_key = var.render_api_key
}
