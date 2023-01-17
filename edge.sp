edge "person_repo" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      repository_full_name as to_id,
      'pull' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login
      ) as properties
    from
      public.github_pull_activity('org:turbot', $1)
  EOQ
}

edge "pr_repo" {
  sql = <<EOQ
    select distinct
      number as from_id,
      repository_full_name as to_id,
      'pull' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'title', title
      ) as properties

    from
      public.github_pull_activity($1, $2)
  EOQ
}

edge "person_pr" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      number as to_id,
      'author' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'title', title
      ) as properties

    from
      public.github_pull_activity($1, $2)
  EOQ
}


