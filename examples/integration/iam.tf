resource "google_service_account" "pubsub" {
  project    = "ua-ops-infra-test"
  account_id = "it-pubsub"
}

# Pub/Sub mints the push OIDC token as this SA.
resource "google_service_account_iam_member" "pubsub_agent_token_creator" {
  service_account_id = google_service_account.pubsub.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:service-130461057978@gcp-sa-pubsub.iam.gserviceaccount.com"
}
