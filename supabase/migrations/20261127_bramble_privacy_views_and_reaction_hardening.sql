-- Bramble 2nd-pass hardening: privacy-safe subscriber counts and real view metrics.
-- All changes are additive or policy refinements; commerce tables and products are untouched.

-- Do not expose the full subscriber graph (subscriber_id values) to anonymous visitors.
drop policy if exists "read subscriptions" on public.bramble_channel_subscriptions;
drop policy if exists "users read own subscriptions" on public.bramble_channel_subscriptions;
create policy "users read own subscriptions"
on public.bramble_channel_subscriptions
for select
to authenticated
using (subscriber_id = (select auth.uid()) or public.is_bramble_admin());

-- A public, aggregate-only endpoint provides creator subscriber counts without exposing IDs.
create or replace function public.bramble_get_subscriber_count(p_channel_id uuid)
returns bigint
language sql
stable
security definer
set search_path = pg_catalog
as $function$
  select count(*)::bigint
  from public.bramble_channel_subscriptions
  where channel_id = p_channel_id;
$function$;
revoke all on function public.bramble_get_subscriber_count(uuid) from public;
grant execute on function public.bramble_get_subscriber_count(uuid) to anon, authenticated;

-- The existing record_bramble_video_view function inserted unique view records,
-- but there was no trigger to maintain bramble_videos.views_count.
create or replace function public.sync_bramble_video_views()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog
as $function$
begin
  if tg_op = 'INSERT' then
    update public.bramble_videos
    set views_count = views_count + 1
    where id = new.video_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.bramble_videos
    set views_count = greatest(0, views_count - 1)
    where id = old.video_id;
    return old;
  end if;
  return null;
end;
$function$;
revoke all on function public.sync_bramble_video_views() from public, anon, authenticated;
drop trigger if exists bramble_video_view_count_trigger on public.bramble_video_views;
create trigger bramble_video_view_count_trigger
after insert or delete on public.bramble_video_views
for each row execute function public.sync_bramble_video_views();

-- View recording is an authenticated-user action; do not expose it to anon callers.
revoke all on function public.record_bramble_video_view(uuid) from public, anon;
grant execute on function public.record_bramble_video_view(uuid) to authenticated;

-- Reaction rows are private to the reacting user/admin. Also prevent reactions
-- against hidden, draft, removed, or otherwise non-public videos.
drop policy if exists "users insert own reactions" on public.bramble_video_reactions;
create policy "users insert own reactions"
on public.bramble_video_reactions
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.bramble_videos v
    where v.id = video_id and v.status = 'published' and v.visibility = 'public'
  )
);
drop policy if exists "users update own reactions" on public.bramble_video_reactions;
create policy "users update own reactions"
on public.bramble_video_reactions
for update to authenticated
using (user_id = (select auth.uid()))
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.bramble_videos v
    where v.id = video_id and v.status = 'published' and v.visibility = 'public'
  )
);

