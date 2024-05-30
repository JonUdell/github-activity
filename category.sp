category "repo" {
  color = "blue"
  icon = "server"
  href = "https://github.com/{{.properties.'repository_full_name'}}"
}

category "person_community" {
  color = "brown"
  icon = "person"
  href = "https://github.com/{{.properties.'login'}}"
}

category "person_org" {
  color = "red"
  icon = "person"
  href = "https://github.com/{{.properties.'member_login'}}"
}

category "pull_request" {
  icon = "document"
  href = "{{.properties.'url'}}"
}

category "open_pull_request_community" {
  color = "red"
  icon = "document"
  href = "{{.properties.'html_url'}}"
}

category "closed_pull_request_community" {
  color = "green"
  icon = "document"
  href = "{{.properties.'html_url'}}"
}

category "open_issue_community" {
  color = "red"
  icon = "document"
  href = "{{.properties.'url'}}"
}

category "closed_issue_community" {
  color = "green"
  icon = "document"
  href = "{{.properties.'url'}}"
}

category "open_pull_request_org" {
  color = "red"
  icon = "document"
  href = "{{.properties.'html_url'}}"
}

category "closed_pull_request_org" {
  color = "green"
  icon = "document"
  href = "{{.properties.'html_url'}}"
}

category "open_issue_org" {
  color = "red"
  icon = "document"
  href = "{{.properties.'url'}}"
}

category "closed_issue_org" {
  color = "green"
  icon = "document"
  href = "{{.properties.'url'}}"
}



