# Единая точка входа - единственная машинка с доступом в интернет
module "vm-bastion" {
  source = "./vm-instance"

  name        = "${terraform.workspace}-bastion"
  user        = "ubuntu"
  user_key    = "../secrets/key_bastion.pub"
  description = "SSH Bastion"
  cpu         = 2
  ram         = 0.5
  ip          = "192.168.1.10"
  internet    = true
  temporary   = false
  subnet      = yandex_vpc_subnet.subnet-main
  # Используется диск для NAT-инстанс
  #main_disk_image = "fd8op8qfgnk02nflaovf" # Ubuntu 18.04, обновление 11 сентября 2023
  main_disk_image = yandex_compute_image.nat-disk.id
  main_disk_size  = 8
}

# Машинка с Git и CI - GitLab
module "vm-main-1" {
  source = "./vm-instance"

  name        = "${terraform.workspace}-vm-1"
  user        = "debian"
  user_key    = "../secrets/key_machine.pub"
  description = "GitLab"
  cpu         = 2
  ram         = 6
  cpu_load    = 20
  ip          = "192.168.1.11"
  subnet      = yandex_vpc_subnet.subnet-main
  # Используется диск для обычных машинок
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}

# Машинка системы мониторинга - InfluxDB и Grafana
module "vm-main-2" {
  source = "./vm-instance"

  name        = "${terraform.workspace}-vm-2"
  user        = "debian"
  user_key    = "../secrets/key_machine.pub"
  description = "InfluxDB and Grafana"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.1.12"
  subnet      = yandex_vpc_subnet.subnet-main
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 20
}

# Машинка сборочного цеха и управления кластером
module "vm-main-3" {
  source = "./vm-instance"

  name        = "${terraform.workspace}-vm-3"
  user        = "debian"
  user_key    = "../secrets/key_machine.pub"
  description = "CI Runner and Kube proxy"
  cpu         = 2
  ram         = 1
  cpu_load    = 5
  ip          = "192.168.1.13"
  subnet      = yandex_vpc_subnet.subnet-main
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}
