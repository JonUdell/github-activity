card "max_updated" {
  width = 2
  sql = <<EOQ
    select max(updated_at) as newest_update
      from
        github_pull_activity_all
  EOQ
}

card "min_updated" {
  width = 2
  sql = <<EOQ
    select min(updated_at) as oldest_update
      from
        github_pull_activity_all
  EOQ
}


