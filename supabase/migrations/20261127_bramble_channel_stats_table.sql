-- Replace exposed aggregate SECURITY DEFINER RPC with a read-only aggregate table.
-- Public viewers can see subscriber totals, never subscriber user IDs.

create table if not exists public.bramble_channel_stats (
  channel_id uuid primary key references public.creator_channels(id) on delete cascade,
  subscriber_count bigint not null default 0 check (subscriber_count >= 0),
  updated_at timestamptz not null default now()
);

alter table public.bramble_channel_stats enable row level security;
revoke all on public.bramble_channel_stats from public, anon, authenticated;
grant select on public.bramble_channel_stats to anon, authenticated;
drop policy if exists "public read bramble channel stats" on public.bramble_channel_stats;
create policy "public read bramble channel stats"
on public.bramble_channel_stats
for select to anon, authenticated
using (true);

insert into public.bramble_channel_stats(channel_id,subscriber_count)
select c.id,count(s.subscriber_id)::bigint
from public.creator_channels c
left join public.bramble_channel_subscriptions s on s.channel_id=c.id
group by c.id
on conflict (channel_id) do update
set subscriber_count=excluded.subscriber_count,updated_at=now();

create or replace function public.initialize_bramble_channel_stats()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog
as $function$
begin
  insert into public.bramble_channel_stats(channel_id,subscriber_count)
  values(new.id,0)
  on conflict(channel_id) do nothing;
  return new;
end;
$function$;
revoke all on function public.initialize_bramble_channel_stats() from public, anon, authenticated;
drop trigger if exists bramble_channel_stats_init on public.creator_channels;
create trigger bramble_channel_stats_init
after insert on public.creator_channels
for each row execute function public.initialize_bramble_channel_stats();

create or replace function public.sync_bramble_channel_stats()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog
as $function$
begin
  if tg_op='INSERT' then
    insert into public.bramble_channel_stats(channel_id,subscriber_count,updated_at)
    values(new.channel_id,1,now())
    on conflict(channel_id) do update
      set subscriber_count=public.bramble_channel_stats.subscriber_count+1,
          updated_at=now();
    return new;
  elsif tg_op='DELETE' then
    update public.bramble_channel_stats
      set subscriber_count=greatest(0,subscriber_count-1),updated_at=now()
      where channel_id=old.channel_id;
    return old;
  end if;
  return null;
end;
$function$;
revoke all on function public.sync_bramble_channel_stats() from public, anon, authenticated;
drop trigger if exists bramble_channel_stats_sync on public.bramble_channel_subscriptions;
create trigger bramble_channel_stats_sync
after insert or delete on public.bramble_channel_subscriptions
for each row execute function public.sync_bramble_channel_stats();

drop function if exists public.bramble_get_subscriber_count(uuid);

