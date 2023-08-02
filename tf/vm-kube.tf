/*
# Управляющая нода кластера в зоне доступности A
module "vm-kube-1" {
  source = "./vm-instance"

  name        = "vm-kube-1"
  user        = "debian"
  user_key    = "../secrets/key_kube.pub"
  description = "Kube Master 1"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.10.1"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-kube-a.id
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}

# Управляющая нода кластера в зоне доступности B
module "vm-kube-2" {
  source = "./vm-instance"

  name        = "vm-kube-2"
  user        = "debian"
  user_key    = "../secrets/key_kube.pub"
  description = "Kube Master 2"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.10.2"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-kube-b.id
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}

# Управляющая нода кластера в зоне доступности C
module "vm-kube-3" {
  source = "./vm-instance"

  name        = "vm-kube-3"
  user        = "debian"
  user_key    = "../secrets/key_kube.pub"
  description = "Kube Master 3"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.20.1"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-kube-c.id
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}

# Рабочая нода кластера в зоне доступности A
module "vm-kube-4" {
  source = "./vm-instance"

  name        = "vm-kube-4"
  user        = "debian"
  user_key    = "../secrets/key_kube.pub"
  description = "Kube Worker 1"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.20.2"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-kube-a.id
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}

# Рабочая нода кластера в зоне доступности B
module "vm-kube-5" {
  source = "./vm-instance"

  name        = "vm-kube-5"
  user        = "debian"
  user_key    = "../secrets/key_kube.pub"
  description = "Kube Worker 2"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.30.1"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-kube-b.id
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}

# Рабочая нода кластера в зоне доступности C
module "vm-kube-6" {
  source = "./vm-instance"

  name        = "vm-kube-6"
  user        = "debian"
  user_key    = "../secrets/key_kube.pub"
  description = "Kube Worker 3"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.30.2"
  nat         = false
  temporary   = true
  subnet      = yandex_vpc_subnet.subnet-kube-c.id
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}
*/
