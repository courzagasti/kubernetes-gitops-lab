provider "helm" {
  kubernetes {
    config_path    = pathexpand(var.kubeconfig_path)
    config_context = "docker-desktop"
  }
}
provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig_path)
  config_context = "docker-desktop"
}
