create or replace function public.github_org_excluded_members2() returns table (
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
    'visiit',
    'binaek'
  ] ) as excluded_org_member
$$ language sql;  

create or replace function public.github_org_members() returns table (
  member_login text
) as $$
select
  login
from
  github_jon.github_organization_member
where
  organization = 'turbot'
  and not login in ( select excluded_member_login from github_org_excluded_members2() )
$$ language sql;

create or replace function public.github_activity(match_user text, match_repo text, updated text, match_body text)
  returns table (
    type text,
    html_url text,
    title text,
    updated_at timestamptz,
    created_at timestamptz,
    closed_at timestamptz,
    comments bigint,
    body text
  ) as $$
  with my_created_issues as (
    select
      'issue_author',
      i.url,
      i.title,
      i.updated_at,
      i.created_at,
      i.closed_at,
      i.comments_total_count as comments,
      i.body
    from
      github_jon.github_search_issue i
    where
      i.query = 'updated:>=' || updated || ' is:issue author:' || match_user
      and i.url ~ match_repo
  ),

  my_assigned_issues as (
    select
      'issue_assignee',
      i.url,
      i.title,
      i.updated_at,
      i.created_at,
      i.closed_at,
      i.comments_total_count as comments,
      i.body
    from
      github_jon.github_search_issue i
    where
      i.query = 'updated:>=' || updated || ' is:issue assignee:' || match_user
      and i.url ~ match_repo
  ),

  my_mentioned_issues as (
    select
      'issue_mention',
      i.url,
      i.title,
      i.updated_at,
      i.created_at,
      i.closed_at,
      i.comments_total_count as comments,
      i.body
    from
      github_jon.github_search_issue i
    where
      i.query = 'updated:>=' || updated || ' is:issue mentions:' || match_user
      and i.url ~ match_repo
  ),

  my_created_pulls as (
    select
      'pr_author',
      p.url,
      p.title,
      p.updated_at,
      p.created_at,
      p.closed_at,
      p.total_comments_count as comments,
      p.body
    from
      github_jon.github_search_pull_request p
    where
      p.query = 'updated:>=' || updated || ' is:pr author:' || match_user
      and p.url ~ match_repo
  ),

  my_assigned_pulls as (
    select
      'pr_assignee',
      p.url,
      p.title,
      p.updated_at,
      p.created_at,
      p.closed_at,
      p.total_comments_count as comments,
      p.body
    from
      github_jon.github_search_pull_request p
    where
      p.query = 'updated:>=' || updated || ' is:pr assignee:' || match_user
      and p.url ~ match_repo
  ),

  my_mentioned_pulls as (
    select
      'pr_mention',
      p.url,
      p.title,
      p.updated_at,
      p.created_at,
      p.closed_at,
      p.total_comments_count as comments,
      p.body
    from
      github_jon.github_search_pull_request p
    where
      p.query = 'updated:>=' || updated || ' is:pr mentions:' || match_user
      and p.url ~ match_repo
  ),

  combined as (
    select * from my_created_issues
    union
    select * from my_assigned_issues
    union
    select * from my_mentioned_issues
    union
    select * from my_created_pulls
    union
    select * from my_assigned_pulls
    union
    select * from my_mentioned_pulls
  ),

  filtered as (
    select distinct
      *
    from
      combined c
    where
      ( c.body is not null and c.body ~* match_body )
      or
      ( c.body is null and match_body = '')
  )
  select
    *
  from
    filtered f
  order by
    f.updated_at desc;
$$ language sql;

create or replace function public.github_issue_activity(org text, updated text)
returns table (
  query text,
  repository_full_name text,
  updated_at text,
  number int,
  issue text,
  title text,
  author_login text,
  created_at text,
  closed_at text,
  comments bigint,
  url text    
) as $$
select
  s.query,
  i.repository_full_name,
  to_char(i.updated_at, 'YYYY-MM-DD'),
  i.number,
  i.repository_full_name || '_' || i.number,        
  i.title,
  i.author->>'login',
  to_char(i.created_at, 'YYYY-MM-DD'),
  to_char(i.closed_at, 'YYYY-MM-DD'),
  i.comments_total_count,
  i.url
from 
  github_search_issue s
join 
  github_issue i
on 
  s.number = i.number
  and s.repository_full_name = i.repository_full_name
where 
  s.query = 'org:' || org || ' updated:>' || '2024-03-30'
$$ language sql;

create or replace function public.github_pull_activity(q text, updated text)
  returns table (
    query text,
    repository_full_name text,
    updated_at text,
    number int,
    pr text,
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
    s.repository_full_name || '_' || s.number as pr,
    p.title,
    p.author->>'login',
    to_char(p.created_at, 'YYYY-MM-DD'),
    to_char(p.closed_at, 'YYYY-MM-DD'),
    p.merged_by->>'login',
    p.total_comments_count,
    p.url
  from
    github_jon.github_search_pull_request s
  join
    github_jon.github_pull_request p
  on
    s.number = p.number
    and s.repository_full_name = p.repository_full_name
  where
    s.query = q || ' updated:>' || updated
    and p.author->>'login' !~* 'dependabot'
  order by
    p.updated_at desc
$$ language sql;