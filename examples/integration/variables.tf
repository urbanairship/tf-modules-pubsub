variable "project_id" {
  description = "Project the example resources are created in."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for every resource name."
  type        = string
}

variable "labels" {
  description = "Labels set on every labelled resource."
  type        = map(string)
}

variable "kms_key_name" {
  description = "Cloud KMS key in us-east1 the topic is encrypted with. The Pub/Sub service agent needs encrypter/decrypter on it."
  type        = string
}

variable "fixture_service_account_email" {
  description = "Service account used for push OIDC tokens and pull subscription IAM."
  type        = string
}

variable "push_endpoint" {
  description = "HTTPS endpoint of the push subscription. Pub/Sub accepts any HTTPS URL at create time."
  type        = string
  default     = "https://example.com/integration-test-push"
}
