category "repo" {
  color = "blue"
  icon = "server"
  href = "https://github.com/{{.properties.'repository_full_name'}}"
}

category "person_external" {
  color = "orange"
  icon = "person"
  href = "https://github.com/{{.properties.'login'}}"
}

category "person_org" {
  color = "darkred"
  icon = "person"
  href = "${local.host}/github.dashboard.ActivityForPerson?input.repo_pattern=turbot&input.issue_or_pull=both&input.open_or_closed=both&input.text_match=none&input.username={{.properties.'login'}}&input.updated=2021-01-01"
}

category "pull_request" {
  icon = "question-mark-circle"
  href = "{{.properties.'html_url'}}"
}

category "closed_pull_request" {
  color = "green"
  icon = "question-mark-circle"
  href = "{{.properties.'html_url'}}"
}

category "open_pull_request" {
  color = "red"
  icon = "question-mark-circle"
  href = "{{.properties.'html_url'}}"
}