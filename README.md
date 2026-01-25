# Дипломный практикум в Yandex Cloud
#

Данный репозиторий содержит выполнение дипломного задания по развёртыванию облачной инфраструктуры, Kubernetes-кластера и подготовке платформы для дальнейшего деплоя

---

## Выполненные этапы

### 1. Подготовка Terraform и удалённого backend

- Настроен **удалённый backend Terraform** в **Yandex Object Storage** (S3-совместимый).
- State-файл (`terraform.tfstate`) хранится **в облаке**, а не локально.
- Для доступа используется **Service Account + static access key**.
- Backend инициализируется через `backend.tf` + `backend.hcl`.

📁 Структура:
```
terraform/
├── backend/
└── infra/
```


---

#### 1.1 Облачная инфраструктура (Terraform)

С помощью Terraform создана базовая инфраструктура в Yandex Cloud:

- VPC (Virtual Private Cloud)
- 3 подсети в разных зонах доступности:
  - `ru-central1-a`
  - `ru-central1-b`
  - `ru-central1-d`
- Виртуальная машина Compute Cloud для вспомогательных задач
- Используется remote state (Object Storage)

📁 Основные файлы:
```
infra/
├── main.tf # VPC, subnet, VM
├── locals.tf
├── variables.tf
├── outputs.tf
```

Результат:
```
rikolleti@compute-vm-2-2-30-hdd-1751355561681:~/Netology/git-2-diploma/terraform$ yc compute instance list
+----------------------+-------------------------------------+---------------+---------+-----------------+---------------+
|          ID          |                NAME                 |    ZONE ID    | STATUS  |   EXTERNAL IP   |  INTERNAL IP  |
+----------------------+-------------------------------------+---------------+---------+-----------------+---------------+
| epdgllrf42et6fifvv3m | cl1u5hukgn3667un5a7v-uhab           | ru-central1-b | RUNNING | 158.160.66.197  | 192.168.11.17 |
| fhm15se23j8uhgsp0674 | netology_vm1                        | ru-central1-a | RUNNING | 158.160.51.200  | 192.168.10.34 |
| fhmsvvni1hre9um1hkha | cl1u5hukgn3667un5a7v-ujop           | ru-central1-a | RUNNING | 178.154.201.219 | 192.168.10.10 |
```

---

### 2. Managed Kubernetes в Yandex Cloud

Развёрнут **Managed Kubernetes кластер** с использованием Terraform:

- Regional master (multi zone)
- Master размещён в 3 подсетях (по одной в каждой зоне)
- Публичный доступ к API (`public_ip = true`)
- Node Group:
  - 2 worker-ноды
  - прерываемые (preemptible)
  - размещены в зонах `ru-central1-a` и `ru-central1-b`
  - зона `ru-central1-d` исключена из node group из-за недоступности платформы `standard-v1`

Для кластера создан отдельный **Service Account** с необходимыми ролями:
- `k8s.editor`
- `k8s.clusters.agent`
- `container-registry.images.puller`
- `vpc.user`
- `vpc.publicAdmin`

📁 Kubernetes-ресурсы вынесены в отдельный файл:
```
infra/
├── k8s.tf
```


---

#### 2.1 Доступ к Kubernetes кластеру

- Конфигурация доступа сохранена в `~/.kube/config`
- Контекст добавлен через `yc managed-kubernetes cluster get-credentials`
- Проверка доступа выполнена успешно

```bash
kubectl get pods --all-namespaces
NAMESPACE     NAME                                 READY   STATUS    RESTARTS      AGE
kube-system   coredns-768847b69f-2mb65             1/1     Running   0             39m
kube-system   coredns-768847b69f-lvb6n             1/1     Running   0             48m
kube-system   ip-masq-agent-26bhx                  1/1     Running   0             40m
kube-system   ip-masq-agent-t92nk                  1/1     Running   0             39m
kube-system   kube-dns-autoscaler-66b55897-54gnv   1/1     Running   1 (40m ago)   48m
kube-system   kube-proxy-hkdbn                     1/1     Running   0             40m
kube-system   kube-proxy-n2tgn                     1/1     Running   0             39m
kube-system   metrics-server-8689cb9795-hspp6      1/1     Running   0             48m
kube-system   metrics-server-8689cb9795-m9frf      1/1     Running   0             48m
kube-system   npd-v0.8.0-cx7w2                     1/1     Running   0             39m
kube-system   npd-v0.8.0-xgch5                     1/1     Running   0             40m
kube-system   yc-disk-csi-node-v2-gcjsq            6/6     Running   0             39m
kube-system   yc-disk-csi-node-v2-hv7gj            6/6     Running   0             40m
```

### 3. Создание тестового приложения

В рамках дипломного задания подготовлено и развернуто тестовое приложение
для проверки полного цикла:

**Docker → Container Registry → Kubernetes → LoadBalancer**

В качестве приложения используется простой **nginx** с кастомной HTML-страницей.

---

#### 3.1 Docker-образ приложения

Создан Dockerfile для сборки образа:

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

Docker-образ собран и загружен в Yandex Container Registry:

```
docker build -t cr.yandex/crp602u6ka42e2m3tmst/netology-nginx:latest .
docker push cr.yandex/crp602u6ka42e2m3tmst/netology-nginx:latest
```

Проверка образа в реестре:

```
rikolleti@compute-vm-2-2-30-hdd-1751355561681:~/Netology/git-2-diploma/terraform/app$ yc container image list --registry-id crp602u6ka42e2m3tmst
+----------------------+---------------------+-------------------------------------+--------+-----------------+
|          ID          |       CREATED       |                NAME                 |  TAGS  | COMPRESSED SIZE |
+----------------------+---------------------+-------------------------------------+--------+-----------------+
| crpo850n7658snl1g0rb | 2026-01-18 12:51:06 | crp602u6ka42e2m3tmst/netology-nginx | latest | 24.7 MB         |
+----------------------+---------------------+-------------------------------------+--------+-----------------+
```

После создания сервиса Kubernetes автоматически создал внешний балансировщик в Yandex Cloud:

<img width="823" height="489" alt="Снимок экрана 2026-01-18 в 18 10 22" src="https://github.com/user-attachments/assets/277d7d80-a1ed-40b8-9156-3b1d1e3ba462" />


Вывод в браузере:

<img width="660" height="169" alt="Снимок экрана 2026-01-18 в 19 15 42" src="https://github.com/user-attachments/assets/29123e2b-6496-486e-a5b3-40badc7ed0bf" />


### 4. Подготовка системы мониторинга и деплой приложения

На этом этапе развёрнут мониторинг Kubernetes:
- Prometheus  
- Grafana  
- Alertmanager  
- Node exporter

Мониторинг развернут в namespace `monitoring` и доступен через LoadBalancer.

```
monitoring/
├── monitoring-values.yaml
```

Создан yaml файл monitoring-values.yaml чтобы Grafana была LoadBalancer на 80:
```
kubectl -n monitoring get svc monitoring-grafana
NAME                 TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)        AGE
monitoring-grafana   LoadBalancer   10.96.193.28   158.160.216.152   80:32167/TCP   4m31s
```

Получен http доступ на 80 порту к web интерфейсу grafana:

<img width="1511" height="834" alt="1" src="https://github.com/user-attachments/assets/66ee0c15-68b0-498d-82a3-851a1317372f" />

Присутствуют дашборды в grafana отображающие состояние Kubernetes кластера

<img width="1511" height="834" alt="2" src="https://github.com/user-attachments/assets/9c26fc49-3947-4459-a94e-7ba4dc786183" />

<img width="1511" height="855" alt="3" src="https://github.com/user-attachments/assets/b56ea3c8-6834-41da-93a3-968817c47043" />

<img width="1511" height="772" alt="4" src="https://github.com/user-attachments/assets/6ad01bcc-4d01-42c5-ab13-ca4df6823593" />

#### 4.1. Деплой инфраструктуры в Terraform pipeline (CI/CD Terraform)

Для автоматизации управления инфраструктурой использован CI/CD пайплайн Terraform на базе GitHub Actions

CI/CD настроен для каталога:
```
terraform/infra
```

Workflow:
```
.github/workflows/terraform.yml
```

Terraform variables:
Передаются через TF_VAR_*
В репозитории отсутствуют секреты и ключи доступа

Проверка инфраструктуры выполняется при каждом Pull Request и применение изменений выполняется автоматически при merge в master:

<img width="1511" height="808" alt="5" src="https://github.com/user-attachments/assets/29f1c261-3a6e-48c1-aa0a-38451da0fae8" />

<img width="1511" height="794" alt="6" src="https://github.com/user-attachments/assets/6e7b6990-edeb-4260-bfaf-1bc76e476883" />

<img width="719" height="337" alt="7" src="https://github.com/user-attachments/assets/00e9e030-2a41-465f-8db1-f8bd3eec7d84" />

### 5. CI/CD приложения

Workflow описан в файле:
```
.github/workflows/app.yml
```

Он выполняет следующие задачи:

#### 1️⃣ Сборка и публикация Docker-образа

- При **коммите в ветку `master`**:
  - собирается Docker-образ приложения
  - образ публикуется в **Yandex Container Registry** с тегом `latest`

- При **создании git-тега формата `v*` (например `v1.0.7`)**:
  - собирается Docker-образ
  - образ публикуется в YCR с версионным тегом (`v1.0.7`)

Используемая команда сборки:
```bash
docker build -t cr.yandex/<REGISTRY_ID>/<IMAGE_NAME>:<TAG> .
```

Для работы CI/CD используются следующие GitHub Secrets:
1. YC_SA_KEY — JSON-ключ Service Account для доступа к Yandex Cloud
2. YC_REGISTRY_ID — ID Yandex Container Registry
3. YC_IMAGE_NAME — имя Docker-образа
4. KUBE_CONFIG_B64 — kubeconfig Kubernetes-кластера, закодированный в base64

Push тега версии:
```
git tag v1.0.7
git push origin v1.0.7
```

Приложение собирается из Dockerfile:
```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

При пуше тега workflow выполняет деплой новой версии приложения:
```bash
kubectl -n app set image deployment/netology-nginx \
  nginx=cr.yandex/<REGISTRY_ID>/netology-nginx:v1.0.7
```

Проверка вывода версии в containter list:
```
rikolleti@compute-vm-2-2-30-hdd-1751355561681:~/Netology/git-2-diploma$ yc container image list
+----------------------+---------------------+-------------------------------------+--------+-----------------+
|          ID          |       CREATED       |                NAME                 |  TAGS  | COMPRESSED SIZE |
+----------------------+---------------------+-------------------------------------+--------+-----------------+
| crp2k4mau6agbcd3en8c | 2026-01-25 16:32:23 | crp602u6ka42e2m3tmst/netology-nginx | v1.0.7 | 24.7 MB         |
```

<img width="678" height="205" alt="Снимок экрана 2026-01-25 в 21 36 29" src="https://github.com/user-attachments/assets/a9a4a867-e3eb-43bd-8e2f-048cd7a495f6" />


<img width="1031" height="568" alt="Снимок экрана 2026-01-25 в 21 38 11" src="https://github.com/user-attachments/assets/a320983d-797f-469d-850a-f31b413f890b" />


<img width="1153" height="723" alt="Снимок экрана 2026-01-25 в 21 38 49" src="https://github.com/user-attachments/assets/e8b822c7-74fc-4233-bd23-b40a6725776d" />
