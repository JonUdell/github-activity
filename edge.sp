edge "person_pr" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      number as to_id,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'title', title
      ) as properties
    from
      github_pull_activity_all
  EOQ
}

edge "person_open_pr" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      repository_full_name || '_' || number as to_id,
      'author' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'html_url', html_url,
        'closed_at', closed_at
      ) as properties
    from
      github_pull_activity_all
    where
      closed_at is null
    EOQ
}


edge "person_closed_pr" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      repository_full_name || '_' || number as to_id,
      'author' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'html_url', html_url,
        'closed_at', closed_at
      ) as properties
    from
      github_pull_activity_all
    where
      closed_at is not null
  EOQ
}

edge "person_org_open_pr" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      repository_full_name || '_' || number as to_id,
      'author' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'html_url', html_url,
        'closed_at', closed_at
      ) as properties
    from
      github_pull_activity_all
    where
      closed_at is null
    EOQ
}

edge "person_org_open_pr_filtered" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      repository_full_name || '_' || number as to_id,
      'author' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'html_url', html_url,
        'closed_at', closed_at
      ) as properties
    from
      github_pull_activity_all
    where
      closed_at is null
      and author_login = $1
    EOQ
}


edge "person_org_closed_pr" {
  sql = <<EOQ
    select distinct
      author_login as from_id,
      repository_full_name || '_' || number as to_id,
      'author' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'html_url', html_url,
        'closed_at', closed_at
      ) as properties
    from
      github_pull_activity_all
    where
      closed_at is not null
  EOQ
}

edge "pr_repo" {
  sql = <<EOQ
    select distinct
      repository_full_name || '_' || number as from_id,
      repository_full_name as to_id,
      'pull' as title,
      jsonb_build_object(
        'repository_full_name', repository_full_name,
        'author', author_login,
        'title', title
      ) as properties
    from
      github_pull_activity_all
  EOQ
}

