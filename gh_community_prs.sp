dashboard "CommunityPullRequests" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = <<EOT
[ActivityForPerson](${local.host}/github_activity.dashboard.ActivityForPerson)
🞄
CommunityPullRequests
🞄
[Repos](${local.host}/github_activity.dashboard.Repos)

EOT
    }
  }

  container {

    input "updated" {
      title = "pull requests updated since"
      width = 3
      base = input.global_updated
    }

  }

  container {

    card {
      width = 2
      args = [ "org:turbot", self.input.updated.value]
      sql = <<EOQ
        with data as (
          select
            *
          from
            github_pull_activity($1, $2)
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
      args = [ "org:turbot", self.input.updated.value]
      sql = <<EOQ
        with data as (
          select
            *
          from
            github_pull_activity($1, $2)
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


  }

  container {

    graph {
      title = "community contributors"

      node {
        category = category.person_external
        args = [ self.input.updated.value ]
        base = node.people_not_org_members
      }

      node {
        category = category.repo
        args = [ "org:turbot", self.input.updated.value ]
        base = node.org_repos
      }

      node {
        category = category.open_pull_request
        args = [ "org:turbot", self.input.updated.value ]
        base = node.open_external_pull_requests
      }

      node {
        category = category.closed_pull_request
        args = [ "org:turbot", self.input.updated.value ]
        base = node.closed_external_pull_requests
      }

      edge {
        args = [ "org:turbot", self.input.updated.value ]
        base = edge.person_open_pr
      }

      edge {
        args = [ "org:turbot", self.input.updated.value ]
        base = edge.person_closed_pr
      }

      edge {
        args = [ "org:turbot", self.input.updated.value ]
        base = edge.pr_repo
      }



    }

    table {
      args = [ "org:turbot", self.input.updated.value ]
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
          github_pull_activity($1, $2)
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