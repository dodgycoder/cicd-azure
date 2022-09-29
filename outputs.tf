output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

output "role_id" {
  value = azurerm_linux_virtual_machine.my_terraform_vm.identity[0].principal_id
}