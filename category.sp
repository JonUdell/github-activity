category "repo" {
  color = "blue"
  icon = "server"
}

category "person_external" {
  color = "orange"
  icon = "person"
  href = "${local.host}/github.dashboard.ActivityForPerson?input.repo_pattern=turbot&input.issue_or_pull=both&input.open_or_closed=both&input.text_match=none&input.username={{.properties.'login'}}&input.updated=2021-01-01"
}

category "person_org" {
  color = "darkred"
  icon = "person"
  href = "${local.host}/github.dashboard.ActivityForPerson?input.repo_pattern=turbot&input.issue_or_pull=both&input.open_or_closed=both&input.text_match=none&input.username={{.properties.'login'}}&input.updated=2021-01-01"
}

category "closed_pull_request" {
  color = "green"
  icon = "question-mark-circle"
  href = "https://github.com/{{.properties.'repository_full_name'}}/pull/{{.properties.'number'}}"
}

category "open_pull_request" {
  color = "red"
  icon = "question-mark-circle"
  href = "https://github.com/{{.properties.'repository_full_name'}}/pull/{{.properties.'number'}}"
}