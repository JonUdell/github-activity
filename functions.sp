dashboard "drop_functions" {

  with "drop_github_activity" {
    sql = <<EOQ
      drop function github_activity;
    EOQ
  }

  with "drop_github_pull_activity" {
    sql = <<EOQ
      drop function github_pull_activity;
    EOQ
  }

  with "drop_github_org_members" {
    sql = <<EOQ
      drop function github_org_members;
    EOQ
  }

  with "drop_github_org_excluded_members" {
    sql = <<EOQ
      drop function github_org_excluded_members;
    EOQ
  }

}