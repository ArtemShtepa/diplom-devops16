# Название машинки
variable "name" {
  type    = string
  default = ""
}
# Описание машинки
variable "description" {
  type    = string
  default = ""
}
# Используемая платформа - текстовой идентификатор Яндекс.Облака
variable "platform" {
  type    = string
  default = "standard-v2"
}
# Число ядер процессора
variable "cpu" {
  type    = number
  default = 2
}
# Объём оперативной памяти, в Гигабайтах
variable "ram" {
  type    = number
  default = 1
}
# Гарантированная доля загрузки процессора
variable "cpu_load" {
  type    = number
  default = 5
}
# Прерывемая - может быть остановлена в любой момент
variable "temporary" {
  type    = bool
  default = true
}
# Образ системного диска
variable "main_disk_image" {
  type    = string
  default = ""
}
# Размер системного диска, в Гигабайтах
variable "main_disk_size" {
  type    = number
  default = 10
}
# Логин пользователя для которого пробрасывается SSH ключ
variable "user" {
  type    = string
  default = ""
}
# Файл пробрасываемого SSH ключа
variable "user_key" {
  type    = string
  default = ""
}
# Идентификатор подсети
variable "subnet" { default = null }
# Фиксированный внутренний IP адрес
variable "ip" {
  type    = string
  default = ""
}
# Требуется ли подключение машинки к интернету
variable "internet" {
  type    = bool
  default = false
}

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
    nat        = var.internet
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
