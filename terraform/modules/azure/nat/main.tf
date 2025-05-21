resource "azurerm_public_ip" "nat" {
  name                = "${var.cluster_name}-nat-ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "${var.cluster_name}-nat-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_route_table" "private_route_table" {
  name                = "${var.cluster_name}-private-route-table"
  location            = var.location
  resource_group_name = var.resource_group_name

  route {
    name                   = "private-subnet-nat-route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
    # next_hop_in_ip_address = azurerm_public_ip.nat.ip_address
  }
}

resource "azurerm_subnet_route_table_association" "private_subnet_route_association" {
  count          = length(var.private_subnet_ids)
  subnet_id      = var.private_subnet_ids[count.index]
  route_table_id = azurerm_route_table.private_route_table.id
}
