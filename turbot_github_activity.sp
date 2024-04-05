dashboard "Turbot_GitHub_Activity_By_Person" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = replace(
        replace(
          "${local.menu}",
          "__HOST__",
          "${local.host}"
        ),
        "[Turbot_GitHub_Activity_By_Person](${local.host}/github_activity.dashboard.Turbot_GitHub_Activity_By_Person)",
        "Turbot_GitHub_Activity_By_Person"
      )
    }
  }  

  input "username" {
    title = "username"
    type = "combo"
    width = 2
    base = input.turbot_logins
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
        self.input.updated.value,
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

table "activity" {
  sql = <<EOT
    select
        array_to_string(array_agg(type order by type), ', ') as type,
        html_url,
        title,
        to_char(updated_at, 'YYYY-MM-DD') as updated_at,
        to_char(created_at, 'YYYY-MM-DD') as created_at,
        to_char(closed_at, 'YYYY-MM-DD') as closed_at
    from
        github_activity(
          $1,
          $2,
          $5,
          case
            when $6 = 'none' then ''
            else $6
          end
        )
    where
        html_url ~
          case
            when $3 = 'issue' then 'issue'
            when $3 = 'pull' then 'pull'
            else 'issue|pull'
          end
        and case
          when $4 = 'open' then closed_at is null
          when $4 = 'closed' then closed_at is not null
          else closed_at is null or closed_at is not null
        end
    group by
      html_url, title, updated_at, created_at, closed_at
  EOT
}

