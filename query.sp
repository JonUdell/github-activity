query "usernames" {
  sql   = <<EOT
    with user_info as (
      select
        jsonb_array_elements_text(member_logins) as member_login
      from
        github_organization
      where
        login = '${local.default_org}'
    )
    select
      '${local.default_user}' as label,
      '${local.default_user}' as value
    union all
    select
      member_login as label,
      member_login as value
    from
      user_info
  EOT
}
