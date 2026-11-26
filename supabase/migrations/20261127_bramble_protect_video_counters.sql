-- Protect creator-facing counters from direct client edits.
-- Counter changes are allowed only from nested database counter triggers or Bramble admins.
create or replace function public.enforce_bramble_video_moderation()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $function$
begin
  if public.is_bramble_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.visibility := 'public';
    return new;
  end if;

  if new.status is distinct from old.status
     or new.visibility is distinct from old.visibility then
    raise exception 'Only Bramble moderators can publish or change video visibility';
  end if;

  if (new.views_count is distinct from old.views_count
      or new.likes_count is distinct from old.likes_count)
     and pg_trigger_depth() <= 1 then
    raise exception 'Video view and like counts are maintained automatically';
  end if;

  return new;
end;
$function$;

