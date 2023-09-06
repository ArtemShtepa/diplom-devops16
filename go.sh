#!/usr/bin/env bash

# Текущая директория
init_dir=$(pwd)
# Каталог расположения файлов Ansible
ansible_dir=$(pwd)/ansible
# Каталог расположения файлов Terraform
terraform_dir=$(pwd)/tf
# Имя S3 бакета - должно быть уникально для всего Яндекс.Облака
storage_name="artemshtepa-devops16"
# Имя сервисного аккаунта
sa_name="sa-diplom"
# Дополнение к имени файла сервисного аккаунта
sa_file="diplom"

if ! [ -x "$(command -v ansible)" ]; then
  echo "Ansible not found. Use init command" >&2
fi

if ! [ -x "$(command -v terraform)" ]; then
  echo 'Terraform is not installed. Use init command' >&2
fi

get_yc_vars() {
  yc_cloud=$(yc config get cloud-id 2>/dev/null)
  if [ $? -eq 0 ]; then
    export export TF_VAR_YC_CLOUD_ID=$yc_cloud
  fi
  yc_folder=$(yc config get folder-id 2>/dev/null)
  if [ $? -eq 0 ]; then
    export TF_VAR_YC_FOLDER_ID=$yc_folder
  fi
  #export TF_VAR_YC_ZONE=$(yc config get compute-default-zone)
}

if ! [ -x "$(command -v yc)" ]; then
  echo 'Yandex CLI is not installed. Use init command' >&2
else
  export TF_VAR_YC_SA_FILE=$(pwd)/$(ls secrets/sa_file*.json | head -n1)
  export TF_VAR_YC_SA_ID=$(cat $TF_VAR_YC_SA_FILE | jq -r .service_account_id)
  if ! [ -f secrets/sa_key.json ]; then
    echo "Generate access key for service account..."
    yc iam access-key create --service-account-id $TF_VAR_YC_SA_ID --format json > secrets/sa_key.json
  fi
  access_key=$(cat secrets/sa_key.json | jq -r .access_key.key_id)
  secret_key=$(cat secrets/sa_key.json | jq -r .secret)
  get_yc_vars
fi

create_ssh_key() {
  if ! [ -f "secrets/key_$1" ]; then
    echo "Generate SSH key for $1..."
    ssh-keygen -t ed25519 -N '' -f secrets/key_$1 <<< $'\ny' >/dev/null 2>&1
  fi
}

init() {
  if ! [ -x "$(command -v ansible)" ]; then
    echo "Install Ansible..."
    python3 -m pip install --upgrade --user ansible
  fi
  chmod 0600 $init_dir/secrets/*
  echo "Install YC CLI and Terraform..."
  run_playbook false configure_yc+tf.yml
  cd $init_dir
  # Инициализирование YC CLI
  while [ $TF_VAR_YC_CLOUD_ID = "" ] || [ $TF_VAR_YC_FOLDER_ID = "" ]; do
    yc init
    get_yc_vars
  done
  # Создание сервисного аккаунта
  if ! $(yc iam service-account get $sa_name 1>/dev/null 2>&1); then
    echo "Create service account..."
    yc iam service-account create --name $sa_name
    echo "Add access rights..."
    yc iam service-account add-access-binding --name $sa_name --role editor --service-account-name $sa_name
    echo "Grant access rights to folder..."
    yc resource-manager folder --id $TF_VAR_YC_FOLDER_ID add-access-binding --role editor --service-account-name $sa_name
    echo "Generate account access file..."
    yc iam key create --service-account-name $sa_name -o secrets/sa_file-$sa_file.json
    echo "Generate access key for service account..."
    yc iam access-key create --service-account-name $sa_name --format json > secrets/sa_key.json
  fi
  create_ssh_key bastion
  create_ssh_key kube
  create_ssh_key machine
  # Создание бакета
  if ! $(yc storage bucket get $storage_name 1>/dev/null 2>&1); then
    echo "Create S3 storage..."
    if ! $(yc storage bucket create --name $storage_name 1>/dev/null 2>&1); then
      echo "FAIL! Can't create bucket. May be name is already used?"
      exit
    fi
  fi
}

clean() {
  cd $init_dir
  rm ansible/playbook/files/_*
  rm -r tf/terraform*
  rm -r tf/.terraform
  rm -r tf/.terraform.*
  echo "Destroy S3 storage..."
  yc storage bucket delete --name $storage_name
  echo "Delete service account..."
  yc iam service-account delete --name $sa_name
}

check_bastion() {
  cd $terraform_dir
  export TF_WORKSPACE=$(terraform workspace show)
  echo "Use terraform workspace: $TF_WORKSPACE"
  cd $init_dir
  export BASTION_IP=$(yc compute instance list --format json | jq -r '.[] | select(.name == "'$TF_WORKSPACE'-bastion") | .network_interfaces[].primary_v4_address.one_to_one_nat.address')
  if [ -z "$BASTION_IP" ]; then
    echo "SSH Bastion does not exist or is not configured as NAT"
    exit 1
  else
    echo "Use SSH Bastion at $BASTION_IP";
  fi
}

# Инициализация Terraform
tf_init() {
  cd $terraform_dir
  terraform init -reconfigure -backend-config="access_key=$access_key" -backend-config="secret_key=$secret_key" -backend-config="bucket=$storage_name"
  #terraform providers lock -platform=linux_amd64
  # Создание рабочих пространств
  terraform workspace new stage
  terraform workspace new prod
  terraform workspace select stage
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
    fi
    cd $ansible_dir
    for pb in ${@:2}; do
      ansible-playbook -i inventory playbook/$pb
    done
  fi
}

# Эмуляция преднастройки машин Яндекс.Облака для стандартных образов ОС в гипервизорах
i_sudo() {
  check_bastion
  cd $ansible_dir
  ansible-playbook -i inventory playbook/bootstrap_vm.yml --tags sudo
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

i_update() {
  run_playbook true bootstrap_hosts.yml
}

i_bastion() {
  run_playbook true configure_bastion.yml
}

i_kube_pre() {
  run_playbook true install_kube-prereq.yml
}

i_kube_cl() {
  run_playbook true install_kube-cluster.yml
}

run_vm() {
  check_bastion
  if [ "$1" == "" ]; then
    echo "Specify host name to connect without '$TF_WORKSPACE-'"
    yc compute instance list
  else
    if [ "$1" == "bastion" ]; then
      ssh ubuntu@$BASTION_IP -i secrets/key_bastion
    else
      cmd=${@:2}
      ip=$(yc compute instance list --format json | jq -r '.[] | select(.name == "'$TF_WORKSPACE'-'$1'") | .network_interfaces[0].primary_v4_address.address')
      if [ "$ip" == "" ]; then
        echo "Host name '$1' not exists"
      elif [[ $ip == "kube*" ]]; then
        ssh -o ProxyCommand="ssh -W %h:%p -q -i secrets/key_bastion ubuntu@$BASTION_IP" debian@$ip -i secrets/key_kube $cmd
      else
        ssh -o ProxyCommand="ssh -W %h:%p -q -i secrets/key_bastion ubuntu@$BASTION_IP" debian@$ip -i secrets/key_machine $cmd
      fi
    fi
  fi
}

rearm() {
  c=0
  for n in $(yc compute instance list --format json | jq -r '.[] | select(.status != "RUNNING") | .name'); do
    echo "Rearm instance: $n ..."
    yc compute instance start $n
    ((c++))
  done
  if [[ $c == 0 ]]; then
    run_playbook true ssh_add_fp.yml
  fi
  echo $c
}

if [ $1 ]; then
  $*
else
  echo "Possible commands:"
  echo "  init         - Install Ansible,YC CLI,Terraform and preconfigure YC"
  echo "  tf_init      - Run Terraform init"
  echo "  tf_plan      - Print Terraform plan"
  echo "  tf_apply     - Apply Terraform plan"
  echo "  tf_destroy   - Destroy Terraform plan"
  echo "  i_update     - Update hosts package cache"
  echo "  i_bastion    - Configure SSH Bastion"
  echo "  i_sudo       - Configure hosts similarly to the YC instance (local VM)"
  echo "  i_podman     - Install Podman"
  echo "  i_gitlab     - Install GitLab CE"
  echo "  i_monitoring - Install InfluxDB + Grafana + Telegraf"
  echo "    i_grafana  - Install Grafana"
  echo "    i_influxdb - Install InfluxDB"
  echo "    i_telegraf - Install Telegraf"
  echo "  i_runner     - Install GitLab Runner"
  echo "  i_kube_pre   - Install Kubernetes Prerequirements"
  echo "  i_kube_cl    - Install Kubernetes Cluster"
  echo "  run_vm       - Run SSH session or command on remote machine"
  echo "  rearm        - Start stopped YC instances"
  echo "  clean        - Destroy preconfigured YC resources and clear temporary files"
fi
