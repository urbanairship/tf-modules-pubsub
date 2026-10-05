check "push_subscription_keeps_requested_backoff" {
  data "google_pubsub_subscription" "push" {
    project = var.project_id
    name    = "${var.name_prefix}-push"
  }

  assert {
    condition     = try(data.google_pubsub_subscription.push.retry_policy[0].minimum_backoff, "") == "15s" && try(data.google_pubsub_subscription.push.retry_policy[0].maximum_backoff, "") == "300s"
    error_message = "Push subscription retry_policy is not 15s/300s."
  }
}

check "pull_subscription_has_dead_letter_policy" {
  data "google_pubsub_subscription" "pull" {
    project = var.project_id
    name    = "${var.name_prefix}-pull"
  }

  assert {
    condition     = length(data.google_pubsub_subscription.pull.dead_letter_policy) == 1
    error_message = "Pull subscription has no dead_letter_policy although dead_letter_topic is set."
  }
}

check "pull_subscription_grants_service_account" {
  data "google_pubsub_subscription_iam_policy" "pull" {
    project      = var.project_id
    subscription = "${var.name_prefix}-pull"
  }

  assert {
    condition     = try(strcontains(data.google_pubsub_subscription_iam_policy.pull.policy_data, "serviceAccount:${var.fixture_service_account_email}"), false)
    error_message = "Pull subscription IAM policy does not include service_account."
  }
}
