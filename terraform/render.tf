# Backend Web Service on Render
# This deploys your Node.js/Express API

resource "render_web_service" "backend" {
  name        = "${var.app_name}-backend"
  region      = "oregon"
  plan        = "starter"  # Free tier
  
  runtime_source = {
    native_runtime = {
      auto_deploy      = true
      branch           = var.branch
      repo_url         = var.github_repo_url
      root_directory   = "backend"
      runtime          = "node"
      build_command    = "npm install"
    }
  }
  
  # Root directory must also be set at resource level
  root_directory = "backend"
  
  # Start command must be at the resource level
  start_command = "node index.js"
  
  # Environment variables (map format)
  env_vars = {
    DATABASE_URL = {
      value = var.database_url
    }
    NODE_ENV = {
      value = "production"
    }
    PORT = {
      value = "3000"
    }
  }
  
  # Health check endpoint
  health_check_path = "/healthz"
}

# Frontend Static Site on Render
# This deploys your React application

resource "render_static_site" "frontend" {
  name           = "${var.app_name}-frontend"
  branch         = var.branch
  repo_url       = var.github_repo_url
  root_directory = "frontend"
  build_command  = "npm ci && npm run build"
  publish_path   = "build"
  auto_deploy    = true
  
  # Environment variables for build (map format)
  env_vars = {
    REACT_APP_API_URL = {
      value = render_web_service.backend.url
    }
  }
}
