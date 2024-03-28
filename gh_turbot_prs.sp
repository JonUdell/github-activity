dashboard "TurbotPullRequests" {

  tags = {
    service = "GitHub Activity"
  }

  container {

    graph {
      title = "Turbot contributors"

      node {
        category = category.repo
        base = node.org_repos_datatank
      }

      node {
        category = category.person_org
        base = node.people_org_members
      }      

      node {
        category = category.closed_pull_request
        base = node.closed_internal_pull_requests_datatank
      }

      node {
        category = category.open_pull_request
        base = node.open_internal_pull_requests_datatank
      }

      edge {
        base = edge.person_org_open_pr
      }

      edge {
        base = edge.person_org_closed_pr
      }

      edge {
        base = edge.pr_repo_datatank
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
          author_login in (select * from github_org_members() )
          and not author_login ~ 'dependabot'
        order by 
          closed_at desc nulls last
      EOQ
    }


  }


}