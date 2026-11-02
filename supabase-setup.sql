-- Crystal Collecting Simulator community: run this once in Supabase (SQL Editor > New query > paste > Run).

-- ---------- profiles (one per account; username is public) ----------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[A-Za-z0-9_]{3,20}$'),
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
create policy "profiles are public" on public.profiles for select using (true);
-- no insert/update policies: profiles are created by the trigger below, and nobody can edit is_admin from the browser.

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username)
  values (new.id, coalesce(new.raw_user_meta_data->>'username', 'user_' || substr(new.id::text, 1, 8)));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false)
$$;

-- ---------- posts ----------
create table public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 60),
  image_path text not null,
  created_at timestamptz not null default now()
);
alter table public.posts enable row level security;
create policy "posts are public" on public.posts for select using (true);
create policy "insert own posts" on public.posts for insert to authenticated
  with check (user_id = auth.uid() and image_path like auth.uid()::text || '/%');
create policy "delete own posts or admin" on public.posts for delete to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- at most 10 posts per account per day
create function public.limit_posts() returns trigger language plpgsql as $$
begin
  if (select count(*) from public.posts where user_id = new.user_id and created_at > now() - interval '1 day') >= 10 then
    raise exception 'Daily post limit reached';
  end if;
  return new;
end $$;
create trigger posts_limit before insert on public.posts for each row execute function public.limit_posts();

-- ---------- likes ----------
create table public.likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
alter table public.likes enable row level security;
create policy "likes are public" on public.likes for select using (true);
create policy "like as yourself" on public.likes for insert to authenticated with check (user_id = auth.uid());
create policy "unlike as yourself" on public.likes for delete to authenticated using (user_id = auth.uid());

-- ---------- reports (only admins can read them) ----------
create table public.reports (
  id bigint generated always as identity primary key,
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  reason text not null default '' check (char_length(reason) <= 200),
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);
alter table public.reports enable row level security;
create policy "report as yourself" on public.reports for insert to authenticated with check (user_id = auth.uid());
create policy "admins read reports" on public.reports for select to authenticated using (public.is_admin());
create policy "admins clear reports" on public.reports for delete to authenticated using (public.is_admin());

-- ---------- feed view (posts + author + like count) ----------
create view public.posts_feed with (security_invoker = true) as
  select p.id, p.user_id, p.title, p.image_path, p.created_at, pr.username,
         (select count(*) from public.likes l where l.post_id = p.id) as like_count
  from public.posts p join public.profiles pr on pr.id = p.user_id;
grant select on public.posts_feed to anon, authenticated;

-- ---------- image storage ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('posts', 'posts', true, 4194304, array['image/png','image/jpeg','image/webp','image/gif'])
on conflict (id) do nothing;
create policy "anyone can view post images" on storage.objects for select using (bucket_id = 'posts');
create policy "upload into your own folder" on storage.objects for insert to authenticated
  with check (bucket_id = 'posts' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "delete your own images or admin" on storage.objects for delete to authenticated
  using (bucket_id = 'posts' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

-- ---------- let people delete their own account (the page removes their images first) ----------
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = public, auth as $$
begin
  delete from auth.users where id = auth.uid();
end $$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;

-- ---------- make yourself a moderator (run AFTER you have signed up on the page) ----------
-- update public.profiles set is_admin = true where username = 'LumeCraftor';
