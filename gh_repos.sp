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
        args = [ "org:turbot", self.input.updated.value ]
        base = node.org_repos
      }

      node {
        category = category.open_pull_request
        args = [ self.input.repos.value, self.input.updated.value ]
        base = node.open_internal_pull_requests
      }

      node {
        category = category.closed_pull_request
        args = [ self.input.repos.value, self.input.updated.value ]
        base = node.closed_internal_pull_requests
      }

      node {
        category = category.person_org
        base = node.people_org_members
      }

      edge {
        args = [ self.input.repos.value, self.input.updated.value ]
        base = edge.person_open_pr
      }

      edge {
        args = [ self.input.repos.value, self.input.updated.value ]
        base = edge.person_closed_pr
      }

      edge {
        args = [ self.input.repos.value, self.input.updated.value ]
        base = edge.pr_repo
      }


    }

  }

  container {

    table {
      title = "github_pull_activity_repo"
      args = [ self.input.repos.value, self.input.updated.value ]
      sql = <<EOQ
        select
          number,
          created_at,
          updated_at,
          closed_at,
          author_login,
          title,
          html_url
        from
          github_pull_activity($1, $2)
      EOQ
    }

  }

}