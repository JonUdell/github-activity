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
