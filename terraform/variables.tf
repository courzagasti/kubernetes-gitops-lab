variable "kubeconfig_path" {
  type        = string
  description = "Ruta al kubeconfig de Windows (admite ~)."
  default     = "~/.kube/config"
}
