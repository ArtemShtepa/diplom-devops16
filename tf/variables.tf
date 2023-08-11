locals {
  # Число управляющих нод в кластере
  kube_master_count = {
    stage = 1
    prod  = 3
  }
  # Число рабочих нод в кластере
  kube_worker_count = {
    stage = 2
    prod  = 3
  }
  # Список подсетей, используемых для создания нод кластера
  zones = ([
    yandex_vpc_subnet.subnet-kube-a,
    yandex_vpc_subnet.subnet-kube-b,
    yandex_vpc_subnet.subnet-kube-c
  ])
}
