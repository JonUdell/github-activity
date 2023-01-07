dashboard "Repos" {

  tags = {
    service = "GitHub Activity"
  }

  container {
    text {
      value = <<EOT
[ActivityForPerson](${local.host}/github.dashboard.ActivityForPerson)
🞄
[ExternalPeople](${local.host}/github.dashboard.ExternalPeople)
🞄
Repos

EOT
    }
  }

  container {

    input "repos" {
      width = 4
      base = input.global_repos
    }

    input "updated" {
      title = "pull requests updated since"
      width = 3
      base = input.global_updated
    }

  }

  container {

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


  }

}