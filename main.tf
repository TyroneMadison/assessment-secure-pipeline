terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "npipe:////./pipe/docker_engine"
}

variable "app_secret" {
  description = "App secret injected at runtime, never baked into the image"
  type        = string
  sensitive   = true
}

resource "docker_network" "app_net" {
  name = "app-network"
}

resource "docker_container" "app" {
  name  = "app"
  image = "localhost:5000/app:v1"

  networks_advanced {
    name = docker_network.app_net.name
  }

  ports {
    internal = 8080
    external = 8082
  }

  env = [
    "APP_SECRET=${var.app_secret}"
  ]

  healthcheck {
    test     = ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen(\"http://localhost:8080/health\")"]
    interval = "10s"
    timeout  = "3s"
    retries  = 3
  }
}
