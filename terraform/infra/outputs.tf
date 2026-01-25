output "vm_public_ip" {
  value = yandex_compute_instance.vm1.network_interface[0].nat_ip_address
}

output "k8s_cluster_name" {
  value = yandex_kubernetes_cluster.k8s.name
}

output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.k8s.id
}

output "container_registry_id" {
  value = yandex_container_registry.main.id
}

#
#
