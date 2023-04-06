# Create a resource group
resource "azurerm_resource_group" "terraformwithmooglelabs" {
  name     = "terraform-shubham"
  location = "North Europe"
}

resource "azurerm_network_security_group" "moogle_sg" {
  name = "moogle-sg"
  location = azurerm_resource_group.terraformwithmooglelabs.location
  resource_group_name = azurerm_resource_group.terraformwithmooglelabs.name

  security_rule {
    access = "Allow"
    destination_address_prefix = "*"
    destination_port_range = "80"
    direction = "Inbound"
    name = "Http"
    priority = 100
    protocol = "Tcp"
    source_address_prefix = "*"
    source_port_range = "*"
  }

  security_rule {
    access = "Allow"
    destination_address_prefix = "*"
    destination_port_range = "22"
    direction = "Inbound"
    name = "ssh"
    priority = 101
    protocol = "Tcp"
    source_address_prefix = "*"
    source_port_range = "*"
  } 
  
}
# Create a virtual network within the resource group
resource "azurerm_virtual_network" "terraform-vnet" {
  name                = "terraform-vnet"
  resource_group_name = azurerm_resource_group.terraformwithmooglelabs.name
  location            = azurerm_resource_group.terraformwithmooglelabs.location
  address_space       = ["10.0.0.0/16"]
}

# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "terra-subnet" {
  name                 = "terraform-subnet"
  resource_group_name  = azurerm_resource_group.terraformwithmooglelabs.name
  virtual_network_name = azurerm_virtual_network.terraform-vnet.name
  address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "association" {
    subnet_id = azurerm_subnet.terra-subnet.id
    network_security_group_id = azurerm_network_security_group.moogle_sg.id
  
}
# Create our Azure Storage Account 
resource "azurerm_storage_account" "mooglelabs-storage-new" {
  name                     = "mooglelabvol"
  resource_group_name      = azurerm_resource_group.terraformwithmooglelabs.name
  location                 = azurerm_resource_group.terraformwithmooglelabs.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_public_ip" "moogleip" {
  name = "mooglelabs-ip"
  location = azurerm_resource_group.terraformwithmooglelabs.location
  resource_group_name = azurerm_resource_group.terraformwithmooglelabs.name
  allocation_method = "Dynamic"
  
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "mooglelabvnic"
  location            = azurerm_resource_group.terraformwithmooglelabs.location
  resource_group_name = azurerm_resource_group.terraformwithmooglelabs.name
  
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.terra-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.moogleip.id
  }

}

# Create our Virtual Machine -
resource "azurerm_virtual_machine" "mooglevm_new" {
  name                  = "mooglelabsvm"
  location              = azurerm_resource_group.terraformwithmooglelabs.location
  resource_group_name   = azurerm_resource_group.terraformwithmooglelabs.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B1s"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "mooglelabsvm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name      = "mooglelabs"
    admin_username     = "mooglelabs"
    admin_password     = "Mooglelabs@123"
    custom_data = file("azure-user-data.sh")
  }
  os_profile_linux_config  {
    disable_password_authentication = true
    ssh_keys {
      key_data = file("C:\\Users\\HalwaShubham.SEASIAINFOTECH\\.ssh\\id_rsa.pub")
      path = "/home/mooglelabs/.ssh/authorized_keys"
    }

  }
}
# provisioner "remote-exec" {
#   inline = [
#     "sudo apt-get -y update",
#     "sudo apt-get -y install apache2 && sudo systemctl restart apache2",
#     "echo '<h1> SHUBHAM <h1>'>index.html",
#     "sudo mv index.html /var/www/html/"
#   ]
#   connection {
#     type = "ssh"
#     host = azurerm_public_ip.moogleip.ip_address
#     user= "mooglelabs"
#     private_key = file(".ssh/id_rsa")
#   }
