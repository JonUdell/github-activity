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
        category = category.person_external
        base = node.people_not_org_members
      }

      node {
        category = category.repo
        base = node.org_repos
      }

      node {
        category = category.open_pull_request
        base = node.open_external_pull_requests
      }

      node {
        category = category.closed_pull_request
        base = node.closed_external_pull_requests
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

  with "github_org_members" {
    sql = <<EOQ
      create or replace function public.github_org_members() returns table (
        member_login text
      ) as $$
      select
        login
      from
        github_jon.github_organization_member
      where
        organization = 'turbot'
        and not login in ( select excluded_member_login from github_org_excluded_members() )
      $$ language sql;
    EOQ
  }

  with "github_excluded_org_members" {
    sql = <<EOQ
      create or replace function public.github_org_excluded_members() returns table (
        excluded_member_login text
      ) as $$
      select
        unnest ( array [
          'LalitLab',
          'Priyanka585464',
          'c0d3r-arnab',
          'Paulami30',
          'RupeshPatil20',
          'akumar-99',
          'anisadas',
          'debabrat-git',
          'krishna5891',
          'rajeshbal65',
          'sayan133',
          'shivani1982',
          'subham9418',
          'visiit'
        ] ) as excluded_org_member
      $$ language sql;
    EOQ
  }

  with "github_pull_activity" {
    sql = <<EOQ
      create or replace function public.github_pull_activity(q text, updated text)
        returns table (
          query text,
          repository_full_name text,
          updated_at text,
          number int,
          pr text,
          title text,
          author_login text,
          created_at text,
          closed_at text,
          merged_by_login text,
          comments bigint,
          html_url text
        ) as $$
        select
          s.query,
          p.repository_full_name,
          to_char(s.updated_at, 'YYYY-MM-DD'),
          s.number,
          s.repository_full_name || '_' || s.number as pr,
          p.title,
          p.author->>'login',
          to_char(p.created_at, 'YYYY-MM-DD'),
          to_char(p.closed_at, 'YYYY-MM-DD'),
          p.merged_by->>'login',
          p.total_comments_count,
          p.url
        from
          github_jon.github_search_pull_request s
        join
          github_jon.github_pull_request p
        on
          s.number = p.number
          and s.repository_full_name = p.repository_full_name
        where
          s.query = q || ' updated:>' || updated
          and p.author->>'login' !~* 'dependabot'
        order by
          p.updated_at desc
      $$ language sql;
     EOQ
  }


}