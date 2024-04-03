mod "github_activity" {
  title = "GitHub Activity"
}

locals {
  //host = "https://pipes.turbot.com/org/turbot-ops/workspace/stats/dashboard"
  host = "http://localhost:9194"
  //host = "http://localhost:9033"
  default_org = "turbot"

  menu = <<EOT
[Turbot_GitHub_Activity_By_Person](__HOST__/github_activity.dashboard.Turbot_GitHub_Activity_By_Person)
•
[Turbot_Pull_Requests_By_Person](__HOST__/github_activity.dashboard.Turbot_Pull_Requests_By_Person)
•
[Turbot_Issues_By_Person](__HOST__/github_activity.dashboard.Turbot_Issues_By_Person)
•
[Community_Pull_Requests](__HOST__/github_activity.dashboard.Community_Pull_Requests)
•
[Community_Issues](__HOST__/github_activity.dashboard.Community_Issues)
EOT
}