dashboard "Turbot_Pull_Requests_By_Person" {

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
        "[Turbot_Pull_Requests_By_Person](${local.host}/github_activity.dashboard.Turbot_Pull_Requests_By_Person)",
        "Turbot_Pull_Requests_By_Person"
      )
    }
  }  

  input "turbot_logins" {
    base = input.turbot_logins
  }


  container {

    card {
      width = 2
      base = card.max_updated
    }

    card {
      width = 2
      base = card.min_updated
    }

  }

  container {

    graph {
      title = "Turbot PRs"

      node {
        category = category.repo
        base = node.pr_repos
      }

      node {
        args = [self.input.turbot_logins.value]
        category = category.person_org
        base = node.people_org_members_filtered
      }      

      node {
        args = [self.input.turbot_logins.value]
        category = category.closed_pull_request
        base = node.closed_internal_pull_requests_filtered
      }

      node {
        args = [self.input.turbot_logins.value]
        category = category.open_pull_request
        base = node.open_internal_pull_requests_filtered
      }

      edge {
        args = [self.input.turbot_logins.value]
        base = edge.person_org_open_pr_filtered
      }

      edge {
        args = [self.input.turbot_logins.value]
        base = edge.person_org_closed_pr_filtered
      }

      edge {
        base = edge.pr_repo
      }

    }

    table {
      args = [self.input.turbot_logins.value]
      sql = <<EOQ
        select
          author_login,
          repository_full_name,
          created_at,
          updated_at,
          closed_at,
          title,
          html_url
        from
          github_pull_activity_all
        where
          author_login = $1
        order by 
          closed_at desc nulls last
      EOQ
    }


  }


}