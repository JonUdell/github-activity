dashboard "Repos" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = <<EOT
[ActivityForPerson](${local.host}/github_activity.dashboard.ActivityForPerson)
🞄
[ExternalPeople](${local.host}/github_activity.dashboard.ExternalPeople)
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

      node {
        category = category.repo
        args = [ self.input.repos, self.input.updated ]
        base = node.org_repo
      }

      node {
        category = category.closed_pull_request
        args = [ self.input.repos, self.input.updated ]
        base = node.closed_pull_requests_for_repo
      }

      node {
        category = category.open_pull_request
        args = [ self.input.repos, self.input.updated ]
        base = node.open_pull_requests_for_repo
      }

      node {
        category = category.person_org
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