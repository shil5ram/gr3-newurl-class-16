variable "group_number" {
  type        = string
  default     = "group3"
  description = "Assigned group identifier for resource naming and subdomains"
}

variable "my_ip_cidr" {
  type        = string
  default     = "203.0.113.50/32" # REPLACE WITH YOUR PUBLIC WORKSPACE IP
  description = "The absolute IP address range allowed to connect to API endpoints"
}
