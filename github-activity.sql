create or replace function github_activity(match_user text, match_repo text, updated text, match_body text) 
  returns table (
    html_url text,
    title text,
    updated_at timestamptz,
    created_at timestamptz,
    closed_at timestamptz,
    comments bigint,
    body text
  ) as $$
  begin 
    return query
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
    end;
$$ language plpgsql;
