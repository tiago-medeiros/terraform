variable "cluster_stack" {
  description = "Name of the EKS stack"
  type        = string
  default     = "localstack"
}

variable "app_stack" {
  description = "Name of the app stack"
  type        = string
  default     = "localstack"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}