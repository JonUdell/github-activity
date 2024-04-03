category "repo" {
  color = "blue"
  icon = "server"
  href = "https://github.com/{{.properties.'repository_full_name'}}"
}

category "person_community" {
  color = "orange"
  icon = "person"
  href = "https://github.com/{{.properties.'login'}}"
}

category "person_org" {
  color = "darkred"
  icon = "person"
  href = "https://github.com/{{.properties.'login'}}"
}

category "pull_request" {
  icon = "document"
  href = "{{.properties.'html_url'}}"
}

category "closed_pull_request" {
  color = "green"
  icon = "document"
  href = "{{.properties.'html_url'}}"
}

category "open_pull_request" {
  color = "red"
  icon = "document"
  href = "{{.properties.'html_url'}}"
}

category "closed_issue" {
  color = "green"
  icon = "document"
  href = "{{.properties.'url'}}"
}

category "open_issue" {
  color = "red"
  icon = "document"
  href = "{{.properties.'url'}}"
}