node "people_not_org_members" {
  sql = <<EOQ
    with data as (
      select distinct
        author_login
      from
        public.github_pull_activity('org:turbot', $1)
    )
    select
      author_login as id,
      author_login as title,
      'person_external' as category,
      jsonb_build_object(
        'login', author_login
      ) as properties
    from
      data
    where
      not author_login in ( select member_login from github_org_members() )
      and author_login !~ 'dependabot'
      and not author_login in ( select excluded_member_login from github_org_excluded_members() )
  EOQ
}

node "org_repos" {
  sql = <<EOQ
    with data as (
      select distinct
        repository_full_name
      from
        public.github_pull_activity('org:turbot', $1)
    )
    select
      repository_full_name as id,
      repository_full_name as title,
      'repo' as category,
      jsonb_build_object(
        'repository_full_name', repository_full_name
      ) as properties
    from
      data
  EOQ
}



