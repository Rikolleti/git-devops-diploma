locals {
  subnet_by_zone = {
    "ru-central1-a" = yandex_vpc_subnet.public_a.id
    "ru-central1-b" = yandex_vpc_subnet.public_b.id
    "ru-central1-d" = yandex_vpc_subnet.public_d.id
  }
}
