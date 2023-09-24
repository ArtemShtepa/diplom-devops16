# Дипломный проект

<details>
<summary>Постановка задачи</summary>

### Цели:

1. Подготовить облачную инфраструктуру на базе облачного провайдера Яндекс.Облако.
1. Запустить и сконфигурировать Kubernetes кластер.
1. Установить и настроить систему мониторинга.
1. Настроить и автоматизировать сборку тестового приложения с использованием Docker-контейнеров.
1. Настроить CI для автоматической сборки и тестирования.
1. Настроить CD для автоматического развёртывания приложения.

---
### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в Яндекс.Облаке при помощи **Terraform**.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться **Terraform** для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя
1. Подготовьте [backend](https://www.terraform.io/docs/language/settings/backends/index.html) для **Terraform**:  
   а. Рекомендуемый вариант: [Terraform Cloud](https://app.terraform.io/)  
   б. Альтернативный вариант: S3 bucket в созданном Яндекс.Облако аккаунте
1. Настройте [workspaces](https://www.terraform.io/docs/language/state/workspaces.html)  
   а. Рекомендуемый вариант: создайте два workspace: *stage* и *prod*. В случае выбора этого варианта все последующие шаги должны учитывать факт существования нескольких workspace.  
   б. Альтернативный вариант: используйте один workspace, назвав его *stage*. Пожалуйста, не используйте workspace, создаваемый **Terraform**-ом по-умолчанию (*default*).
1. Создайте VPC с подсетями в разных зонах доступности.
1. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.
1. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://www.terraform.io/docs/language/settings/backends/index.html) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. **Terraform** сконфигурирован и создание инфраструктуры посредством **Terraform** возможно без дополнительных ручных действий.
1. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

---
### Создание Kubernetes кластера

На этом этапе необходимо создать [Kubernetes](https://kubernetes.io/ru/docs/concepts/overview/what-is-kubernetes/)
кластер на базе предварительно созданной инфраструктуры.
Требуется обеспечить доступ к ресурсам из Интернета.

Это можно сделать двумя способами:

1. Рекомендуемый вариант: самостоятельная установка **Kubernetes** кластера.  
  а. При помощи **Terraform** подготовить как минимум 3 виртуальных машины **Compute Cloud** для создания **Kubernetes**-кластера. Тип виртуальной машины следует выбрать самостоятельно с учётом требовании к производительности и стоимости. Если в дальнейшем поймете, что необходимо сменить тип инстанса, используйте **Terraform** для внесения изменений.  
  б. Подготовить **ansible** конфигурации, можно воспользоваться, например [Kubespray](https://kubernetes.io/docs/setup/production-environment/tools/kubespray/)  
  в. Задеплоить **Kubernetes** на подготовленные ранее инстансы, в случае нехватки каких-либо ресурсов вы всегда можете создать их при помощи **Terraform**.
1. Альтернативный вариант: воспользуйтесь сервисом [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)  
  а. С помощью terraform resource для [kubernetes](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_cluster) создать региональный мастер kubernetes с размещением нод в разных 3 подсетях  
  б. С помощью terraform resource для [kubernetes node group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kubernetes_node_group)

Ожидаемый результат:

1. Работоспособный **Kubernetes** кластер.
1. В файле `~/.kube/config` находятся данные для доступа к кластеру.
1. Команда `kubectl get pods --all-namespaces` отрабатывает без ошибок.

---
### Создание тестового приложения

Для перехода к следующему этапу необходимо подготовить тестовое приложение,
эмулирующее основное приложение разрабатываемое вашей компанией.

Способ подготовки:

1. Рекомендуемый вариант:  
   а. Создайте отдельный **git** репозиторий с простым **nginx** конфигом, который будет отдавать статические данные.  
   б. Подготовьте **Dockerfile** для создания образа приложения.  
1. Альтернативный вариант:  
   а. Используйте любой другой код, главное, чтобы был самостоятельно создан **Dockerfile**.

Ожидаемый результат:

1. **Git** репозиторий с тестовым приложением и **Dockerfile**.
1. Регистр с собранным **docker image**. В качестве регистра может быть [DockerHub](https://hub.docker.com/) или [Yandex Container Registry](https://cloud.yandex.ru/services/container-registry), созданный также с помощью **terraform**.

---
### Подготовка cистемы мониторинга и деплой приложения

Уже должны быть готовы конфигурации для автоматического создания облачной инфраструктуры и поднятия **Kubernetes** кластера.  
Теперь необходимо подготовить конфигурационные файлы для настройки нашего **Kubernetes** кластера.

Цель:
1. Задеплоить в кластер [prometheus](https://prometheus.io/), [grafana](https://grafana.com/), [alertmanager](https://github.com/prometheus/alertmanager), [экспортер](https://github.com/prometheus/node_exporter) основных метрик **Kubernetes**.
1. Задеплоить тестовое приложение, например, [nginx](https://www.nginx.com/) сервер отдающий статическую страницу.

Рекомендуемый способ выполнения:
1. Воспользовать пакетом [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus), который уже включает в себя [Kubernetes оператор](https://operatorhub.io/) для [grafana](https://grafana.com/), [prometheus](https://prometheus.io/), [alertmanager](https://github.com/prometheus/alertmanager) и [node_exporter](https://github.com/prometheus/node_exporter). При желании можете собрать все эти приложения отдельно.
1. Для организации конфигурации использовать [qbec](https://qbec.io/), основанный на [jsonnet](https://jsonnet.org/). Обратите внимание на имеющиеся функции для интеграции **helm** конфигов и [helm charts](https://helm.sh/)
1. Если на первом этапе вы не воспользовались [Terraform Cloud](https://app.terraform.io/), то задеплойте в кластер [atlantis](https://www.runatlantis.io/) для отслеживания изменений инфраструктуры.

Альтернативный вариант:
1. Для организации конфигурации можно использовать [helm charts](https://helm.sh/)

Ожидаемый результат:
1. **Git** репозиторий с конфигурационными файлами для настройки **Kubernetes**.
2. **Http** доступ к **web** интерфейсу **grafana**.
3. Дашборды в **grafana** отображающие состояние **Kubernetes** кластера.
4. **Http** доступ к тестовому приложению.

---
### Установка и настройка CI/CD

Осталось настроить **CI/CD** систему для автоматической сборки **docker image** и деплоя приложения при изменении кода.

Цель:

1. Автоматическая сборка **docker образа** при коммите в репозиторий с тестовым приложением.
1. Автоматический деплой нового **docker** образа.

Можно использовать [teamcity](https://www.jetbrains.com/ru-ru/teamcity/), [jenkins](https://www.jenkins.io/), [GitLab CI](https://about.gitlab.com/stages-devops-lifecycle/continuous-integration/) или GitHub Actions.

Ожидаемый результат:

1. Интерфейс **CI/CD** сервиса доступен по **http**.
1. При любом коммите в репозиторие с тестовым приложением происходит сборка и отправка в регистр **Docker** образа.
1. При создании тега (например, `v1.0.0`) происходит сборка и отправка с соответствующим **label** в регистр, а также деплой соответствующего **Docker** образа в кластер **Kubernetes**.

---
### Что необходимо для сдачи задания?

1. Репозиторий с конфигурационными файлами **Terraform** и готовность продемонстрировать создание всех ресурсов с нуля.
1. Пример **pull request** с комментариями созданными **atlantis**'ом или снимки экрана из **Terraform Cloud**.
1. Репозиторий с конфигурацией **ansible**, если был выбран способ создания **Kubernetes** кластера при помощи **ansible**.
1. Репозиторий с **Dockerfile** тестового приложения и ссылка на собранный **docker image**.
1. Репозиторий с конфигурацией **Kubernetes** кластера.
1. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
1. Все репозитории рекомендуется хранить на одном ресурсе (**github, gitlab**)

</details>

## Состав инфраструктуры

Проект составлен с учётом двух рабочих пространств:
- Основное или полное: `prod`
- Тестовое или сокращённое: `stage`

Рабочие пространство разделены как инфраструктурно на уровне **Terraform**, так и на уровне пространства имён кластера **Kubernetes**.

### Схема инфраструктуры рабочего пространства `prod`

![Инфраструктура prod](./schema_source/infrastructure-prod.png)

### Схема инфраструктуры рабочего пространства `stage`

![Инфраструктура stage](./schema_source/infrastructure-stage.png)

> Исходный код схем расположен в каталоге  [schema_source](./schema_source) в файлах формата **draw.io**

Инфраструктура создаётся **Terraform** провайдером Яндекс.Облака.
В зависимости от рабочего пространства создаются от 7 до 10 виртуальных машин с различными характеристиками.
В каждом из рабочих пространств только одна из машина имеет внешний IP адрес - это SSH бастион. Весь трафик из внутренней сети в сеть интернет осуществляется через бастион. Доступ к внутренним ресурсам из интернет также осуществляется через бастион благодаря установленному на нём балансировщику **HAProxy**.

> Исходных код **Terraform** расположен в каталоге [tf](./tf)



## Приложение

Простейший API сервер на языке **GoLang**, обрабатывающий HTTP запросы:
  - По **url** `/task/<id>` выводит в лог число `<id>`. В ответном JSON блоке результат преобразования `<id>` в число
  - По **url** `/wait` замораживает выполнение приложения от 1 до 5 секунд. В ответном JSON блоке включается время начала и окончания заморозки в формате ISO и Unix Timestamp
  - На остальные **url** в ответный JSON блок включается путь и HTTP метод запроса

Приложение, по умолчанию, принимает соединения со всех адресов по порту **8080** (`0.0.0.0:8080`).

Изменить прослушиваемый порт и принимамые адреса можно
параметром запуска `-addr` (например, `apiserver --addr 127.0.0.1:80`),
либо переменной окружения `API_BIND` (например, `export API_BIND=:8090`)

[Исходный код](./app_source/apiserver.go)




## Справочные материалы

### Документация Яндекс.Облака и Terraform
1. Описание [платформ](https://cloud.yandex.ru/docs/compute/concepts/vm-platforms) и допустимые [конфигурации](https://cloud.yandex.ru/docs/compute/concepts/performance-levels)
1. Описание [Terraform провайдера](https://terraform-provider.yandexcloud.net//index)
1. [Создание авторизованных ключей](https://cloud.yandex.ru/docs/iam/operations/authorized-key/create) для доступа через сервисный аккаунт
1. Зеркало дистрибутивов [Terraform](https://hashicorp-releases.yandexcloud.net/terraform/)
1. Документация по языку [Terraform](https://developer.hashicorp.com/terraform/language)

### Документация GitLab
1. Ключевые слова [CI/CD](https://docs.gitlab.com/ee/ci/yaml/)
1. Предопределённые переменные [CI/CD](https://docs.gitlab.com/ee/ci/variables/predefined_variables.html)

### Документация Kubernetes и связанного с ним
1. Установка [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
1. [Отказоустойчивый кластер](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)
1. Репозиторий Kubeadm: [Советы по отказоустойчивости кластера](https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing)
1. Допусимые [Container runtimes](https://kubernetes.io/docs/setup/production-environment/container-runtimes/)
1. Репозиторий [containerd](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)

<details>
<summary>Всякая всячина</summary>

### Подсказки разной степени полезности
1. Статья: [How to Install Kubernetes Cluster on Debian 11 with Kubeadm](https://www.linuxtechi.com/install-kubernetes-cluster-on-debian/)
1. Статья: [Install Kubernetes Cluster with Ansible on Ubuntu in 5 minutes](https://www.linuxsysadmins.com/install-kubernetes-cluster-with-ansible/)
1. Статья: [Разворачиваем кластер Kubernetes на Debian](https://unlix.ru/разворачиваем-кластер-kubernetes-на-debian/)
1. Статья: [Бекенды для хранения состояния Terraform](https://ru.hexlet.io/courses/terraform-basics/lessons/remote-state/theory_unit)

### Полезные команды

Получение хэша сертификата
```console
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
    | openssl rsa -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -hex | sed 's/^.* //'
```

</details>
