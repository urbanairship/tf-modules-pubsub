output "topic_id" {
  value = module.full.id
}

output "dead_letter_topic_id" {
  value = module.dead_letter_topic.id
}

output "subscription_paths" {
  value = concat(module.full.subscription_paths, module.subscriptions_only.subscription_paths)
}
