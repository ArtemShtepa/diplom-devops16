# Управляющие ноды кластера
module "vm-kube-master" {
  source = "./vm-instance"
  count  = local.kube_master_count[terraform.workspace]

  name        = "vm-kube-master-${count.index + 1}"
  user        = "debian"
  user_key    = "../secrets/key_kube.pub"
  description = "Kube Master ${count.index + 1}"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.${((count.index % length(local.zones)) + 1) * 10}.${51 + floor(count.index / length(local.zones))}"
  subnet      = local.zones[count.index % length(local.zones)]
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}

# Рабочая нода кластера
module "vm-kube-worker" {
  source = "./vm-instance"
  count  = local.kube_worker_count[terraform.workspace]

  name        = "vm-kube-worker-${count.index + 1}"
  user        = "debian"
  user_key    = "../secrets/key_kube.pub"
  description = "Kube Worker ${count.index + 1}"
  cpu         = 2
  ram         = 2
  cpu_load    = 5
  ip          = "192.168.${((count.index % length(local.zones)) + 1) * 10}.${101 + floor(count.index / length(local.zones))}"
  subnet      = local.zones[count.index % length(local.zones)]
  main_disk_image = yandex_compute_image.os-disk.id
  main_disk_size  = 30
}
