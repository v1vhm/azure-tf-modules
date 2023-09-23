
output "public_ip" {
  value       = azurerm_public_ip.example.ip_address
  description = "The public IP address of the load balancer"
}