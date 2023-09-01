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

[Схема инфраструктуры](https://viewer.diagrams.net/?tags=%7B%7D&target=blank&highlight=0000ff&layers=1&nav=1&title=%D0%A1%D1%85%D0%B5%D0%BC%D0%B0%20%D0%B8%D0%BD%D1%84%D1%80%D0%B0%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%82%D1%83%D1%80%D1%8B.drawio#R7ZxLb6s4FMc%2FTaSZRSvekGXT50hzpUpd3NFsKgecxApgZJyGO59%2BbMAhwU4Kt5CENF1QcrB5nP%2FP9rGxGZn3UfZMQLL4gQMYjgwtyEbmw8gwdG3ssX%2Fc8quweEZpmBMUlIkqwxv6D4qcpXWFApjuJKQYhxQlu0YfxzH06Y4NEILXu8lmONy9agLmUDK8%2BSCUrT9RQBfiKdzK%2FgLRfCGurDvj4kgEROLySdIFCPB6y2Q%2Bjsx7gjEt9qLsHobcecIvRb6nPUc3N0ZgTJtkSPyxNn0hS3f6L7n5ESfmP%2BbLjbi5DxCuyicu75b%2BEi4geBUHkJ9FH5mT9QJR%2BJYAnx9dM9GZbUGjsDws31V5ox%2BQUJhtmcq7fIY4gpT8YknKo%2BbYvrWLTCU04i7XlQKWVtoWW97fJASl6vPNySvHsJ3SNy38pI8H4SdH4Sj9uI7yOnZUCKYwfMUpogjHzOYzh0HCDnBHIVZQ%2F64liFAQ8CtNQIjmyhx35YFNyg7EEDn2E2valpBrWwrH7k0KSYlXgjN2Xidk155MCdub8723txeWbvSgjcY6307Yvj7y9Hxr5BYv3z7m2wf5DH9MQcrd%2F6ek9T6VpphSHLGs6RJSn7tI45KlSVGJz1DGAdkGoa4exZyUlBK8hPc4xEzhhxjHSuXxioYoZslEI8EvxirkhN9llM1523XrI0pQdptwJ72nkHzkWbtgw6oXVFvBh%2Buo8Bj3RYchl1MOgFdKXElv5%2FuasG8scrkentbzEE87qgAsUY6FxKZCYk8lsWv3JLHcZjGnMB%2FyjK8hYO6TC%2FJHdLNcTeGN3rwob6rR35a3OsMhhUnhslYC%2BziKQBy8b%2BioNychnNFuANCl5lgfKxCwlaXc6asNkOO75gyYl1CdSwR0Uda9utSmdXqp5fa%2BudRGc6lLoX5X54qU%2FqXeGzt2wYBTZ0ARfB8bAblR%2F4nJEpIDyluXUdFnMAZJUoVt%2FdXzcjSnKvuOLLs37kt2s73sziXU7XXRO1DXsaVOtXdqea328tqXUJ9%2FVqa7rM4dKXpz3BPLbkuyPyPK1FPLHgEUt4naz7dUBzBdsnO%2Fr%2BG0G21dKVpzTYW2R%2B1%2B646sLgEzEANZ3r%2FiWbjKHiYHhG8Rv31n4W3DEJYTSu9K0vM626c8Z6IeopsjGvKSr5EVc%2BSemj8n4SI6bcHC77ZZl4M2ZY9NUb%2F3NwAnR22ScjAO7vhLLO7HEKQp8nN3A0Jl85ZM1QC7dsh9KV4RHx4itUjHrjeH9NCjFOlgsPMuTRZjy9W24q2EsBEYAoo%2Bdt%2FAqfxfXuEVI%2FZkB96LWPUx9uLJy3zG1juz2qksRaxfO1XhHOlUORKbR%2F8CJXLwd3aU2A0x0a%2BY9IaJHCyeHSZNKXGumPSGiRx1nh0mbkNOxldMesNEjlAHi4l4A3LlpAdOGkz2GAwn1%2BikN04s%2BdVUM05OGq26VyB6A6Jd37ccUghAuthMG%2BsDjcYh6tm3KW53aNSnCvaNRrsObys08hcIE%2BAv57ldjFiNDNNhf09PX6JnfDHwDLheade%2FOVK90piMawjSHxntujSfkMHtr4BSSOLcYmjmZhxcLBMwTkGQcSWoN4LadXaGSpB5Jag3ghosIrkAgqwrQX0RJO58mASJyPcCKqHh9q%2FsdmMxvSC0vx%2F2lP99jTKrKWVn3xEbMGXGpVNmXAxlA24OOx1GPHpz2Hi48doc9odQp8ONR0eocVt39kNLA0ao3dybc0OocUN29ggNuCFTjVuXU3zFDN98eba7sw6%2FWKtfLN2fWOLQ9tJ9tjVz%2B9NWlkfF8n5DuxNXZE9QXbQOMoUZ3QVWOft3hsLwswnBexeHqb4I0RD3Fl%2FPkGug4ucWvp4KX3M%2FqV%2BaD2yrRqiPzMDkezHgatKSbcVir%2BNSoBplPjIF99%2Bdgs03c7qngP2sPvlUNB%2FVh7PMx%2F8B)

Исходный код схемы приведён в файле [infrastructure.drawio](./schema_source/infrastructure.drawio)

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
