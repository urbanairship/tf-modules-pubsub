# Integration example

Calls the module three times so that every input is set at least once:

- `dead_letter_topic`: topic only (`create_subscriptions = false`).
- `full`: topic with schema, KMS key, storage policy and retention, one push and one pull subscription with every `subscription_details` key the module reads.
- `subscriptions_only`: a pull subscription on the existing `full` topic (`create_topic = false`).

terraform-infrastructure `integration-tests/pubsub/` calls this directory through `?ref=` and passes `project_id`, `name_prefix`, `labels`, `kms_key_name` and `fixture_service_account_email`.

`checks.tf` asserts properties a clean plan does not show. On `v2` three checks fail:

- `push_subscription_keeps_requested_backoff`: the push `retry_policy` reads `subscription_details.minimum_backoff`/`maximum_backoff` keys that do not exist, so the API stores its defaults (10s/600s).
- `pull_subscription_has_dead_letter_policy`: the pull `dead_letter_policy` gate looks up the literal key `subscription_details.dead_letter_topic`.
- `pull_subscription_grants_service_account`: the IAM resources filter on a top-level `service_account` attribute that the variable type drops.

Check failures are reported as warnings by `terraform plan` and `terraform apply`.

The PR body of each terraform-infrastructure integration test run has a `pubsub coverage` section that lists the module variables this example leaves unset.
