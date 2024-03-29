dashboard "Turbot_GitHub_Activity_By_Person" {

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
        "[Turbot_GitHub_Activity_By_Person](${local.host}/github_activity.dashboard.Turbot_GitHub_Activity_By_Person)",
        "Turbot_GitHub_Activity_By_Person"
      )
    }
  }  

  input "username" {
    title = "username"
    type = "combo"
    width = 2
    query = query.usernames
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
        self.input.updated.value,
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

  with "github_activity" {
    sql = <<EOQ
    create or replace function public.github_activity(match_user text, match_repo text, updated text, match_body text)
      returns table (
        type text,
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
          'issue_author',
          i.url,
          i.title,
          i.updated_at,
          i.created_at,
          i.closed_at,
          i.comments_total_count as comments,
          i.body
        from
          github_jon.github_search_issue i
        where
          i.query = 'updated:>=' || updated || ' is:issue author:' || match_user
          and i.url ~ match_repo
      ),

      my_assigned_issues as (
        select
          'issue_assignee',
          i.url,
          i.title,
          i.updated_at,
          i.created_at,
          i.closed_at,
          i.comments_total_count as comments,
          i.body
        from
          github_jon.github_search_issue i
        where
          i.query = 'updated:>=' || updated || ' is:issue assignee:' || match_user
          and i.url ~ match_repo
      ),

      my_mentioned_issues as (
        select
          'issue_mention',
          i.url,
          i.title,
          i.updated_at,
          i.created_at,
          i.closed_at,
          i.comments_total_count as comments,
          i.body
        from
          github_jon.github_search_issue i
        where
          i.query = 'updated:>=' || updated || ' is:issue mentions:' || match_user
          and i.url ~ match_repo
      ),

      my_created_pulls as (
        select
          'pr_author',
          p.url,
          p.title,
          p.updated_at,
          p.created_at,
          p.closed_at,
          p.total_comments_count as comments,
          p.body
        from
          github_jon.github_search_pull_request p
        where
          p.query = 'updated:>=' || updated || ' is:pr author:' || match_user
          and p.url ~ match_repo
      ),

      my_assigned_pulls as (
        select
          'pr_assignee',
          p.url,
          p.title,
          p.updated_at,
          p.created_at,
          p.closed_at,
          p.total_comments_count as comments,
          p.body
        from
          github_jon.github_search_pull_request p
        where
          p.query = 'updated:>=' || updated || ' is:pr assignee:' || match_user
          and p.url ~ match_repo
      ),

      my_mentioned_pulls as (
        select
          'pr_mention',
          p.url,
          p.title,
          p.updated_at,
          p.created_at,
          p.closed_at,
          p.total_comments_count as comments,
          p.body
        from
          github_jon.github_search_pull_request p
        where
          p.query = 'updated:>=' || updated || ' is:pr mentions:' || match_user
          and p.url ~ match_repo
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

table "activity" {
  sql = <<EOT
    select
        array_to_string(array_agg(type order by type), ', ') as type,
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
    group by
      html_url, title, updated_at, created_at, closed_at
  EOT
}

