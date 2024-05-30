dashboard "Community_Pull_Requests" {

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
        "[Community_Pull_Requests](${local.host}/github_activity.dashboard.Community_Pull_Requests)",
        "Community_Pull_Requests"
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
            github_pull_activity_all
          where
            author_login not in (select * from github_org_members() )
            and not author_login ~ 'dependabot'
            and closed_at is null
          )
        select
          count(*) as "open community prs"
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
            github_pull_activity_all
          where
            author_login not in (select * from github_org_members() )
            and not author_login ~ 'dependabot'
            and closed_at is not null
          )
        select
          count(*) as "closed community prs"
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
      title = "community contributors"

      node {
        category = category.person_community
        base = node.pr_people_not_org_members
      }

      node {
        category = category.repo
        base = node.pr_repos
      }

      node {
        category = category.open_pull_request_community
        base = node.open_community_pull_requests
      }

      node {
        category = category.closed_pull_request_community
        base = node.closed_community_pull_requests
      }

      edge {
        base = edge.person_open_pr
      }

      edge {
        base = edge.person_closed_pr
      }

      edge {
        base = edge.pr_repo
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
          html_url
        from
          github_pull_activity_all
        where
          author_login not in (select * from github_org_members() )
          and not author_login ~ 'dependabot'
        order by 
          closed_at desc nulls last
      EOQ
    }


  }

}