variable "project_id" {
  description = "GCP project id"
  default     = "github-actions-378014"
}

variable "region" {
  description = "region"
  default     = "asia-northeast1"
}

variable "function_name" {
  description = "my function name"
  default     = "test-function"
}

variable "env" {
  description = "select environment"
  default     = "dev"
}
