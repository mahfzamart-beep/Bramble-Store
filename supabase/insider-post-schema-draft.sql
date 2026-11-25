-- Insider Post CMS schema proposal (Supabase/Postgres)
-- Review and apply only after selecting/activating the target project.
-- This file is a draft. It has not been run against any database.

create extension if not exists pgcrypto;

create table if not exists public.editor_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'reporter' check (role in ('reporter','editor','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.news_articles (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  headline_bn text not null,
  headline_en text,
  excerpt_bn text,
  excerpt_en text,
  body_bn text,
  body_en text,
  category text not null check (category in ('Bangladesh','Politics','World','Business','Technology','Sports','Entertainment','Opinion')),
  author_id uuid references public.editor_profiles(user_id),
  cover_image_path text,
  cover_image_credit text,
  status text not null default 'draft' check (status in ('draft','review','published','archived')),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.article_sources (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references public.news_articles(id) on delete cascade,
  source_url text not null,
  source_note text,
  created_at timestamptz not null default now()
);

create table if not exists public.article_tags (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references public.news_articles(id) on delete cascade,
  tag text not null
);

create index if not exists news_articles_status_published_idx
  on public.news_articles(status, published_at desc);
create index if not exists news_articles_category_idx
  on public.news_articles(category, published_at desc);
create index if not exists article_sources_article_idx
  on public.article_sources(article_id);

alter table public.editor_profiles enable row level security;
alter table public.news_articles enable row level security;
alter table public.article_sources enable row level security;
alter table public.article_tags enable row level security;

-- SECURITY DEFINER helper avoids recursive profile RLS lookups.
create or replace function public.current_editor_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.editor_profiles where user_id = auth.uid()
$$;

revoke all on function public.current_editor_role() from public;
grant execute on function public.current_editor_role() to authenticated;

-- Public visitors may only read published articles.
drop policy if exists "published articles public read" on public.news_articles;
create policy "published articles public read" on public.news_articles
for select to anon, authenticated
using (status = 'published');

-- Editors/reporters/admins may read newsroom drafts and update articles.
drop policy if exists "newsroom read all" on public.news_articles;
create policy "newsroom read all" on public.news_articles
for select to authenticated
using (public.current_editor_role() in ('reporter','editor','admin'));

drop policy if exists "newsroom create" on public.news_articles;
create policy "newsroom create" on public.news_articles
for insert to authenticated
with check (
  public.current_editor_role() in ('editor','admin')
  or (public.current_editor_role() = 'reporter' and status in ('draft','review'))
);

drop policy if exists "newsroom update" on public.news_articles;
create policy "newsroom update" on public.news_articles
for update to authenticated
using (public.current_editor_role() in ('reporter','editor','admin'))
with check (
  public.current_editor_role() in ('editor','admin')
  or (public.current_editor_role() = 'reporter' and status in ('draft','review'))
);

drop policy if exists "newsroom delete" on public.news_articles;
create policy "newsroom delete" on public.news_articles
for delete to authenticated
using (public.current_editor_role() in ('editor','admin'));

-- Source URLs are newsroom-only by default. Public article rendering may expose
-- selected sources later through a server-side/public-view query.
drop policy if exists "newsroom sources access" on public.article_sources;
create policy "newsroom sources access" on public.article_sources
for all to authenticated
using (public.current_editor_role() in ('reporter','editor','admin'))
with check (public.current_editor_role() in ('reporter','editor','admin'));

drop policy if exists "newsroom tags access" on public.article_tags;
create policy "newsroom tags access" on public.article_tags
for all to authenticated
using (public.current_editor_role() in ('reporter','editor','admin'))
with check (public.current_editor_role() in ('reporter','editor','admin'));

-- Role assignment is restricted to service/admin operations; no self-role updates.
drop policy if exists "profile self read" on public.editor_profiles;
create policy "profile self read" on public.editor_profiles
for select to authenticated using (user_id = auth.uid());

drop policy if exists "admins manage editor profiles" on public.editor_profiles;
create policy "admins manage editor profiles" on public.editor_profiles
for all to authenticated
using (public.current_editor_role() = 'admin')
with check (public.current_editor_role() = 'admin');

-- IMPORTANT: Storage bucket and its object policies should be created separately
-- after choosing image-storage strategy and admin-role provisioning method.
