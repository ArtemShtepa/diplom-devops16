# Название машинки
variable name { default = "" }
# Описание машинки
variable description { default = "" }
# Используемая платформа - текстовой идентификатор Яндекс.Облака
variable platform { default = "standard-v1" }
# Число ядер процессора
variable cpu { default = "" }
# Объём оперативной памяти, в Гигабайтах
variable ram { default = "" }
# Гарантированная доля загрузки процессора
variable cpu_load { default = 5 }
# Прерывемая - может быть остановлена в любой момент
variable temporary { default = "false" }
# Образ системного диска
variable main_disk_image { default = "" }
# Размер системного диска, в Гигабайтах
variable main_disk_size { default = "" }
# Логин пользователя для которого пробрасывается SSH ключ
variable user { default = "" }
# Файл пробрасываемого SSH ключа
variable user_key { default = "" }
# Идентификатор подсети
variable subnet { default = "" }
# Фиксированный внутренний IP адрес
variable ip { default = "" }
# Требуется ли подключение машинки к интернету
variable nat { default = "false" }

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

resource "yandex_compute_instance" "vm-instance" {
  name        = var.name
  description = var.description
  platform_id = var.platform

  resources {
    cores         = var.cpu
    memory        = var.ram
    core_fraction = var.cpu_load
  }

  boot_disk {
    device_name = var.user
    initialize_params {
      image_id = var.main_disk_image
      type     = "network-hdd"
      size     = var.main_disk_size
    }
  }

  zone = var.subnet.zone
  network_interface {
    subnet_id  = var.subnet.id
    ip_address = var.ip
    nat        = var.nat
  }

  metadata = {
    ssh-keys = "${var.user}:${file("${var.user_key}")}"
  }

  scheduling_policy {
    preemptible = var.temporary
  }
}

output "internal_ip" {
  value = "${yandex_compute_instance.vm-instance.network_interface.0.ip_address}"
}

output "external_ip" {
  value = "${yandex_compute_instance.vm-instance.network_interface.0.nat_ip_address}"
}
