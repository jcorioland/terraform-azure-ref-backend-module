provider "azurerm" {
  version = "~> 1.31"
}

data "azurerm_resource_group" "rg" {
  name = "tf-ref-${var.environment}-rg"
}

data "azurerm_subnet" "backend" {
  name                 = "backend-subnet"
  virtual_network_name = "backend-vnet"
  resource_group_name  = "${data.azurerm_resource_group.rg.name}"
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.environment}-vm-nic"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "${var.environment}-vm-nic-ipconfiguration"
    subnet_id                     = "${data.azurerm_subnet.backend.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.environment}-vm"
  location              = "${var.location}"
  resource_group_name   = "${data.azurerm_resource_group.rg.name}"
  network_interface_ids = ["${azurerm_network_interface.vm.id}"]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.environment}-vm-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.environment}-vm"
    admin_username = "${var.vm_username}"
    admin_password = "${var.vm_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${var.environment}"
  }
}

resource "azurerm_mysql_server" "mysql" {
  name                         = "${var.environment}-mysql-server"
  location                     = "${var.location}"
  resource_group_name          = "${data.azurerm_resource_group.rg.name}"
  administrator_login          = "${var.mysql_username}"
  administrator_login_password = "${var.mysql_password}"
  version                      = "5.7"
  ssl_enforcement              = "Enabled"

  sku {
    name     = "GP_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }
}

resource "azurerm_mysql_virtual_network_rule" "mysql" {
  name                = "${var.environment}-mysql-backend-vnet-rule"
  resource_group_name = "${data.azurerm_resource_group.rg.name}"
  server_name         = "${azurerm_mysql_server.mysql.name}"
  subnet_id           = "${data.azurerm_subnet.backend.id}"
}