dashboard "Relationship" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = <<EOT
[ActivityForPerson](${local.host}/github.dashboard.ActivityForPerson)
🞄
Relationship
EOT
    }
  }

  container {
    input "repos" {
      width = 4
      base = input.global_repos
    }

    input "updated" {
      width = 2
      base = input.global_updated
    }

  }

  table {
    title = "github_pull_activity_repo"
    args = [ self.input.repos, self.input.updated ]
    sql = <<EOQ
      select 
        *
      from
        github_pull_activity($1, $2)
    EOQ
  }
 
  table {
    title = "github_pull_activity_org"
    args = [ "org:turbot", self.input.updated ]
    sql = <<EOQ
      select 
        *
      from
        github_pull_activity($1, $2) 
    EOQ
  }

  table {
    title = "github_pull_author_repo"
    args = [ self.input.repos, self.input.updated ]
    sql = <<EOQ
      select 
        *
      from
        github_pull_author_repo(replace($1,'repo:','')::text, $2)
    EOQ
  }

  table {
    title = "github_pull_merger_repo"
    args = [ self.input.repos, self.input.updated ]
    sql = <<EOQ
      select 
        *
      from
        github_pull_merger_repo(replace($1,'repo:','')::text, $2)
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
        p.title,
        p.author_login,
        to_char(p.created_at, 'YYYY-MM-DD'),
        to_char(p.closed_at, 'YYYY-MM-DD'),
        p.merged_by_login,
        p.comments,
        p.html_url
      from
        github.github_search_pull_request s
      join
        github.github_pull_request p
      on
        s.number = p.issue_number
        and s.repository_full_name = p.repository_full_name
      where
        s.query = q || ' updated:>' || updated
      order by
        p.updated_at desc
      $$ language sql;
     EOQ
  }

  with "github_pull_author_repo" {
    sql = <<EOQ
      create or replace function public.github_pull_author_repo(repo text, updated text)
      returns table (
        number bigint,
        author_login text,
        created_at text
      ) as $$
      select
        issue_number,
        author_login,
        to_char(created_at, 'YYYY-MM-DD')
      from
        github_pull_request
      where
        repository_full_name = repo
        and to_char(updated_at, 'YYYY-MM-DD') > updated
        order by issue_number      
      $$ language sql;
    EOQ
  }

  with "github_pull_merger_repo" {
    sql = <<EOQ
      create or replace function public.github_pull_merger_repo(repo text, updated text)
        returns table (
          number bigint,
          merged_by_login text,
          created_at text
        ) as $$
        select
          issue_number,
          merged_by_login,
          to_char(created_at, 'YYYY-MM-DD')
        from
          github_pull_request
        where
          repository_full_name = repo
          and to_char(updated_at, 'YYYY-MM-DD') > updated
          order by issue_number
      $$ language sql;
    EOQ
  }

  with "github_activity" {
    sql = <<EOQ
    create or replace function public.github_activity(match_user text, match_repo text, updated text, match_body text) 
    returns table (
        html_url text,
        title text,
        updated_at timestamptz,
        created_at timestamptz,
        closed_at timestamptz,
        comments bigint,
        body text
    ) as $$
    with my_created_issues as (
        select
        i.html_url,
        i.title,
        i.updated_at,
        i.created_at,
        i.closed_at,
        i.comments,
        i.body
        from
        github.github_search_issue i
        where
        i.query = 'updated:>=' || updated || ' is:issue author:' || match_user
        and i.html_url ~ match_repo
        ),

        my_assigned_issues as (
        select
            i.html_url,
            i.title,
            i.updated_at,
            i.created_at,
            i.closed_at,
            i.comments,
            i.body
        from
            github.github_search_issue i
        where
            i.query = 'updated:>=' || updated || ' is:issue assignee:' || match_user
            and i.html_url ~ match_repo
        ),

        my_mentioned_issues as (
        select
            i.html_url,
            i.title,
            i.updated_at,
            i.created_at,
            i.closed_at,
            i.comments,
            i.body
        from
            github.github_search_issue i
        where
            i.query = 'updated:>=' || updated || ' is:issue mentions:' || match_user
            and i.html_url ~ match_repo
        ),

        my_created_pulls as (
        select
            p.html_url,
            p.title,
            p.updated_at,
            p.created_at,
            p.closed_at,
            p.comments,
            p.body
        from
            github.github_search_pull_request p
        where
            p.query = 'updated:>=' || updated || ' is:pr author:' || match_user
            and p.html_url ~ match_repo
        ),

        my_assigned_pulls as (
        select
            p.html_url,
            p.title,
            p.updated_at,
            p.created_at,
            p.closed_at,
            p.comments,
            p.body
        from
            github.github_search_pull_request p
        where
            p.query = 'updated:>=' || updated || ' is:pr assignee:' || match_user
            and p.html_url ~ match_repo
        ),

        my_mentioned_pulls as (
        select
            p.html_url,
            p.title,
            p.updated_at,
            p.created_at,
            p.closed_at,
            p.comments,
            p.body
        from
            github.github_search_pull_request p
        where
            p.query = 'updated:>=' || updated || ' is:pr mentions:' || match_user
            and p.html_url ~ match_repo
        ),

        combined as (
        select * from my_created_issues
        union
        select * from my_assigned_issues
        union
        select * from my_mentioned_issues
        union
        select * from my_created_pulls
        union
        select * from my_assigned_pulls
        union
        select * from my_mentioned_pulls
        ),

        filtered as (
        select distinct
            *
        from
            combined c
        where 
            ( c.body is not null and c.body ~* match_body )
            or
            ( c.body is null and match_body = '')
        )

    select 
        *
    from
        filtered f
    order by
        f.updated_at desc;
    $$ language sql;
    EOQ
  }
 
}