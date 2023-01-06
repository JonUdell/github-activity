dashboard "ActivityForPerson" {

  title = "All GitHub activity related to a person."

  tags = {
    service = "GitHub Activity"
  }
 
  input "username" {
    title = "username"
    width = 2
    query = query.usernames
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

  input "repo_pattern" {
    type = "combo"
    title = "repo pattern"
    width = 2
    option "turbot" {}
    option "steampipe-mod" {}
    option "steampipe-plugin" {}
    option "steampipe-docs" {}
  }

  input "issue_or_pull" {
    title = "issue/pull"
    width = 2
    option "issue" {}
    option "pull" {}
    option "both" {}
  }

  input "open_or_closed" {
    title = "open/closed"
    width = 2
    option "open" {}
    option "closed" {}
    option "both" {}
  }

  input "updated" {
    base = input.global_updated
  }

  input "text_match" {
    type = "combo"
    title = "match text"
    width = 2
    option "none" {}
  }

  container {

    table {
      base = table.activity
      width = 12
      args = [
        self.input.username.value,
        self.input.repo_pattern.value,
        self.input.issue_or_pull.value,
        self.input.open_or_closed.value,
        self.input.updated,
        self.input.text_match.value
      ]
      column "html_url"{
        wrap = "all"
      }
      column "title" {
        wrap = "all"
      }
    }

  }


}

query "usernames" {
  sql   = <<EOT
    with user_info as (
      select 
        jsonb_array_elements_text(member_logins) as member_login
      from
        github_organization
      where 
        login = '${local.default_org.name}'
    )
    select
      '${local.default_user.name}' as label,
      '${local.default_user.name}' as value
    union all
    select
      member_login as label, 
      member_login as value
    from 
      user_info
  EOT  
}

table "activity" {
  sql = <<EOT
    select
        html_url,
        title,
        to_char(updated_at, 'YYYY-MM-DD') as updated_at,
        to_char(created_at, 'YYYY-MM-DD') as created_at,
        to_char(closed_at, 'YYYY-MM-DD') as closed_at
    from
        github_activity(
          $1,
          $2,
          $5,
          case 
            when $6 = 'none' then ''
            else $6
          end
        )
    where
        html_url ~ 
          case 
            when $3 = 'issue' then 'issue'
            when $3 = 'pull' then 'pull'
            else 'issue|pull'
          end 
        and case 
          when $4 = 'open' then closed_at is null
          when $4 = 'closed' then closed_at is not null
          else closed_at is null or closed_at is not null
        end
  EOT
}    
