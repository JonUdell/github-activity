dashboard "ActivityForPerson" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = <<EOT
ActivityForPerson
🞄
[Relationship](${local.host}/github.dashboard.Relationship)
EOT
    }
  }

  input "username" {
    title = "username"
    width = 2
    query = query.usernames
  }

  input "repo_pattern" {
    type = "combo"
    title = "repo pattern"
    width = 2
    option "turbot" {}
    option "steampipe-mod" {}
    option "steampipe-plugin" {}
    option "steampipe-docs" {}
  }

  input "issue_or_pull" {
    title = "issue/pull"
    width = 2
    option "issue" {}
    option "pull" {}
    option "both" {}
  }

  input "open_or_closed" {
    title = "open/closed"
    width = 2
    option "open" {}
    option "closed" {}
    option "both" {}
  }

  input "updated" {
    base = input.global_updated
  }

  input "text_match" {
    type = "combo"
    title = "match text"
    width = 2
    option "none" {}
  }

  container {

    table {
      base = table.activity
      width = 12
      args = [
        self.input.username.value,
        self.input.repo_pattern.value,
        self.input.issue_or_pull.value,
        self.input.open_or_closed.value,
        self.input.updated,
        self.input.text_match.value
      ]
      column "html_url"{
        wrap = "all"
      }
      column "title" {
        wrap = "all"
      }
    }

  }

}

