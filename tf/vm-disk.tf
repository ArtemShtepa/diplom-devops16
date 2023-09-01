# Диски с операционными системами

# Основной системный диск - Debian 11
resource "yandex_compute_image" "os-disk" {
  name          = "${terraform.workspace}-disk"
  source_family = "debian-11"
}
