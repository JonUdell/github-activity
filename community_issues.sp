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

  with "github_issue_activity" {
    sql = <<EOQ
    create or replace function public.github_issue_activity(org text, updated text)
      returns table (
        query text,
        repository_full_name text,
        updated_at text,
        number int,
        issue text,
        title text,
        author_login text,
        created_at text,
        closed_at text,
        comments bigint,
        url text    
      ) as $$
      select
        s.query,
        i.repository_full_name,
        to_char(i.updated_at, 'YYYY-MM-DD'),
        i.number,
        i.repository_full_name || '_' || i.number,        
        i.title,
        i.author->>'login',
        to_char(i.created_at, 'YYYY-MM-DD'),
        to_char(i.closed_at, 'YYYY-MM-DD'),
        i.comments_total_count,
        i.url
      from 
        github_search_issue s
      join 
        github_issue i
      on 
        s.number = i.number
        and s.repository_full_name = i.repository_full_name
      where 
        s.query = 'org:' || org || ' updated:>' || '2024-03-30'
    $$ language sql;
    EOQ
  }


 

}