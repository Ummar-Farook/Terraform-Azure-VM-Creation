
provider "azurerm" {
  
    subscription_id = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # Set Environmental Variable of the Subcription ID
    client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # Set Environmental Variable of the Client ID
    client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # Set Environmental Variable of the Client Secret
    tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # Set Environmental Variable of the Tentant ID of the Organization

}

resource "azurerm_resource_group" "petclinic" {
  name     = "petclinic"
  location = "southcentralus"
}

resource "azurerm_public_ip" "petclinic" {
    name                         = "PetclinicPublicIP"
    location                     = "southcentralus"
    resource_group_name          = "${azurerm_resource_group.petclinic.name}"
    allocation_method            = "Dynamic"

}

resource "azurerm_virtual_network" "petclinic" {
  name                = "Development-network"
  resource_group_name = "${azurerm_resource_group.petclinic.name}"
  location            = "${azurerm_resource_group.petclinic.location}"
  address_space       = ["172.20.0.0/16"]
}


resource "azurerm_subnet" "petclinic" {
  name                 = "petclinic-public"
  resource_group_name  = "${azurerm_resource_group.petclinic.name}"
  virtual_network_name = "${azurerm_virtual_network.petclinic.name}"
  address_prefix       = "172.20.10.0/24"
}



resource "azurerm_subnet" "petclinic" {
  name                 = "petclinic-private"
  resource_group_name  = "${azurerm_resource_group.petclinic.name}"
  virtual_network_name = "${azurerm_virtual_network.petclinic.name}"
  address_prefix       = "172.20.20.0/24"
}

resource "azurerm_network_interface" "petclinicprivateip" {
  name                = "petclinic-privateip"
  location            = "${azurerm_resource_group.petclinic.location}"
  resource_group_name = "${azurerm_resource_group.petclinic.name}"

  ip_configuration {
    name                          = "petclinic"
    subnet_id                     = "${azurerm_subnet.petclinic.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface" "petclinicpublicip" {
  name                = "petclinic-publicip"
  location            = "${azurerm_resource_group.petclinic.location}"
  resource_group_name = "${azurerm_resource_group.petclinic.name}"

  ip_configuration {
    name                          = "petclinic"
    subnet_id                     = "${azurerm_subnet.petclinic.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.2.5"
    public_ip_address_id          = "${azurerm_public_ip.petclinic.id}"
  }
}

resource "azurerm_virtual_machine" "petclinicpublicip" {
  name                  = "petclinic---Jenkins"
  location              = "${azurerm_resource_group.petclinic.location}"
  resource_group_name   = "${azurerm_resource_group.petclinic.name}"
  network_interface_ids = ["${azurerm_network_interface.petclinicpublicip.id}"]
  vm_size               = "Standard_DS1_v2"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "Jenkins Server"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "Development"
   } 
}


resource "azurerm_virtual_machine" "petclinicprivateip" {
  name                  = "petclinic---Docker"
  location              = "${azurerm_resource_group.petclinic.location}"
  resource_group_name   = "${azurerm_resource_group.petclinic.name}"
  network_interface_ids = ["${azurerm_network_interface.petclinicprivateip.id}"]
  vm_size               = "Standard_DS1_v2"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "Application Server"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "Development"
  }
}

provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && apt-get install python-software-properties && add-apt-repository ppa:openjdk-r/ppa && apt-get update && apt-get install openjdk-7-jdk && apt-get update && apt-get install jenkins",
      "systemctl start jenkins",
    ]
  }
