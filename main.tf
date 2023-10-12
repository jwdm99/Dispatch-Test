#Create Resource Group "rg-avd-prod-scus"
resource "azurerm_resource_group" "rg-avd-prod-scus" {
  name     = "rg-avd-prod-scus"
  location = "South Central US"
  tags = {
    environment = "dev"
  }
}

#Create Virtual Network "vnet-avd-prod-scus"
resource "azurerm_virtual_network" "vnet-avd-prod-scus" {
  name                = "vnet-avd-prod-scus"
  location            = azurerm_resource_group.rg-avd-prod-scus.location
  resource_group_name = azurerm_resource_group.rg-avd-prod-scus.name
  address_space       = ["10.21.4.0/23"]

  tags = {
    environment = "dev"
  }
}

/*#Create VNET Pairing to "avd-to-transit-hub"
resource "azurerm_virtual_network_peering" "avd-to-transit-hub" {
  name                      = "avd-to-transit-hub"
  resource_group_name       = azurerm_resource_group.rg-avd-prod-scus.name
  virtual_network_name      = azurerm_virtual_network.vnet-avd-prod-scus.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-transit-prod-scus.id
}

#Create VNET Pairing to "AVD-to-AADDS"
resource "azurerm_virtual_network_peering" "AVD-to-AADDS" {
  name                      = "AVD-to-AADDS"
  resource_group_name       = azurerm_resource_group.rg-avd-prod-scus.name
  virtual_network_name      = azurerm_virtual_network.vnet-avd-prod-scus.name
  remote_virtual_network_id = azurerm_virtual_network.vnet-infra-aadds-scus-csp.id
}

#Create VNET Pairing to "AADDS-peer-AVD"
resource "azurerm_virtual_network_peering" "AADDS-peer-AVD" {
  name                      = "AADDS-peer-AVD"
  resource_group_name       = azurerm_resource_group.rg-avd-prod-scus.name
  virtual_network_name      = azurerm_virtual_network.vnet-avd-prod-scus.name
  remote_virtual_network_id = azurerm_virtual_network.DHVirtualNet.id
}*/

#Create Subnet "Subnet-AVD-Prod-SC-001" seperatley from vnet-avd-prod-scus
resource "azurerm_subnet" "Subnet-AVD-Prod-SC-001" {
  name                 = "Subnet-AVD-Prod-SC-001"
  resource_group_name  = azurerm_resource_group.rg-avd-prod-scus.name
  virtual_network_name = azurerm_virtual_network.vnet-avd-prod-scus.name
  address_prefixes     = ["10.21.4.0/24"]
}

#Create Route Table
resource "azurerm_route_table" "rt-avd-prod-scus-01" {
  name                          = "rt-avd-prod-scus-01"
  location                      = azurerm_resource_group.rg-avd-prod-scus.location
  resource_group_name           = azurerm_resource_group.rg-avd-prod-scus.name
  disable_bgp_route_propagation = true

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.21.0.20"
  }

  route {
    name           = "aadds"
    address_prefix = "AzureActiveDirectoryDomainServices"
    next_hop_type  = "VnetLocal"
  }

  route {
    name           = "Hackett"
    address_prefix = "98.187.217.215/32"
    next_hop_type  = "Internet"
  }

  tags = {
    environment = "dev"
  }
}

#Associates Route Table with Subnet
resource "azurerm_subnet_route_table_association" "sn-rt-avd-prod-scus-01" {
  subnet_id      = azurerm_subnet.Subnet-AVD-Prod-SC-001.id
  route_table_id = azurerm_route_table.rt-avd-prod-scus-01.id
}

#Create Host Pool "DH-AVD-PROD" NO SCALING PLAN -YET-
resource "azurerm_virtual_desktop_host_pool" "DH-AVD-PROD" {
  location            = azurerm_resource_group.rg-avd-prod-scus.location
  resource_group_name = azurerm_resource_group.rg-avd-prod-scus.name

  name                     = "DH-AVD-PROD"
  friendly_name            = "DH-AVD-PROD"
  validate_environment     = true
  start_vm_on_connect      = true
  custom_rdp_properties    = "audiocapturemode:i:1;audiomode:i:0;"
  description              = "Acceptance Test: A pooled host pool - pooleddepthfirst"
  type                     = "Pooled"
  maximum_sessions_allowed = 50
  load_balancer_type       = "DepthFirst"
}

#Create Desktop Application Group "DH-AVD-PROD-DAG"
resource "azurerm_virtual_desktop_application_group" "DH-AVD-PROD-DAG" {
  name                = "DH-AVD-PROD-DAG"
  location            = azurerm_resource_group.rg-avd-prod-scus.location
  resource_group_name = azurerm_resource_group.rg-avd-prod-scus.name

  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.DH-AVD-PROD.id
  friendly_name = "Default Desktop"
  description   = "Desktop Application Group created through the Hostpool Wizard"
}

#Create Workspace "DH-AVD-PROD"
resource "azurerm_virtual_desktop_workspace" "DH-AVD-PROD" {
  name                = "DH-AVD-PROD"
  location            = azurerm_resource_group.rg-avd-prod-scus.location
  resource_group_name = azurerm_resource_group.rg-avd-prod-scus.name

  friendly_name = "DH-AVD-PROD"
  description   = "Production Workspace"
}

#Associate Workspace to DAG
resource "azurerm_virtual_desktop_workspace_application_group_association" "AVD-PROD-DAG" {
  workspace_id         = azurerm_virtual_desktop_workspace.DH-AVD-PROD.id
  application_group_id = azurerm_virtual_desktop_application_group.DH-AVD-PROD-DAG.id
}

/*#Create AVD Role
resource "azurerm_role_assignment" "sg-avd-users-access-001" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = data.azurerm_client_config.sg-avd-users-access-001.object_id
}*/

resource "azurerm_virtual_desktop_host_pool_registration_info" "DH-AVD-PROD-REG" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.DH-AVD-PROD.id
  expiration_date = "2023-10-25T19:14:28+00:00"
}

#Create NIC for "vm-avd-sc-p-6.dispatchhealth.local"
resource "azurerm_network_interface" "vm-avd-sc-p-6-nic" {
  name                = "vm-avd-sc-p-6-nic"
  location            = azurerm_resource_group.rg-avd-prod-scus.location
  resource_group_name = azurerm_resource_group.rg-avd-prod-scus.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.Subnet-AVD-Prod-SC-001.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "dev"
  }
}

#Creates Session Host
resource "azurerm_windows_virtual_machine" "vm-avd-sc-p-6" {
  name                = "vm-avd-sc-p-6"
  location            = azurerm_resource_group.rg-avd-prod-scus.location
  resource_group_name = azurerm_resource_group.rg-avd-prod-scus.name
  size                = "Standard_DC2s_v2"
  admin_username      = "superuser"
  admin_password      = "Cust0mersf1rst!"
  network_interface_ids = [
    azurerm_network_interface.vm-avd-sc-p-6-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-22h2-pro"
    version   = "latest"
  }
}

# Retrieve domain information
data "azuread_domains" "67a6b159-2ceb-48cd-a023-cc670d5570d7" {
  only_initial = true
}

# Create an application
resource "azuread_application" "APP1" {
  display_name = "ExampleApp"
}

# Create a service principal
resource "azuread_service_principal" "SP1" {
  application_id = azuread_application.APP1.application_id
}

# Create a user
resource "azuread_user" "Test" {
  user_principal_name = "Test"
  display_name        = "Test"
  password            = "AVD123"
}

resource "azurerm_virtual_machine_extension" "aadlogin" {
name = "AADLoginForWindows"
virtual_machine_id = azurerm_windows_virtual_machine.vm-avd-sc-p-6.id
publisher = "Microsoft.Azure.ActiveDirectory"
type = "AADLoginForWindows"
type_handler_version = "1.0"
auto_upgrade_minor_version = true
}