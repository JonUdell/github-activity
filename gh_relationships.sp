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

  with "github_pull_activity" {
    sql = <<EOQ
        create or replace function public.github_pull_activity(repo text, updated text) 
        returns table (
            number int,
            title text,
            author_login text,
            created_at timestamptz,
            updated_at timestamptz,
            closed_at timestamptz,
            merged_by_login text,
            comments bigint,
            html_url text
        ) as $$
        select
            s.number,
            p.title,
            p.author_login,
            p.created_at,
            p.updated_at,
            p.closed_at,
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
            s.query = 'repo:turbot/steampipe-docs updated:>' || updated
        $$ language sql
    EOQ
  }

  with "github_pull_author" {
    sql = <<EOQ
      create or replace function public.github_pull_author(repo text, updated text)
      returns table (
          repo text,
          created_at timestamptz,
          issue_number bigint,
          author_login text
      ) as $$
      select
          repository_full_name,
          created_at,
          issue_number,
          author_login
      from
          github_pull_request
      where
          repository_full_name = repo
          and to_char(updated_at, 'YYYY-MM-DD') > updated
      $$ language sql;
    EOQ
  }

  with "github_pull_merger" {
    sql = <<EOQ
      create or replace function public.github_pull_merger(repo text, updated text)
        returns table (
          repo text,
          created_at timestamptz,
          issue_number bigint,
          merged_by_login text
        ) as $$
        select
          repository_full_name,
          created_at,
          issue_number,
          merged_by_login
        from
          github_pull_request
        where
          repository_full_name = repo
          and to_char(updated_at, 'YYYY-MM-DD') > updated
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