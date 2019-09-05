output "resource_group_name" {
  value = "${data.azurerm_resource_group.rg.name}"
}

output "mysql_fqdn" {
  value = "${azurerm_mysql_server.mysql.fqdn}"
}

output "vm_private_ip" {
  value = "${azurerm_network_interface.vm.private_ip_address}"
}