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
      replace(repository_full_name, 'turbot/steampipe-', '') as title,
      'repo' as category,
      jsonb_build_object(
        'repository_full_name', repository_full_name
      ) as properties
    from
      data
  EOQ
}

node "org_repo" {
  sql = <<EOQ
    with data as (
      select distinct
        repository_full_name
      from
        public.github_pull_activity($1, $2)
    )
    select
      repository_full_name as id,
      replace(repository_full_name, 'turbot/steampipe-', '') as title,
      'repo' as category,
      jsonb_build_object(
        'repository_full_name', repository_full_name
      ) as properties
    from
      data
  EOQ
}


node "closed_pull_requests_for_repo" {
  sql = <<EOQ
    with data as (
      select distinct
        number,
        title,
        closed_at,
        repository_full_name,
        author_login as author
      from
        public.github_pull_activity($1, $2)
    )
    select
      number as id,
      number as title,
      'closed-pull-request' as category,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author,
        'number', number,
        'closed_at', closed_at,
        'title', title
      ) as properties
    from
      data
    where closed_at is not null
  EOQ
}

node "open_pull_requests_for_repo" {
  sql = <<EOQ
    with data as (
      select distinct
        number,
        title,
        closed_at,
        repository_full_name,
        author_login as author
      from
        public.github_pull_activity($1, $2)
    )
    select
      number as id,
      number as title,
      'open-pull-request' as category,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author,
        'pr number', number,
        'closed_at', closed_at,
        'title', title
      ) as properties
    from
      data
    where closed_at is null
  EOQ
}



