-- Reaction records contain user IDs. Public feeds use video likes_count;
-- only the reacting user and Bramble admins need row-level reaction records.
drop policy if exists "read reactions" on public.bramble_video_reactions;
drop policy if exists "users read own reactions" on public.bramble_video_reactions;
create policy "users read own reactions"
on public.bramble_video_reactions
for select
to authenticated
using (user_id = (select auth.uid()) or public.is_bramble_admin());
