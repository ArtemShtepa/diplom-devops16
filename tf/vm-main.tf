# Единая точка входа - единственная машинка с доступом в интернет
module "vm-bastion" {
  source = "./vm-instance"

  name        = "bastion"
  user        = "debian"
  user_key    = "../secrets/key_bastion.pub"
  description = "SSH Bastion"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.1.10"
  nat         = true
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-main
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 10
}

# Машинка с Git и CI - GitLab
module "vm-main-1" {
  source = "./vm-instance"

  name        = "vm-main-1"
  user        = "debian"
  user_key    = "../secrets/key_machine.pub"
  description = "GitLab"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.1.11"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-main
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}
/*
# Машинка системы мониторинга - InfluxDB и Grafana
module "vm-main-2" {
  source = "./vm-instance"

  name        = "vm-main-2"
  user        = "debian"
  user_key    = "../secrets/key_machine.pub"
  description = "InfluxDB and Grafana"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.1.12"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-main.id
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 20
}

# Машинка сборочного цеха и управления кластером
module "vm-main-3" {
  source = "./vm-instance"

  name        = "vm-main-3"
  user        = "debian"
  user_key    = "../secrets/key_machine.pub"
  description = "CI Runner and Kube proxy"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.1.13"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-main.id
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}
*/
