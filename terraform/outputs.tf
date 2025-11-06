# Output values from Terraform deployment
# These will be displayed after applying the infrastructure

output "backend_url" {
  description = "URL of the deployed backend service"
  value       = render_web_service.backend.service_url
}

output "frontend_url" {
  description = "URL of the deployed frontend application"
  value       = render_static_site.frontend.service_url
}

output "backend_id" {
  description = "Render service ID for the backend"
  value       = render_web_service.backend.id
}

output "frontend_id" {
  description = "Render service ID for the frontend"
  value       = render_static_site.frontend.id
}
