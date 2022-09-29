data "azurerm_subscription" "primary" {}

resource "random_string" "random_str_val" {
  special = false
  length =8
  min_upper = 8
}


resource "azurerm_resource_group" "rg" {
    location = var.resource_group_location
    name = "RG-${var.resource_group_name_prefix}" 
    tags = {
      Owner = var.tags["value"]  
    }

}

# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "${format("%s%s",var.resource_group_name_prefix,"-VNET")}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
   tags = {
      Owner = var.tags["value"]  
    }
}

# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "${format("%s%s",var.resource_group_name_prefix,"-NETWORK")}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
   
}

# Create public IPs
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "${format("%s%s",var.resource_group_name_prefix,"-PUBIP")}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
   tags = {
      Owner = var.tags["value"]  
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "${format("%s%s",var.resource_group_name_prefix,"-NSG")}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Open-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  security_rule {
    name                       = "Open-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
      Owner = var.tags["value"]  
    }  

}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "${format("%s%s",var.resource_group_name_prefix,"-NIC")}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }

tags = {
        Owner = var.tags["value"]  
    }   

}

# Create (and display) an SSH key
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_role_definition" "app-role" {
  name        = "role-${var.resource_group_name_prefix}"
  scope       = "${data.azurerm_subscription.primary.id}"
  description = "This is a custom role created via Terraform"

  permissions {
    actions     = ["*"]
    not_actions = []
  }

assignable_scopes = [
    "${data.azurerm_subscription.primary.id}", 
  ]
   

}  


# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = "VM-${random_string.random_str_val.result}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_B2s"

  os_disk {
    name                 = "Disk-${random_string.random_str_val.result}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "VM-${random_string.random_str_val.result}"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  identity {
    type = "SystemAssigned"
  }  

  tags = {
      Owner = var.tags["value"]  
    }  
 
}

resource "azurerm_role_assignment" "assign_role" {
  name               = azurerm_role_definition.app-role.role_definition_id
  scope              = data.azurerm_subscription.primary.id
  role_definition_id = azurerm_role_definition.app-role.role_definition_resource_id
  principal_id       = azurerm_linux_virtual_machine.my_terraform_vm.identity[0].principal_id
}