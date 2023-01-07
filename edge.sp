edge "person_author_repo" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      repository_full_name as to_id,
      'author' as title
    from
      public.github_pull_activity('org:turbot', $1)
  EOQ
}
