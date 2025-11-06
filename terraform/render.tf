# Backend Web Service on Render
# This deploys your Node.js/Express API

resource "render_web_service" "backend" {
  name        = "${var.app_name}-backend"
  region      = "oregon"
  plan        = "starter"  # Free tier
  branch      = var.branch
  repo_url    = var.github_repo_url
  root_dir    = "backend"
  
  # Docker configuration
  image = {
    owner_id = "owner"
    image_path = "."
  }
  
  # Environment variables
  env_vars = [
    {
      key   = "DATABASE_URL"
      value = var.database_url
    },
    {
      key   = "NODE_ENV"
      value = "production"
    },
    {
      key   = "PORT"
      value = "3000"
    }
  ]
  
  # Health check endpoint
  health_check_path = "/healthz"
  
  # Auto-deploy on push to main branch
  auto_deploy = "yes"
}

# Frontend Static Site on Render
# This deploys your React application

resource "render_static_site" "frontend" {
  name        = "${var.app_name}-frontend"
  region      = "oregon"
  plan        = "starter"  # Free tier
  branch      = var.branch
  repo_url    = var.github_repo_url
  root_dir    = "frontend"
  
  # Build configuration
  build_command   = "npm ci && npm run build"
  publish_path    = "build"
  
  # Environment variables for build
  env_vars = [
    {
      key   = "REACT_APP_API_URL"
      value = render_web_service.backend.service_url
    }
  ]
  
  # Auto-deploy on push to main branch
  auto_deploy = "yes"
}
