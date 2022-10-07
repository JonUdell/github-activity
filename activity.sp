dashboard "GitHub_Activity" {

  title = "GitHub Activity"

  tags = {
    service = "GitHub Activity"
  }
 
  input "username" {
    title = "username"
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
    width = 2
    title = "updated since"
    sql = <<EOQ
      with days(interval, day) as (
        values 
          ( '1 week', to_char(now() - interval '1 week', 'YYYY-MM-DD') ),
          ( '1 month', to_char(now() - interval '1 month', 'YYYY-MM-DD') ),
          ( '3 months', to_char(now() - interval '3 month', 'YYYY-MM-DD') ),
          ( '6 months', to_char(now() - interval '6 month', 'YYYY-MM-DD') ),
          ( '1 year', to_char(now() - interval '1 year', 'YYYY-MM-DD') ),
          ( '2 years', to_char(now() - interval '2 year', 'YYYY-MM-DD') )
      )
      select
        interval as label,
        day as value
      from 
        days
      order by 
        day desc
    EOQ    
  }

  input "text_match" {
    type = "combo"
    title = "match text"
    width = 2
    option "none" {}
  }

  container {

    table {
      width = 12
      args = [
        self.input.username.value,
        self.input.repo_pattern.value,
        self.input.issue_or_pull.value,
        self.input.open_or_closed.value,
        self.input.updated,
        self.input.text_match.value
      ]
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
      param "username" {}
      param "repo_pattern" {}
      param "issue_or_pull" {}
      param "open_or_closed" {}
      param "updated" {}
      param "text_match" {}
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
