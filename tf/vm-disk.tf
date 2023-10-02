# Диски с операционными системами

# Основной системный диск - Debian 12
resource "yandex_compute_image" "os-disk" {
  name          = "${terraform.workspace}-disk"
  source_family = "debian-12"
}

# Системный диск для NAT
resource "yandex_compute_image" "nat-disk" {
  name          = "${terraform.workspace}-nat-disk"
  source_family = "nat-instance-ubuntu" # на основе Ubuntu 18.04
  #source_family = "nat-instance-ubuntu-2204"
}
