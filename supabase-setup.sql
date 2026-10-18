-- AIVAULT setup for Supabase
-- Replace YOUR_LOGIN_EMAIL@example.com with the exact email you will use to sign in.
create table if not exists public.portfolio (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text,
  description text,
  image_url text,
  published boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  rating int not null check (rating between 1 and 5),
  body text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
alter table public.portfolio enable row level security;
alter table public.reviews enable row level security;
drop policy if exists "Public can read published portfolio" on public.portfolio;
create policy "Public can read published portfolio" on public.portfolio for select using (published = true);
drop policy if exists "Owner can manage portfolio" on public.portfolio;
create policy "Owner can manage portfolio" on public.portfolio for all to authenticated
using ((auth.jwt()->>'email') = 'YOUR_LOGIN_EMAIL@example.com')
with check ((auth.jwt()->>'email') = 'YOUR_LOGIN_EMAIL@example.com');
drop policy if exists "Public can read approved reviews" on public.reviews;
create policy "Public can read approved reviews" on public.reviews for select using (status = 'approved');
drop policy if exists "Visitors can submit reviews" on public.reviews;
create policy "Visitors can submit reviews" on public.reviews for insert to anon, authenticated with check (status = 'pending');
drop policy if exists "Owner can manage reviews" on public.reviews;
create policy "Owner can manage reviews" on public.reviews for all to authenticated
using ((auth.jwt()->>'email') = 'YOUR_LOGIN_EMAIL@example.com')
with check ((auth.jwt()->>'email') = 'YOUR_LOGIN_EMAIL@example.com');

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('portfolio-images', 'portfolio-images', true, 10485760, array['image/jpeg','image/png','image/webp','image/gif'])
on conflict (id) do nothing;
drop policy if exists "Public can view portfolio images" on storage.objects;
create policy "Public can view portfolio images" on storage.objects for select using (bucket_id = 'portfolio-images');
drop policy if exists "Owner can upload portfolio images" on storage.objects;
create policy "Owner can upload portfolio images" on storage.objects for insert to authenticated
with check (bucket_id = 'portfolio-images' and (auth.jwt()->>'email') = 'YOUR_LOGIN_EMAIL@example.com');
drop policy if exists "Owner can delete portfolio images" on storage.objects;
create policy "Owner can delete portfolio images" on storage.objects for delete to authenticated
using (bucket_id = 'portfolio-images' and (auth.jwt()->>'email') = 'YOUR_LOGIN_EMAIL@example.com');
