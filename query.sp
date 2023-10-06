query "usernames" {
  sql   = <<EOT
    with user_info as (
      select
        login
      from
        github_organization_member
      where
        organization = '${local.default_org}'
    )
    select
      login as label,
      login as value
    from
      user_info
  EOT
}
