output "vm_deploy_public_ip"  { value = azurerm_public_ip.deploy.ip_address }
output "vm_deploy_private_ip" { value = azurerm_network_interface.deploy.private_ip_address }
output "vm_admin_user"        { value = var.admin_username }
output "acr_name"             { value = azurerm_container_registry.main.name }
output "acr_login_server"     { value = azurerm_container_registry.main.login_server }

output "acr_admin_username" {
  value     = azurerm_container_registry.main.admin_username
  sensitive = true
}

output "acr_admin_password" {
  value     = azurerm_container_registry.main.admin_password
  sensitive = true
}

output "ssh_private_key_path" { value = local_file.private_key.filename }
