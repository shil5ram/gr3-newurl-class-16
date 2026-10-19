output "custom_shortener_url" {
  value       = "https://${local.domain_name}"
  description = "The base custom URL used to hit the shortener deployment ecosystem"
}
