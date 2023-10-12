#Create Resource Group "rg-avd-prod-scus"
resource "azurerm_resource_group" "rg-avd-prod-scus" {
  name     = "JWM-Terraform"
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

#Create VNET Pairing to "avd-to-transit-hub"
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
}

#Create Subnet "Subnet-AVD-Prod-SC-001" seperatley from vnet-avd-prod-scus
resource "azurerm_subnet" "Subnet-AVD-Prod-SC-001" {
  name                 = "Subnet-AVD-Prod-SC-001"
  resource_group_name  = azurerm_resource_group.rg-avd-prod-scus.name
  virtual_network_name = azurerm_virtual_network.vnet-avd-prod-scus.name
  id            = azurerm_subnet.Subnet-AVD-Prod-SC-001.id
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

resource "azurerm_subnet_route_table_association" "sn-rt-avd-prod-scus-01" {
  subnet_id      = azurerm_subnet.Subnet-AVD-Prod-SC-001.id
  route_table_id = azurerm_route_table.rt-avd-prod-scus-01.id
}