-- Insider Post CMS schema draft (review only; not executed against Supabase)
-- Newsroom bilingual fields, role-aware editorial states, and source attribution.

create extension if not exists pgcrypto;

create type public.article_status as enum ('draft','review','published','archived');
create type public.editorial_role as enum ('admin','editor','reporter');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  role public.editorial_role not null default 'reporter',
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name_bn text not null,
  name_en text not null,
  sort_order integer not null default 0
);

create table public.articles (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  title_bn text,
  title_en text,
  excerpt_bn text,
  excerpt_en text,
  body_bn text,
  body_en text,
  cover_image_path text,
  category_id uuid references public.categories(id),
  author_id uuid references public.profiles(id),
  status public.article_status not null default 'draft',
  published_at timestamptz,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  seo_title text,
  seo_description text,
  constraint at_least_one_language_title check (title_bn is not null or title_en is not null)
);

create table public.article_sources (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references public.articles(id) on delete cascade,
  source_name text not null,
  source_url text,
  notes text,
  added_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.article_revisions (
  id uuid primary key default gen_random_uuid(),
  article_id uuid not null references public.articles(id) on delete cascade,
  editor_id uuid references public.profiles(id),
  revision_note text,
  snapshot jsonb not null,
  created_at timestamptz not null default now()
);

-- RLS and granular policies must be added and tested before deployment.
-- Public users should only read published stories. Editors/Admins control review/publishing.
-- Never use the service-role key in browser-side code.
