-- DART database schema for Supabase. Run all of this in SQL Editor.
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'مستخدم',
 bio text default '', avatar_url text,
 created_at timestamptz not null default now()
);
create table if not exists public.posts (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 body text not null default '', image_url text, created_at timestamptz not null default now()
);
create table if not exists public.likes (
 post_id uuid not null references public.posts(id) on delete cascade, user_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(post_id,user_id)
);
create table if not exists public.comments (
 id uuid primary key default gen_random_uuid(), post_id uuid not null references public.posts(id) on delete cascade,
 user_id uuid not null references public.profiles(id) on delete cascade, body text not null, created_at timestamptz not null default now()
);
create table if not exists public.follows (
 follower_id uuid not null references public.profiles(id) on delete cascade, following_id uuid not null references public.profiles(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(follower_id,following_id), check(follower_id<>following_id)
);
create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(), sender_id uuid not null references public.profiles(id) on delete cascade,
 receiver_id uuid not null references public.profiles(id) on delete cascade, body text not null,
 created_at timestamptz not null default now(), check(sender_id<>receiver_id)
);
create table if not exists public.stories (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
 image_url text not null, created_at timestamptz not null default now(), expires_at timestamptz not null default now()+interval '24 hours'
);
-- Create a profile automatically when a new auth user signs up.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1))); return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
-- RLS
alter table public.profiles enable row level security; alter table public.posts enable row level security; alter table public.likes enable row level security; alter table public.comments enable row level security; alter table public.follows enable row level security; alter table public.messages enable row level security; alter table public.stories enable row level security;
drop policy if exists "profiles readable" on public.profiles; create policy "profiles readable" on public.profiles for select to authenticated using(true);
drop policy if exists "profile update own" on public.profiles; create policy "profile update own" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
drop policy if exists "posts readable" on public.posts; create policy "posts readable" on public.posts for select to authenticated using(true);
drop policy if exists "posts create own" on public.posts; create policy "posts create own" on public.posts for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "posts delete own" on public.posts; create policy "posts delete own" on public.posts for delete to authenticated using(user_id=auth.uid());
drop policy if exists "likes readable" on public.likes; create policy "likes readable" on public.likes for select to authenticated using(true);
drop policy if exists "likes own" on public.likes; create policy "likes own" on public.likes for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "unlike own" on public.likes; create policy "unlike own" on public.likes for delete to authenticated using(user_id=auth.uid());
drop policy if exists "comments readable" on public.comments; create policy "comments readable" on public.comments for select to authenticated using(true);
drop policy if exists "comment own" on public.comments; create policy "comment own" on public.comments for insert to authenticated with check(user_id=auth.uid());
drop policy if exists "follows readable" on public.follows; create policy "follows readable" on public.follows for select to authenticated using(true);
drop policy if exists "follow own" on public.follows; create policy "follow own" on public.follows for insert to authenticated with check(follower_id=auth.uid());
drop policy if exists "unfollow own" on public.follows; create policy "unfollow own" on public.follows for delete to authenticated using(follower_id=auth.uid());
drop policy if exists "messages participants" on public.messages; create policy "messages participants" on public.messages for select to authenticated using(sender_id=auth.uid() or receiver_id=auth.uid());
drop policy if exists "send messages" on public.messages; create policy "send messages" on public.messages for insert to authenticated with check(sender_id=auth.uid());
drop policy if exists "stories readable" on public.stories; create policy "stories readable" on public.stories for select to authenticated using(expires_at>now());
drop policy if exists "stories own" on public.stories; create policy "stories own" on public.stories for insert to authenticated with check(user_id=auth.uid());
-- Storage buckets: create post-images and story-images as PUBLIC buckets in dashboard.
-- Policies (run after creating buckets):
drop policy if exists "authenticated upload post images" on storage.objects; create policy "authenticated upload post images" on storage.objects for insert to authenticated with check(bucket_id='post-images' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "post images public read" on storage.objects; create policy "post images public read" on storage.objects for select to public using(bucket_id='post-images');
drop policy if exists "authenticated upload story images" on storage.objects; create policy "authenticated upload story images" on storage.objects for insert to authenticated with check(bucket_id='story-images' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "story images public read" on storage.objects; create policy "story images public read" on storage.objects for select to public using(bucket_id='story-images');
