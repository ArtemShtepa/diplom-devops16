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
# Флаг отладки на локальных виртуальных машинах
is_local_vm=true

# Цветовая палитра DOS
CR='\e[0m'
C0='\e[0;30m'
C1='\e[0;34m'
C2='\e[0;32m'
C3='\e[0;36m'
C4='\e[0;31m'
C5='\e[0;35m'
C6='\e[0;33m'
C7='\e[0;37m'
C8='\e[1;30m'
C9='\e[1;34m'
C10='\e[1;32m'
C11='\e[1;36m'
C12='\e[1;31m'
C13='\e[1;35m'
C14='\e[1;33m'
C15='\e[1;37m'

if [ "$is_local_vm" = true ]; then
  vm_list_cmd="cat $init_dir/secrets/yc_local"
  export VM_LIST_CMD=$vm_list_cmd
else
  vm_list_cmd="yc compute instance list --format json"
fi

if ! [ -x "$(command -v ansible)" ]; then
  echo -e "$C12 Ansible not found.$CR Use$C14 init$CR command" >&2
fi

if ! [ -x "$(command -v terraform)" ]; then
  echo -e "$C12 Terraform is not installed.$CR Use$C14 init$CR command" >&2
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
  echo -e "$C12 Yandex CLI is not installed.$CR Use$C14 initC$R command" >&2
else
  export TF_VAR_YC_SA_FILE=$(pwd)/$(ls secrets/sa_file*.json | head -n1)
  export TF_VAR_YC_SA_ID=$(cat $TF_VAR_YC_SA_FILE | jq -r .service_account_id)
  if ! [ -f secrets/sa_key.json ]; then
    echo -e "$C10 Generate access key for service account...$CR"
    yc iam access-key create --service-account-id $TF_VAR_YC_SA_ID --format json > secrets/sa_key.json
  fi
  access_key=$(cat secrets/sa_key.json | jq -r .access_key.key_id)
  secret_key=$(cat secrets/sa_key.json | jq -r .secret)
  get_yc_vars
fi

create_ssh_key() {
  if ! [ -f "secrets/key_$1" ]; then
    echo -e "$C10 Generate SSH key for $C11$1...$C8"
    ssh-keygen -t ed25519 -N '' -f secrets/key_$1 <<< $'\ny' >/dev/null 2>&1
    echo -e $CR
  fi
}

init() {
  if ! [ -x "$(command -v ansible)" ]; then
    echo -e "$C10 Install Ansible...$C8"
    python3 -m pip install --upgrade --user ansible
  fi
  chmod 0600 $init_dir/secrets/*
  echo -e "$C10 Install YC CLI and Terraform...$CR"
  run_playbook false configure_yc+tf.yml
  cd $init_dir
  # Инициализирование YC CLI
  while [ $TF_VAR_YC_CLOUD_ID = "" ] || [ $TF_VAR_YC_FOLDER_ID = "" ]; do
    yc init
    get_yc_vars
  done
  # Создание сервисного аккаунта
  if ! $(yc iam service-account get $sa_name 1>/dev/null 2>&1); then
    echo -e "$C10 Create service account...$C8"
    yc iam service-account create --name $sa_name
    echo -e "$C10 Add access rights...$C8"
    yc iam service-account add-access-binding --name $sa_name --role editor --service-account-name $sa_name
    echo -e "$C10 Grant access rights to folder...$C8"
    yc resource-manager folder --id $TF_VAR_YC_FOLDER_ID add-access-binding --role editor --service-account-name $sa_name
    echo -e "$C10 Generate account access file...$C8"
    yc iam key create --service-account-name $sa_name -o secrets/sa_file-$sa_file.json
    echo -e "$C10 Generate access key for service account...$C8"
    yc iam access-key create --service-account-name $sa_name --format json > secrets/sa_key.json
  fi
  create_ssh_key bastion
  create_ssh_key kube
  create_ssh_key machine
  # Создание бакета
  if ! $(yc storage bucket get $storage_name 1>/dev/null 2>&1); then
    echo -e "$C10 Create S3 storage...C$8"
    if ! $(yc storage bucket create --name $storage_name 1>/dev/null 2>&1); then
      echo -e "$C12 FAIL! Can't create bucket. May be name is already used?$CR"
      exit
    fi
  fi
}

clean() {
  cd $init_dir
  echo -e "$C12 Remove temporary files...$C8"
  rm ansible/playbook/files/_* 2>/dev/null
  rm -r tf/terraform* 2>/dev/null
  rm -r tf/.terraform 2>/dev/null
  rm -r tf/.terraform.* 2>/dev/null
  echo -e "$C12 Destroy S3 storage...$C8"
  yc storage bucket delete --name $storage_name 2>/dev/null
  echo -e "$C12 Delete service account...$C8"
  yc iam service-account delete --name $sa_name 2>/dev/null
}

check_bastion() {
  cd $terraform_dir
  export TF_WORKSPACE=$(terraform workspace show)
  echo -e "$C15 Use terraform workspace: $C13$TF_WORKSPACE"
  cd $init_dir
  export BASTION_IP=$($vm_list_cmd | jq -r '.[] | select(.name == "'$TF_WORKSPACE'-bastion") | .network_interfaces[].primary_v4_address.one_to_one_nat.address')
  export BASTION_USER=$($vm_list_cmd | jq -r '.[] | select(.name == "'$TF_WORKSPACE'-bastion") | .boot_disk.device_name')
  if [ -z "$BASTION_IP" ]; then
    echo -e "$C12 SSH Bastion does not exist or is not configured as NAT$CR"
    exit 1
  else
    echo -e "$C15 Use SSH Bastion at $C14$BASTION_USER$C6:$C14$BASTION_IP$CR";
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
    echo -e "$C15 Use terraform workspace: $C13$1"
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
  ansible-playbook -i inventory playbook/bootstrap_hosts.yml --tags sudo
}

i_podman() {
  run_playbook true install_podman.yml
}

i_gitlab() {
  run_playbook true install_gitlab.yml
}

gl_backup() {
  run_playbook true backup_create.yml
}

gl_restore() {
  run_playbook true backup_restore.yml
}

i_monitoring() {
  run_playbook true install_influxdb.yml install_grafana.yml install_telegraf.yml
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
    echo -e "$C7 Specify host name to connect without '$C6$TF_WORKSPACE-$C7'"
    yc compute instance list
  else
    if [ "$1" == "bastion" ]; then
      ssh $BASTION_USER@$BASTION_IP -i secrets/key_bastion
    else
      cmd=${@:2}
      ip=$($vm_list_cmd | jq -r '.[] | select(.name == "'$TF_WORKSPACE'-'$1'") | .network_interfaces[0].primary_v4_address.address')
      if [ "$ip" == "" ]; then
        echo "Host name '$1' not exists"
      elif [[ $1 =~ [kube*] ]]; then
        ssh -o ProxyCommand="ssh -W %h:%p -q -i secrets/key_bastion $BASTION_USER@$BASTION_IP" debian@$ip -i secrets/key_kube $cmd
      else
        ssh -o ProxyCommand="ssh -W %h:%p -q -i secrets/key_bastion $BASTION_USER@$BASTION_IP" debian@$ip -i secrets/key_machine $cmd
      fi
    fi
  fi
}

rearm() {
  for n in $($vm_list_cmd | jq -r '.[] | select(.status != "RUNNING") | .name'); do
    echo -e "$C14 Rearm instance: $C13$n $CR..."
    if ! [ "$is_local_vm" = true ]; then
      yc compute instance start $n
    fi
    if [[ $n =~ [*bastion] ]]; then
      check_bastion
      cd $ansible_dir
      ansible-playbook -i inventory --tags bastion playbook/ssh_add_fp.yml
    fi
  done
}

versions() {
  cd $ansible_dir
  echo -e "$C8-$C7-$C15-$C7-$C8- $C10 Git / CI $C8-$C7-$C15-$C7-$C8-$CR"
  grep gitlab_version: inventory/group_vars/gitlab.yml
  grep runner_version: inventory/group_vars/runner.yml
  grep runner_image: inventory/group_vars/runner.yml
  echo -e "$C8-$C7-$C15-$C7-$C8- $C10 Monitoring $C8-$C7-$C15-$C7-$C8-$CR"
  grep grafana_version: inventory/group_vars/grafana.yml
  grep influxdb_version: inventory/group_vars/influxdb.yml
  grep telegraf_version: inventory/group_vars/telegraf.yml
  echo -e "$C8-$C7-$C15-$C7-$C8- $C10 Kubernetes runtime $C8-$C7-$C15-$C7-$C8-$CR"
  grep containerd_version: inventory/group_vars/kube_nodes.yml
  grep runc_version: inventory/group_vars/kube_nodes.yml
  grep cni_plugins_version: inventory/group_vars/kube_nodes.yml
  echo -e "$C8-$C7-$C15-$C7-$C8- $C10 Kubernetes $C8-$C7-$C15-$C7-$C8-$CR"
  grep kube_version: inventory/group_vars/kube_nodes.yml
}

if [ $1 ]; then
  $*
else
  echo -e "$C15 Possible commands:"
  echo -e "$C7  versions     $C7- Print used programm versions"
  echo -e "$C15  init         $C7- Install Ansible,YC CLI,Terraform and preconfigure YC"
  echo -e "$C13  tf_init      $C7- Run Terraform init"
  echo -e "$C5  tf_plan      $C7- Print Terraform plan"
  echo -e "$C13  tf_apply     $C7- Apply Terraform plan"
  echo -e "$C12  tf_destroy   $C7- Destroy Terraform plan"
  echo -e "$C8  i_sudo       $C8- Configure hosts similarly to the YC instance (local VM)"
  echo -e "$C7  i_update     $C7- Update hosts package cache"
  echo -e "$C15  i_bastion    $C7- Configure SSH Bastion"
  echo -e "$C10  i_podman     $C7- Install Podman"
  echo -e "$C10  i_monitoring $C7- Install InfluxDB + Grafana + Telegraf $C14*"
  echo -e "$C2    i_grafana  $C7- Install Grafana $C14*"
  echo -e "$C2    i_influxdb $C7- Install InfluxDB $C14*"
  echo -e "$C2    i_telegraf $C7- Install Telegraf $C14*"
  echo -e "$C9  i_gitlab     $C7- Install GitLab CE $C14*"
  echo -e "$C1   gl_backup   $C7- Create GitLab backup and move to localhost"
  echo -e "$C1   gl_restore  $C7- Copy GitLab backup to remote host and restore it"
  echo -e "$C9  i_runner     $C7- Install GitLab Runner"
  echo -e "$C11  i_kube_pre   $C7- Install Kubernetes Prerequirements"
  echo -e "$C11  i_kube_cl    $C7- Install Kubernetes Cluster"
  echo -e "$C5  run_vm       $C7- Run SSH session or command on remote machine"
  echo -e "$C13  rearm        $C7- Start stopped YC instances"
  echo -e "$C12  clean        $C7- Destroy preconfigured YC resources and clear temporary files"
  echo -e "$C2                 $C14* Steps require podman installed$CR"
fi
