dashboard "Community_Issues" {

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
        "[Community_Issues](${local.host}/github_activity.dashboard.Community_Issues)",
        "Community_Issues"
      )
    }
  }  

  container {

    card {
      width = 2
      sql = <<EOQ
        with data as (
          select
            *
          from
            github_issue_activity_all
          where
            author_login not in (select * from github_org_members() )
            and closed_at is null
          )
        select
          count(*) as "open community issues"
        from
          data
      EOQ
    }

    card {
      width = 2
      sql = <<EOQ
        with data as (
          select
            *
          from
            github_issue_activity_all
          where
            author_login not in (select * from github_org_members() )
            and closed_at is not null
          )
        select
          count(*) as "closed community issues"
        from
          data
      EOQ
    }

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
      title = "community issues"

      node {
        category = category.person_community
        base = node.issue_people_not_org_members
      }

      node {
        category = category.repo
        base = node.issue_repos
      }

      node {
        category = category.open_issue
        base = node.open_community_issues
      }

      node {
        category = category.closed_issue
        base = node.closed_community_issues
      }

      edge {
        base = edge.person_open_issue
      }

      edge {
        base = edge.person_closed_issue
      }

      edge {
        base = edge.issue_repo
      }

    }

    table {
      sql = <<EOQ
        select
          author_login,
          repository_full_name,
          created_at,
          updated_at,
          closed_at,
          title,
          url
        from
          github_issue_activity_all
        where
          author_login not in (select * from github_org_members() )
        order by 
          closed_at desc nulls last
      EOQ
    }


  }

}