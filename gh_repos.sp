dashboard "Repos" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = <<EOT
[ActivityForPerson](${local.host}/github.dashboard.ActivityForPerson)
🞄
[ExternalPeople](${local.host}/github.dashboard.ExternalPeople)
🞄
Repos

EOT
    }
  }

  container {

    input "repos" {
      width = 4
      base = input.global_repos
    }

    input "updated" {
      title = "pull requests updated since"
      width = 3
      base = input.global_updated
    }

  }

  container {

    graph {

      category "repo" {
        color = "yellow"
        icon = "server"
      }

      category "person_org" {
        color = "orange"
        icon = "person"
        href = "${local.host}/github.dashboard.ActivityForPerson?input.repo_pattern=turbot&input.issue_or_pull=both&input.open_or_closed=both&input.text_match=none&input.username={{.properties.'login'}}&input.updated=2021-01-01"
      }

      category "closed-pull-request" {
        color = "green"
        icon = "question-mark-circle"
        href = "https://github.com/{{.properties.'repository_full_name'}}/pull/{{.properties.'number'}}"
      }

      category "open-pull-request" {
        color = "red"
        icon = "question-mark-circle"
        href = "https://github.com/{{.properties.'repository_full_name'}}/pull/{{.properties.'number'}}"
      }

      node {
        args = [ self.input.repos, self.input.updated ]
        base = node.org_repo
      }

      node {
        args = [ self.input.repos, self.input.updated ]
        base = node.closed_pull_requests_for_repo
      }

      node {
        args = [ self.input.repos, self.input.updated ]
        base = node.open_pull_requests_for_repo
      }

      node {
        base = node.people_org_members
      }

      edge {
        args = [ self.input.repos, self.input.updated ]
        base = edge.pr_repo
      }

      edge {
        args = [ self.input.repos, self.input.updated ]
        base = edge.person_pr
      }

    }

  }

  container {

    table {
      title = "github_pull_activity_repo"
      args = [ self.input.repos, self.input.updated ]
      sql = <<EOQ
        select
          number,
          closed_at,
          updated_at,
          author_login,
          title,
          html_url
        from
          github_pull_activity($1, $2)
      EOQ
    }

  }

}