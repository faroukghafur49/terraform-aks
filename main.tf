provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "aks-resource-group"
  location = "East US"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aks-cluster-dns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.0.2.0/24"
    dns_service_ip = "10.0.2.10"
  }

  identity {
    type = "SystemAssigned"
  }
}


provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.k8s.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)
}


resource "kubernetes_deployment" "hello_world_app" {
  metadata {
    name = "hello-world-deployment"
    labels = {
      app = "hello-world"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }

      spec {
        container {
          image = "tutum/hello-world"
          name  = "hello-world"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "hello_world_service" {
  metadata {
    name = "hello-world-service"
    labels = {
      app = "hello-world"
    }
  }

  spec {
    selector = {
      app = "hello-world"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "kubernetes_cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.k8s.kube_config[0].client_certificate
  sensitive = true
}

output "client_key" {
  value = azurerm_kubernetes_cluster.k8s.kube_config[0].client_key
  sensitive = true
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate
  sensitive = true
}

output "cluster_password" {
  value = azurerm_kubernetes_cluster.k8s.kube_config[0].password
  sensitive = true
}

output "cluster_username" {
  value = azurerm_kubernetes_cluster.k8s.kube_config[0].username
  sensitive = true
}

output "host" {
  value = azurerm_kubernetes_cluster.k8s.kube_config[0].host
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config_raw
  sensitive = true
}
