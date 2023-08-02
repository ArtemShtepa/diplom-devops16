#!/usr/bin/env bash

init_dir=$(pwd)
ansible_dir=$(pwd)/ansible
terraform_dir=$(pwd)/tf

if ! [ -x "$(command -v ansible)" ]; then
  echo "Ansible not found. Use preinit command" >&2
fi

if ! [ -x "$(command -v terraform)" ]; then
  echo 'Terraform is not installed. Use preinit command' >&2
fi

if ! [ -x "$(command -v yc)" ]; then
  echo 'Yandex CLI is not installed. Use preinit command' >&2
else
  export TF_VAR_YC_SA_KEY=$(pwd)/$(ls secrets/sa-*-key.json | head -n1)
  export TF_VAR_YC_CLOUD_ID=$(yc config get cloud-id)
  export TF_VAR_YC_FOLDER_ID=$(yc config get folder-id)
  #export TF_VAR_YC_ZONE=$(yc config get compute-default-zone)
fi

preinit() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/configure_yc+tf.yml
}

tf_init() {
  cd $terraform_dir
  terraform init
}

tf_plan() {
  cd $terraform_dir
  terraform plan
}

tf_apply() {
  cd $terraform_dir
  terraform apply --auto-approve
}

tf_destroy() {
  cd $terraform_dir
  terraform destroy --auto-approve
}

i_sudo() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_sudo.yml
}

i_podman() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_podman.yml
}

i_gitlab() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_gitlab.yml
}

i_monitoring() {
  i_influxdb
  i_grafana
  i_telegraf
}

i_grafana() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_grafana.yml
}

i_influxdb() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_influxdb.yml
}

i_telegraf() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_telegraf.yml
}

i_runner() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_runner.yml
}

i_bastion() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_bastion.yml
}

i_kube_pre() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_kube-prereq.yml
}

i_kube_cl() {
  cd $ansible_dir
  ansible-playbook -i inventory playbook/install_kube-cluster.yml
}

if [ $1 ]; then
  $1
else
  echo "Possible commands:"
  echo "  preinit      - Download and configure YC CLI and Terraform"
  echo "  tf_init      - Terraform init"
  echo "  tf_plan      - Terraform plan"
  echo "  tf_apply     - Apply Terraform plan"
  echo "  tf_destroy   - Destroy Terraform plan"
  echo "  i_bastion    - Install SSH Bastion"
  echo "  i_sudo       - Prepare hosts"
  echo "  i_podman     - Install Podman"
  echo "  i_gitlab     - Install GitLab CE"
  echo "  i_monitoring - Install InfluxDB + Grafana + Telegraf"
  echo "    i_grafana  - Install Grafana"
  echo "    i_influxdb - Install InfluxDB"
  echo "    i_telegraf - Install Telegraf"
  echo "  i_runner     - Install GitLab Runner"
  echo "  i_kube_pre   - Install Kubernetes Prerequirements"
  echo "  i_kube_cl    - Install Kubernetes Cluster"
fi
