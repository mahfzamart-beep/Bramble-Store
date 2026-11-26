-- Prevent direct PostgREST RPC invocation of a trigger-only counter function.
-- The database trigger can still invoke this function; API roles cannot call it directly.
revoke execute on function public.sync_bramble_video_likes() from public;
revoke execute on function public.sync_bramble_video_likes() from anon, authenticated;
