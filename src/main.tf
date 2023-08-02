provider "azurerm" {
    subscription_id = "fab6bd82-e9fb-4229-91d4-476d41c138fb"
    client_id       = "a8e8fcb7-ee3a-4260-8942-73671d830a1a"
    client_secret   = "ZH58Q~0J5tz3yEBYfnvVNmRTKqxypnOmvGl1Vanv"
    tenant_id       = "dc07ee3a-4d6e-436e-b3f4-29e1cc532ced"
  features {}
}

# Locate the existing resource group
data "azurerm_resource_group" "main" {
  name = "ratan"
}

output "id" {
  value = data.azurerm_resource_group.main.id
}

# Locate the existing custom image
data "azurerm_image" "main" {
  name                = "myPackerImageratan_vm_image_dn"
  resource_group_name = "ratan"
}

output "image_id" {
  value = "/subscriptions/fab6bd82-e9fb-4229-91d4-476d41c138fb/resourceGroups/RG-EASTUS-SPT-PLATFORM/providers/Microsoft.Compute/images/ratan_vm_image_dn"
}

# Create a Network Security Group with some rules
resource "azurerm_network_security_group" "main" {
  name                = "my-SG"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "my-SGR"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "80"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "main" {
  name                = "my-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
}

# Create subnet
resource "azurerm_subnet" "main" {
  name                 = "my-subnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "main" {
  name                = "my-public-ip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

# Create network interface
resource "azurerm_network_interface" "main" {
  name                = "my-nic"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# Create a new Virtual Machine based on the custom Image
resource "azurerm_virtual_machine" "myVM2" {
  name                             = "myVM2"
  location                         = data.azurerm_resource_group.main.location
  resource_group_name              = data.azurerm_resource_group.main.name
  network_interface_ids            = ["${azurerm_network_interface.main.id}"]
  vm_size                          = "Standard_DS12_v2"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.main.id}"
  }

  storage_os_disk {
    name              = "myVM2-OS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
}

  os_profile {
    computer_name  = "APPVM"
    admin_username = "devopsadmin"
    admin_password = "Cssladmin#2019"
  }

  os_profile_windows_config {    
      provision_vm_agent  = true          
  }

  
  tags = {
    environment = "Production"
  }
}