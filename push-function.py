"""
install the mod's supporting function, `github_activity`
"""

import json, os, requests

def push(sql, org, workspace):
  url = f'https://cloud.steampipe.io/api/latest/org/{org}/workspace/{workspace}/query'
  data = {'sql':sql}
  token = os.environ['STEAMPIPE_CLOUD_TOKEN']
  headers = {"Authorization": "Bearer " + token}
  print(url)
  r = requests.post(url, headers=headers, data=data)
  print(r.text)

with open('github-activity.sql', 'r') as f:
  sql = f.read()
  push(sql, 'acme', 'jon')


