dashboard "Relationship" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = <<EOT
[ActivityForPerson](${local.host}/github.dashboard.ActivityForPerson)
🞄
Relationship
EOT
    }
  }

  container {
    
    input "updated" {
      title = "pull requests updated since"
      width = 3
      base = input.global_updated
    }

  }

  container {
    
    graph {
      title = "external contributors"

      category "person_external" {
        color = "orange"
        icon = "person"
        href  = "https://github.com/{{.properties.'login'}}"
      }

      category "repo" {
        color = "yellow"
        icon = "server"
      }

      /*

      node {
      // people: org members
        args = [ self.input.updated ]
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
            'person_org' as category
          from
            data
          where author_login in (
            select member_login from github_org_members()
          )

        EOQ
      }
      */

      node {
      // people: not org members
        args = [ self.input.updated ]
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


      node {
      // repos
        args = [ self.input.updated ]
        sql = <<EOQ
          with data as (
            select distinct
              repository_full_name as repo
            from 
              public.github_pull_activity('org:turbot', $1)
          )
          select
            repo as id,
            repo as title,
            'repo' as category,
            jsonb_build_object(
              'name', repo
            ) as properties

          from
            data

        EOQ
      }

      edge { //  person author repo
        args = [ self.input.updated ]
        sql = <<EOQ
          with data as (
            select distinct
              author_login as from_id,
              repository_full_name as to_id,
              'author' as title
            from
              public.github_pull_activity('org:turbot', $1)
          )
          select
            *
          from 
            data
        EOQ
      }

    }

  }

  container {

    input "repos" {
      width = 4
      base = input.global_repos
    }

    table {
      title = "github_pull_activity_repo"
      args = [ self.input.repos, self.input.updated ]
      sql = <<EOQ
        select 
          *
        from
          github_pull_activity($1, $2)
      EOQ
    }
  
    table {
      title = "github_pull_activity_org"
      args = [ "org:turbot", self.input.updated ]
      sql = <<EOQ
        select 
          *
        from
          github_pull_activity($1, $2) 
      EOQ
    }

    table {
      title = "github_pull_author_repo"
      args = [ self.input.repos, self.input.updated ]
      sql = <<EOQ
        select 
          *
        from
          github_pull_author_repo(replace($1,'repo:','')::text, $2)
      EOQ
    }

    table {
      title = "github_pull_merger_repo"
      args = [ self.input.repos, self.input.updated ]
      sql = <<EOQ
        select 
          *
        from
          github_pull_merger_repo(replace($1,'repo:','')::text, $2)
      EOQ
    }
  }

  with "github_pull_activity" {
    sql = <<EOQ
      create or replace function public.github_pull_activity(q text, updated text)
      returns table (
        query text,
        repository_full_name text,
        updated_at text,
        number int,
        title text,
        author_login text,
        created_at text,
        closed_at text,
        merged_by_login text,
        comments bigint,
        html_url text
      ) as $$
      select
        s.query,
        p.repository_full_name,
        to_char(s.updated_at, 'YYYY-MM-DD'),
        s.number,
        p.title,
        p.author_login,
        to_char(p.created_at, 'YYYY-MM-DD'),
        to_char(p.closed_at, 'YYYY-MM-DD'),
        p.merged_by_login,
        p.comments,
        p.html_url
      from
        github.github_search_pull_request s
      join
        github.github_pull_request p
      on
        s.number = p.issue_number
        and s.repository_full_name = p.repository_full_name
      where
        s.query = q || ' updated:>' || updated
      order by
        p.updated_at desc
      $$ language sql;
     EOQ
  }

  with "github_pull_author_repo" {
    sql = <<EOQ
      create or replace function public.github_pull_author_repo(repo text, updated text)
      returns table (
        number bigint,
        author_login text,
        created_at text
      ) as $$
      select
        issue_number,
        author_login,
        to_char(created_at, 'YYYY-MM-DD')
      from
        github_pull_request
      where
        repository_full_name = repo
        and to_char(updated_at, 'YYYY-MM-DD') > updated
        order by issue_number      
      $$ language sql;
    EOQ
  }

  with "github_pull_merger_repo" {
    sql = <<EOQ
      create or replace function public.github_pull_merger_repo(repo text, updated text)
        returns table (
          number bigint,
          merged_by_login text,
          created_at text
        ) as $$
        select
          issue_number,
          merged_by_login,
          to_char(created_at, 'YYYY-MM-DD')
        from
          github_pull_request
        where
          repository_full_name = repo
          and to_char(updated_at, 'YYYY-MM-DD') > updated
          order by issue_number
      $$ language sql;
    EOQ
  }

  with "github_org_members" {
    sql = <<EOQ
      create or replace function public.github_org_members() returns table (
        member_login text
      ) as $$
      select
        jsonb_array_elements_text(member_logins) as member_login
      from
        github_organization
      where
        login = 'turbot'
      $$ language sql;
    EOQ
  }

  with "github_excluded_org_members" {
    sql = <<EOQ
      create or replace function public.github_org_excluded_members() returns table (
        excluded_member_login text
      ) as $$
      select
        unnest ( array [
          'LalitLab',
          'Priyanka585464',
          'c0d3r-arnab',
          'Paulami30',
          'RupeshPatil20',
          'akumar-99',
          'anisadas',
          'debabrat-git',
          'krishna5891',
          'rajeshbal65',
          'sayan133',
          'shivani1982',
          'subham9418',
          'visiit'          
        ] ) as excluded_org_member
      $$ language sql;
    EOQ
  }

 
} 