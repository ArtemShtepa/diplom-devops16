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
  #export TF_VAR_YC_KUBE_MASTERS_IP=$(yc compute instance list --format json | jq -r '.[] | select(.name? | match("vm-kube-master-*")) | .network_interfaces[0].primary_v4_address.address')
  #export TF_VAR_YC_KUBE_WORKERS_IP=$(yc compute instance list --format json | jq -r '.[] | select(.name? | match("vm-kube-worker-*")) | .network_interfaces[0].primary_v4_address.address')
  export TF_VAR_YC_CLOUD_ID=$(yc config get cloud-id)
  export TF_VAR_YC_FOLDER_ID=$(yc config get folder-id)
  #export TF_VAR_YC_ZONE=$(yc config get compute-default-zone)
fi

check_bastion() {
  cd $init_dir
  export BASTION_IP=$(yc compute instance list --format json | jq -r '.[] | select( .name == "bastion" ) | .network_interfaces[].primary_v4_address.one_to_one_nat.address')
  if [ -z "$BASTION_IP" ]; then
    echo "SSH Bastion does not exist or is not configured as NAT"
    exit 1
  else
    echo "Use SSH Bastion at $BASTION_IP";
  fi
  cd $ansible_dir
}

preinit() {
  if ! [ -x "$(command -v ansible)" ]; then
    python3 -m pip install --upgrade --user ansible
  fi
  chmod 0600 $init_dir/secrets/*
  run_playbook false configure_yc+tf.yml
}

clear() {
  cd $init_dir
  rm ansible/playbook/files/_*
  rm tf/terraform*
  rm -r tf/.terraform
  rm tf/.terraform.*
}

# Инициализация Terraform
tf_init() {
  cd $terraform_dir
  terraform init
  # Создание рабочих пространств
  terraform workspace new stage
  terraform workspace new prod
}

run_terraform() {
  cd $terraform_dir
  if [ "$1" == "stage" -o "$1" == "prod" ]; then
    echo "Use terraform workspace: $1"
    terraform workspace select -or-create $1
    tf_cmd=${@:2}
  else
    tf_cmd=$*
  fi
  terraform $tf_cmd
}

tf_plan() {
  run_terraform $* plan
}

tf_apply() {
  run_terraform $* apply --auto-approve
  run_playbook true ssh_add_fp.yml
}

tf_destroy() {
  run_playbook true ssh_clear_fp.yml
  run_terraform $* destroy --auto-approve
}

run_playbook() {
  if [ "$#" -gt 1 ]; then
    if [ $1 == "true" ]; then
      check_bastion
    else
      cd $ansible_dir
    fi
    for pb in ${@:2}; do
      ansible-playbook -i inventory playbook/$pb
    done
  fi
}

# Эмуляция преднастройки машин Яндекс.Облака для стандартных образов ОС в гипервизорах
i_sudo() {
  run_playbook false install_sudo.yml
}

i_podman() {
  run_playbook true install_podman.yml
}

i_gitlab() {
  run_playbook true install_gitlab.yml
}

i_monitoring() {
  run_playbook true install_influcdb.yml install_grafana.yml install_telegraf.yml
}

i_grafana() {
  run_playbook true install_grafana.yml
}

i_influxdb() {
  run_playbook true install_influxdb.yml
}

i_telegraf() {
  run_playbook true install_telegraf.yml
}

i_runner() {
  run_playbook true install_runner.yml
}

i_bastion() {
  run_playbook true install_bastion.yml
}

i_kube_pre() {
  run_playbook true install_kube-prereq.yml
}

i_kube_cl() {
  run_playbook true install_kube-cluster.yml
}

if [ $1 ]; then
  $*
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
  echo "  clear        - Clear temporary files"
fi
