locals {
  labels = { purpose = "integration-test" }
}

module "dead_letter_topic" {
  source               = "github.com/urbanairship/tf-modules-pubsub?ref=v2"
  project_id           = var.project_id
  topic                = "it-pubsub-dead-letter"
  create_subscriptions = false
  topic_labels         = local.labels
}

module "full" {
  source                           = "github.com/urbanairship/tf-modules-pubsub?ref=v2"
  project_id                       = var.project_id
  topic                            = "it-pubsub-full"
  topic_labels                     = local.labels
  topic_message_retention_duration = "86400s"

  message_storage_policy = {
    allowed_persistence_regions = ["us-east1"]
  }

  push_subscriptions = [
    {
      subscription_details = {
        name                       = "it-pubsub-push"
        push_endpoint              = "https://example.com/it-pubsub-push"
        x-goog-version             = "v1"
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
      subscription_labels = local.labels
    }
  ]

  pull_subscriptions = [
    {
      subscription_details = {
        name                         = "it-pubsub-pull"
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
      }
      subscription_labels = local.labels
    }
  ]
}

module "subscriptions_only" {
  source       = "github.com/urbanairship/tf-modules-pubsub?ref=v2"
  project_id   = var.project_id
  topic        = module.full.topic
  create_topic = false

  pull_subscriptions = [
    {
      subscription_details = { name = "it-pubsub-existing-topic-pull" }
      subscription_labels  = local.labels
    }
  ]
}

check "push_subscription_keeps_requested_backoff" {
  data "google_pubsub_subscription" "push" {
    project    = var.project_id
    name       = "it-pubsub-push"
    depends_on = [module.full]
  }

  assert {
    condition     = try(data.google_pubsub_subscription.push.retry_policy[0].minimum_backoff, "") == "15s" && try(data.google_pubsub_subscription.push.retry_policy[0].maximum_backoff, "") == "300s"
    error_message = "Push subscription retry_policy is not 15s/300s."
  }
}

check "pull_subscription_has_dead_letter_policy" {
  data "google_pubsub_subscription" "pull" {
    project    = var.project_id
    name       = "it-pubsub-pull"
    depends_on = [module.full]
  }

  assert {
    condition     = length(data.google_pubsub_subscription.pull.dead_letter_policy) == 1
    error_message = "Pull subscription has no dead_letter_policy although dead_letter_topic is set."
  }
}

output "topic_id" {
  value = module.full.id
}

output "dead_letter_topic_id" {
  value = module.dead_letter_topic.id
}

output "subscription_paths" {
  value = concat(module.full.subscription_paths, module.subscriptions_only.subscription_paths)
}
