input "turbot_logins" {
  width = 4
  sql = <<EOQ
    select
      member_login as label,
      member_login as value
    from
      github_org_members()
    order by
      lower(member_login)
  EOQ
}

input "global_updated" {
  width = 2
  title = "updated since"
  sql = <<EOQ
    with days(interval, day) as (
    values
      ( '1 week', to_char(now() - interval '1 week', 'YYYY-MM-DD') ),
      ( '2 weeks', to_char(now() - interval '2 week', 'YYYY-MM-DD') ),
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
