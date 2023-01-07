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
      member_login as label,
      member_login as value
    from
      user_info
  EOT
}
