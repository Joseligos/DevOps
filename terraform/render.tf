# Backend Web Service on Render
# This deploys your Node.js/Express API via Dockerfile

resource "render_web_service" "backend" {
  name        = "${var.app_name}-backend"
  region      = "oregon"
  plan        = "starter"  # Free tier
  
  # For Docker-based deployment, we use native_runtime with root_directory = ""
  # This allows Render to detect and use the Dockerfile at the repository root
  runtime_source = {
    native_runtime = {
      auto_deploy      = true
      branch           = var.branch
      repo_url         = var.github_repo_url
      root_directory   = ""          # Empty = repo root (where Dockerfile is)
      runtime          = "docker"    # Use Docker
    }
  }
  
  # Root directory is repo root (where Dockerfile is located)
  root_directory = ""
  
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
