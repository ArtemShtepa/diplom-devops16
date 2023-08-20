# Основная сеть - будет включать все остальные подсети
resource "yandex_vpc_network" "net-master" {
  name = "network-master"
}

# Виртуальный роутер
resource "yandex_vpc_route_table" "net-router" {
  name       = "route-table"
  network_id = yandex_vpc_network.net-master.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = module.vm-bastion.internal_ip
  }
}

# Подсеть основных ресурсов: bastion, vm-main-1, vm-main-2, vm-main-3
resource "yandex_vpc_subnet" "subnet-main" {
  name           = "subnet-main"
  v4_cidr_blocks = ["192.168.1.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net-master.id
  route_table_id = yandex_vpc_route_table.net-router.id
}

# Подсеть Kubernetes кластера в зоне доступности А
resource "yandex_vpc_subnet" "subnet-kube-a" {
  name           = "subnet-kube-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net-master.id
  route_table_id = yandex_vpc_route_table.net-router.id
}

# Подсеть Kubernetes кластера в зоне доступности Б
resource "yandex_vpc_subnet" "subnet-kube-b" {
  name           = "subnet-kube-b"
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net-master.id
  route_table_id = yandex_vpc_route_table.net-router.id
}

# Подсеть Kubernetes кластера в зоне доступности В
resource "yandex_vpc_subnet" "subnet-kube-c" {
  name           = "subnet-kube-c"
  v4_cidr_blocks = ["192.168.30.0/24"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.net-master.id
  route_table_id = yandex_vpc_route_table.net-router.id
}
