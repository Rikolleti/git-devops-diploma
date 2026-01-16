# Дипломный практикум: Yandex Cloud + Terraform + Kubernetes

Данный репозиторий содержит выполнение дипломного задания по развёртыванию облачной инфраструктуры, Kubernetes-кластера и подготовке платформы для дальнейшего деплоя

---

## 📌 Выполненные этапы

### 1. Подготовка Terraform и удалённого backend

- Настроен **удалённый backend Terraform** в **Yandex Object Storage** (S3-совместимый).
- State-файл (`terraform.tfstate`) хранится **в облаке**, а не локально.
- Для доступа используется **Service Account + static access key**.
- Backend инициализируется через `backend.tf` + `backend.hcl`.

📁 Структура:
'''
terraform/
├── bootstrap/ # создание bucket и ключей
└── infra/ # основная инфраструктура
'''


---

### 2. Облачная инфраструктура (Terraform)

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


---

### 3. Managed Kubernetes в Yandex Cloud

Развёрнут **Managed Kubernetes кластер** с использованием Terraform:

- Regional master (multi-AZ)
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

### 4. Доступ к Kubernetes кластеру

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
