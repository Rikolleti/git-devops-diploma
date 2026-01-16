terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.140"
    }
  }
}

provider "yandex" {
  service_account_key_file = "key.json"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# ---------- VPC ----------
resource "yandex_vpc_network" "net" {
  name = "netology-net"
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}

resource "yandex_vpc_subnet" "public_d" {
  name           = "public-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.12.0/24"]
}

# ---------- VM ----------
resource "yandex_compute_instance" "vm1" {
  name        = var.vm_name
  platform_id = "standard-v1"
  zone        = var.zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd827b91d99psvq5fjit"
      size     = 10
    }
  }

  network_interface {
    subnet_id = local.subnet_by_zone[var.zone]
    nat       = true
  }

  metadata = {
    serial-port-enable = var.metadata["serial-port-enable"]
    ssh-keys           = var.metadata["ssh-keys"]

    user-data = <<-EOF
      #cloud-config
      package_update: true
      packages:
        - apache2

      write_files:
        - path: /var/www/html/index.html
          permissions: "0644"
          content: |
            <html>
            <body>
              <h1>Netology Diploma</h1>
              <p>Terraform + Yandex Cloud</p>
              <p>Zone: ${var.zone}</p>
            </body>
            </html>

      runcmd:
        - systemctl enable apache2
        - systemctl restart apache2
    EOF
  }
}
