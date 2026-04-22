data "http" "my_ip" {
  count = var.my_ip == "" ? 1 : 0
  url   = "https://api.ipify.org"
}

locals {
  my_ip_cidr    = var.my_ip != "" ? var.my_ip : "${chomp(data.http.my_ip[0].response_body)}/32"
  agent_ip_cidr = "${var.agent_public_ip}/32"
  suffix        = random_string.suffix.result
  tags = {
    project     = var.project
    environment = "prod"
    managed_by  = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/../.secrets/epicbook_rsa"
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.ssh.public_key_openssh
  filename        = "${path.module}/../.secrets/epicbook_rsa.pub"
  file_permission = "0644"
}

resource "azurerm_container_registry" "main" {
  name                = "${var.project}acr${local.suffix}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = true
  tags                = local.tags
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project}"
  address_space       = ["10.20.0.0/16"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_subnet" "main" {
  name                 = "snet-${var.project}"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_public_ip" "deploy" {
  name                = "pip-${var.project}-deploy"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_security_group" "deploy" {
  name                = "nsg-${var.project}-deploy"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags

  security_rule {
    name                       = "allow-ssh-my-ip"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.my_ip_cidr
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-ssh-from-agent"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = local.agent_ip_cidr
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-https"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "deploy" {
  name                = "nic-${var.project}-deploy"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.deploy.id
  }
}

resource "azurerm_network_interface_security_group_association" "deploy" {
  network_interface_id      = azurerm_network_interface.deploy.id
  network_security_group_id = azurerm_network_security_group.deploy.id
}

resource "azurerm_linux_virtual_machine" "deploy" {
  name                  = "vm-${var.project}-deploy"
  resource_group_name   = data.azurerm_resource_group.main.name
  location              = data.azurerm_resource_group.main.location
  size                  = var.vm_size_deploy
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.deploy.id]
  tags                  = local.tags

  identity { type = "SystemAssigned" }

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_role_assignment" "deploy_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_virtual_machine.deploy.identity[0].principal_id
}
