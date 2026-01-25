output "vm_public_ip" {
  description = "Public IP of compute VM (null if VM is disabled)"
  value       = try(yandex_compute_instance.vm1[0].network_interface[0].nat_ip_address, null)
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
