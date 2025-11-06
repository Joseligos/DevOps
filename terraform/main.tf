terraform {
  required_providers {
    render = {
      source = "render-oss/render"
      version = "1.7.5"
    }
  }
}

# Configure the Render provider with authentication
provider "render" {
  api_key  = var.render_api_key  # Store API key as a variable
  owner_id = var.render_owner_id  # Render owner ID (username or team ID)
}