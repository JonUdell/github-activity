dashboard "ExternalPeople" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = <<EOT
[ActivityForPerson](${local.host}/github.dashboard.ActivityForPerson)
🞄
ExternalPeople
🞄
[Repos](${local.host}/github.dashboard.Repos)

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
        href = "${local.host}/github.dashboard.ActivityForPerson?input.repo_pattern=turbot&input.issue_or_pull=both&input.open_or_closed=both&input.text_match=none&input.username={{.properties.'login'}}&input.updated=2021-01-01"
      }

      category "repo" {
        color = "yellow"
        icon = "server"
      }

      node {
        args = [ self.input.updated ]
        base = node.people_not_org_members
      }

      node {
        args = [ self.input.updated ]
        base = node.org_repos
      }

      edge {
        args = [ self.input.updated ]
        base = edge.person_repo
      }

    }

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

}