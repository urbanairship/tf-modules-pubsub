locals {
  full_topic = "${var.name_prefix}-full"
}

module "dead_letter_topic" {
  source               = "../../"
  project_id           = var.project_id
  topic                = "${var.name_prefix}-dead-letter"
  create_subscriptions = false
  topic_labels         = var.labels
}

module "full" {
  source                           = "../../"
  project_id                       = var.project_id
  topic                            = local.full_topic
  create_topic                     = true
  create_subscriptions             = true
  topic_labels                     = var.labels
  topic_message_retention_duration = "86400s"
  topic_kms_key_name               = var.kms_key_name

  message_storage_policy = {
    allowed_persistence_regions = ["us-east1"]
  }

  schema = {
    name       = "${var.name_prefix}-schema"
    type       = "AVRO"
    definition = jsonencode({ type = "record", name = "IntegrationTestEvent", fields = [{ name = "id", type = "string" }] })
    encoding   = "JSON"
  }

  push_subscriptions = [
    {
      subscription_details = {
        name                       = "${var.name_prefix}-push"
        push_endpoint              = var.push_endpoint
        x-goog-version             = "v1"
        oidc_service_account_email = var.fixture_service_account_email
        audience                   = var.push_endpoint
        ack_deadline_seconds       = "20"
        message_retention_duration = "604800s"
        retain_acked_messages      = "true"
        filter                     = "attributes.channel = \"push\""
        expiration_policy          = ""
        dead_letter_topic          = module.dead_letter_topic.id
        max_delivery_attempts      = "5"
        minimum_backoff            = "15s"
        maximum_backoff            = "300s"
      }
      subscription_labels = var.labels
    }
  ]

  pull_subscriptions = [
    {
      subscription_details = {
        name                         = "${var.name_prefix}-pull"
        ack_deadline_seconds         = "30"
        message_retention_duration   = "86400s"
        retain_acked_messages        = "false"
        filter                       = "attributes.channel = \"pull\""
        expiration_policy            = "2678400s"
        dead_letter_topic            = module.dead_letter_topic.id
        max_delivery_attempts        = "10"
        minimum_backoff              = "15s"
        maximum_backoff              = "300s"
        enable_exactly_once_delivery = "true"
        enable_message_ordering      = "true"
        service_account              = var.fixture_service_account_email
      }
      subscription_labels = var.labels
    }
  ]
}

module "subscriptions_only" {
  source       = "../../"
  project_id   = var.project_id
  topic        = local.full_topic
  create_topic = false

  pull_subscriptions = [
    {
      subscription_details = {
        name = "${var.name_prefix}-existing-topic-pull"
      }
      subscription_labels = var.labels
    }
  ]

  depends_on = [module.full]
}
