-- GameSphere initial schema. Apply with Supabase SQL editor or Supabase CLI.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (char_length(username) between 3 and 24),
  display_name text not null default 'New Gamer',
  bio text not null default '' check (char_length(bio) <= 280),
  avatar_url text,
  xp integer not null default 0 check (xp >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  genre text not null default 'Other',
  platforms text[] not null default '{}',
  cover_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.user_games (
  user_id uuid not null references public.profiles(id) on delete cascade,
  game_id uuid not null references public.games(id) on delete cascade,
  preferred_role text,
  created_at timestamptz not null default now(),
  primary key (user_id, game_id)
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  game_id uuid references public.games(id) on delete set null,
  media_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.tournaments (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles(id) on delete restrict,
  game_id uuid not null references public.games(id) on delete restrict,
  title text not null check (char_length(title) between 3 and 100),
  description text not null default '',
  format text not null check (format in ('single_elimination', 'round_robin')),
  max_entries integer not null default 16 check (max_entries between 2 and 512),
  starts_at timestamptz not null,
  status text not null default 'registration' check (status in ('draft','registration','in_progress','completed','cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.tournament_entries (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'registered' check (status in ('registered','confirmed','withdrawn','disqualified')),
  created_at timestamptz not null default now(),
  unique (tournament_id, user_id)
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  tournament_id uuid not null references public.tournaments(id) on delete cascade,
  round_number integer not null check (round_number > 0),
  match_number integer not null check (match_number > 0),
  player_one uuid references public.profiles(id) on delete set null,
  player_two uuid references public.profiles(id) on delete set null,
  winner_id uuid references public.profiles(id) on delete set null,
  status text not null default 'pending' check (status in ('pending','reported','approved','disputed')),
  reported_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  unique (tournament_id, round_number, match_number)
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null default '',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists posts_created_at_idx on public.posts (created_at desc);
create index if not exists posts_author_id_idx on public.posts (author_id);
create index if not exists comments_post_id_idx on public.comments (post_id, created_at);
create index if not exists tournaments_status_start_idx on public.tournaments (status, starts_at);
create index if not exists tournament_entries_tournament_idx on public.tournament_entries (tournament_id);
create index if not exists matches_tournament_round_idx on public.matches (tournament_id, round_number, match_number);
create index if not exists notifications_user_created_idx on public.notifications (user_id, created_at desc);

-- RLS defaults: enable RLS on all user-facing tables; add feature-specific policies before production launch.
alter table public.profiles enable row level security;
alter table public.games enable row level security;
alter table public.user_games enable row level security;
alter table public.posts enable row level security;
alter table public.comments enable row level security;
alter table public.post_likes enable row level security;
alter table public.tournaments enable row level security;
alter table public.tournament_entries enable row level security;
alter table public.matches enable row level security;
alter table public.notifications enable row level security;

-- Public read policies for catalogue, public profiles, community content and tournament discovery.
create policy "Games are readable by everyone" on public.games for select using (true);
create policy "Profiles are readable by everyone" on public.profiles for select using (true);
create policy "Users can insert their own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "Users can update their own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy "User games are readable by everyone" on public.user_games for select using (true);
create policy "Users manage their own games" on public.user_games for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Posts are readable by everyone" on public.posts for select using (true);
create policy "Authenticated users create their own posts" on public.posts for insert to authenticated with check (auth.uid() = author_id);
create policy "Authors update their own posts" on public.posts for update to authenticated using (auth.uid() = author_id) with check (auth.uid() = author_id);
create policy "Authors delete their own posts" on public.posts for delete to authenticated using (auth.uid() = author_id);
create policy "Comments are readable by everyone" on public.comments for select using (true);
create policy "Users create their own comments" on public.comments for insert to authenticated with check (auth.uid() = author_id);
create policy "Comment authors delete their own comments" on public.comments for delete to authenticated using (auth.uid() = author_id);
create policy "Likes are readable by everyone" on public.post_likes for select using (true);
create policy "Users manage their own likes" on public.post_likes for all to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Tournaments are readable by everyone" on public.tournaments for select using (true);
create policy "Authenticated users create tournaments" on public.tournaments for insert to authenticated with check (auth.uid() = organizer_id);
create policy "Organizers update their tournaments" on public.tournaments for update to authenticated using (auth.uid() = organizer_id) with check (auth.uid() = organizer_id);
create policy "Entries are readable by everyone" on public.tournament_entries for select using (true);
create policy "Users register themselves" on public.tournament_entries for insert to authenticated with check (auth.uid() = user_id);
create policy "Users withdraw their own entries" on public.tournament_entries for delete to authenticated using (auth.uid() = user_id);
create policy "Matches are readable by everyone" on public.matches for select using (true);
create policy "Users read their own notifications" on public.notifications for select to authenticated using (auth.uid() = user_id);
create policy "Users update their own notifications" on public.notifications for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- IMPORTANT: This is a starter schema. Before a public launch, tighten tournament-entry writes,
-- protect match outcomes behind organizer/server validation, and add moderation/reporting policies.
