# Notes

datatank query for stats.github_issue_activity_all

```
select
  *
from
  github_issue_activity ('turbot',to_char( now() - interval '2 week', 'YYYY-MM-DD'))
```

datatank query for stats.github_issue_activity_all

```
select
  *
from
  github_pull_activity ('org:turbot',to_char( now() - interval '2 week', 'YYYY-MM-DD'))
```

