dashboard "Turbot_Issues_By_Person" {

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
        "[Turbot_Issues_By_Person](${local.host}/github_activity.dashboard.Turbot_Issues_By_Person)",
        "Turbot_Issues_By_Person"
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
      title = "Turbot issues"

      node {
        category = category.repo
        base = node.org_repos
      }

      node {
        args = [self.input.turbot_logins.value]
        category = category.person_org
        base = node.people_org_members_filtered
      }      

      node {
        args = [self.input.turbot_logins.value]
        category = category.closed_issue
        base = node.closed_internal_issues_filtered
      }

      node {
        args = [self.input.turbot_logins.value]
        category = category.open_issue
        base = node.open_internal_issues_filtered
      }

      edge {
        args = [self.input.turbot_logins.value]
        base = edge.person_org_open_pr_filtered
      }

      edge {
        base = edge.person_org_closed_pr
      }

      edge {
        base = edge.issue_repo
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
          author_login in (select * from github_org_members() )
          and not author_login ~ 'dependabot'
          and author_login = $1
        order by 
          closed_at desc nulls last
      EOQ
    }


  }


}