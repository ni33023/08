terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.69.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "d34bfa3c-395b-4a99-b78b-c1eb567f194e"
  client_id       = "f260542f-a9d1-4fa8-9576-0e41120870b0"
  tenant_id       = "9c8afe4e-d0ec-4897-9177-18276771306d"
  client_secret   = "wat8Q~rnYwl0NuMaYX3TMU2TVRwEAWDIKBkesbD0" 
  features {
    
  } 
  
}



resource "azurerm_resource_group" "jay" {
  name     = "jay"
  location = "EAST US"
  }


resource "azurerm_virtual_network" "vnet" {
    name                = "vnet"
    location            = "EAST US"
    resource_group_name = "jay"
    address_space       = ["192.168.0.0/16"]
    depends_on = [ azurerm_resource_group.jay ]

}

resource "azurerm_subnet" "subnet1" {
    name                 = "subnet1"
    resource_group_name  = "jay"
    virtual_network_name = "vnet"
    address_prefixes     = ["192.168.255.224/27"]
    depends_on = [ azurerm_virtual_network.vnet ]
}

resource "azurerm_public_ip" "public-ip" {
    count               = 2
    name                = "public-ip${count.index}"
    location            = "EAST US"
    resource_group_name = "jay"
    allocation_method   = "Dynamic"
    depends_on = [ azurerm_resource_group.jay ]

}

resource "azurerm_network_interface" "network-interface" {
    count                = 2
    name                 = "network-interface${count.index}"
    location             = "EAST US"
    resource_group_name  = "jay"
    enable_ip_forwarding = true

    ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public-ip[count.index].id
    }
    depends_on = [ azurerm_virtual_network.vnet ]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "security-group" {
    name                = "security-group"
    location            = "EAST US"
    resource_group_name = "jay"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    depends_on = [ azurerm_subnet.subnet1 ]

}

resource "azurerm_subnet_network_security_group_association" "mgmt-nsg-association" {
    subnet_id                 = azurerm_subnet.subnet1.id
    network_security_group_id = azurerm_network_security_group.security-group.id
    depends_on = [ azurerm_network_security_group.security-group ]
}

resource "azurerm_virtual_machine" "jay-vm" {
    count                 = 2
    name                  = "jay-vm${count.index}"
    location              = "EAST US"
    resource_group_name   = "jay"
    network_interface_ids = [element(azurerm_network_interface.network-interface.*.id, count.index)]
    vm_size               = "Standard_DS2_v2"
    delete_os_disk_on_termination = true


    storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
    }

    storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    }

    os_profile {
    computer_name  = "jay"
    admin_username = "azureuser"
    admin_password = "J@yendhar555"
    }

    os_profile_linux_config {
    disable_password_authentication = false
    }

}




