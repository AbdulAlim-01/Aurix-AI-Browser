class SupabaseConstant {
  static const String SUPABASE_INIT_SQL = r"""
-- ═══════════════════════════════════════════════════════════
-- INITIAL SETUP
-- ═══════════════════════════════════════════════════════════

-- Enable UUID extension if not already enabled
create extension if not exists "uuid-ossp";

-- ═══════════════════════════════════════════════════════════
-- 1. PROFILES TABLE (User Plans & Details)
-- ═══════════════════════════════════════════════════════════

create table if not exists profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  plan text not null default 'free',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Secure the profiles table
alter table profiles enable row level security;

-- Policies for profiles
do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'Users can view their own profile' and tablename = 'profiles') then
    create policy "Users can view their own profile" on profiles for select using (auth.uid() = id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can update their own profile' and tablename = 'profiles') then
    create policy "Users can update their own profile" on profiles for update using (auth.uid() = id);
  end if;
end $$;

-- Trigger to create a profile entry when a new user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, plan)
  values (new.id, 'free');
  return new;
end;
$$ language plpgsql security definer;

-- Drop trigger if exists to ensure idempotency when recreating
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ═══════════════════════════════════════════════════════════
-- 2. DAILY ANALYTICS TABLE (Global Counts by Date)
-- ═══════════════════════════════════════════════════════════

create table if not exists daily_analytics (
  date date not null primary key default current_date,
  search_count int default 0,
  summary_count int default 0,
  chat_count int default 0,
  content_generation_count int default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS (Public read-only, or Service Role only for updates)
alter table daily_analytics enable row level security;

-- Function to increment counters safely
-- p_action_type: 'search', 'summary', 'chat', 'content'
create or replace function increment_daily_metric(p_action_type text)
returns void as $$
begin
  insert into daily_analytics (date, search_count, summary_count, chat_count, content_generation_count)
  values (
    current_date, 
    case when p_action_type = 'search' then 1 else 0 end,
    case when p_action_type = 'summary' then 1 else 0 end,
    case when p_action_type = 'chat' then 1 else 0 end,
    case when p_action_type = 'content' then 1 else 0 end
  )
  on conflict (date)
  do update set 
    search_count = daily_analytics.search_count + (case when p_action_type = 'search' then 1 else 0 end),
    summary_count = daily_analytics.summary_count + (case when p_action_type = 'summary' then 1 else 0 end),
    chat_count = daily_analytics.chat_count + (case when p_action_type = 'chat' then 1 else 0 end),
    content_generation_count = daily_analytics.content_generation_count + (case when p_action_type = 'content' then 1 else 0 end);
end;
$$ language plpgsql security definer;

-- ═══════════════════════════════════════════════════════════
-- 3. BOOKMARKS TABLE
-- ═══════════════════════════════════════════════════════════

create table if not exists bookmarks (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id) not null,
  title text,
  url text not null,
  favicon_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table bookmarks enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'Users can view their own bookmarks' and tablename = 'bookmarks') then
    create policy "Users can view their own bookmarks" on bookmarks for select using (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can insert their own bookmarks' and tablename = 'bookmarks') then
    create policy "Users can insert their own bookmarks" on bookmarks for insert with check (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can delete their own bookmarks' and tablename = 'bookmarks') then
    create policy "Users can delete their own bookmarks" on bookmarks for delete using (auth.uid() = user_id);
  end if;
end $$;

-- ═══════════════════════════════════════════════════════════
-- 4. DOWNLOADS TABLE
-- ═══════════════════════════════════════════════════════════

create table if not exists downloads (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id) not null,
  url text not null,
  filename text not null,
  status text default 'downloading',
  file_path text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table downloads enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'Users can view their own downloads' and tablename = 'downloads') then
    create policy "Users can view their own downloads" on downloads for select using (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can insert their own downloads' and tablename = 'downloads') then
    create policy "Users can insert their own downloads" on downloads for insert with check (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can update their own downloads' and tablename = 'downloads') then
    create policy "Users can update their own downloads" on downloads for update using (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can delete their own downloads' and tablename = 'downloads') then
    create policy "Users can delete their own downloads" on downloads for delete using (auth.uid() = user_id);
  end if;
end $$;

-- ═══════════════════════════════════════════════════════════
-- 5. AI PROFILES TABLE (Personas)
-- ═══════════════════════════════════════════════════════════

create table if not exists ai_profiles (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id) not null,
  profile_name text not null,
  profile_type text not null,
  profile_context text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table ai_profiles enable row level security;

do $$ begin
  if not exists (select 1 from pg_policies where policyname = 'Users can view their own ai_profiles' and tablename = 'ai_profiles') then
    create policy "Users can view their own ai_profiles" on ai_profiles for select using (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can insert their own ai_profiles' and tablename = 'ai_profiles') then
    create policy "Users can insert their own ai_profiles" on ai_profiles for insert with check (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can update their own ai_profiles' and tablename = 'ai_profiles') then
    create policy "Users can update their own ai_profiles" on ai_profiles for update using (auth.uid() = user_id);
  end if;

  if not exists (select 1 from pg_policies where policyname = 'Users can delete their own ai_profiles' and tablename = 'ai_profiles') then
    create policy "Users can delete their own ai_profiles" on ai_profiles for delete using (auth.uid() = user_id);
  end if;
end $$;
""";
}
