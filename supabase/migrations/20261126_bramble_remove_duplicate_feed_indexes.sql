-- Remove redundant Bramble indexes that duplicated indexes already present before the rebuild.
drop index if exists public.bramble_videos_public_feed_idx;
drop index if exists public.bramble_videos_channel_feed_idx;
drop index if exists public.bramble_comments_video_feed_idx;
