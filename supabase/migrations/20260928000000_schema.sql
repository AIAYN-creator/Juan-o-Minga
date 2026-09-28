-- Juan o Minga: core schema -- enums, tables, constraints and RLS.
-- RPC functions (get_today_round, submit_answer, ...) come in later migrations.
--
-- Security model: the anon key is public, so the client can only touch what RLS
-- and column grants allow. Nobody reads phrases or daily_rounds directly and
-- nobody writes answers directly: that all goes through SECURITY DEFINER RPCs.

create type public.side as enum ('charanga', 'penista');
create type public.phrase_status as enum ('pending', 'approved', 'rejected');

-- ---------------------------------------------------------------------------
-- app_config: single row. launch_date drives the round number (#N = days since
-- launch + 1). Change it from the Supabase table editor before going live.
-- ---------------------------------------------------------------------------
create table public.app_config (
  id boolean primary key default true check (id),
  launch_date date not null
);

insert into public.app_config (launch_date)
values ((now() at time zone 'Europe/Madrid')::date);

-- ---------------------------------------------------------------------------
-- profiles: one per player, created at onboarding when they pick a nickname.
-- Never store email or Google name here: the leaderboard shows nickname only.
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nickname text not null,
  created_at timestamptz not null default now(),
  constraint nickname_length check (char_length(nickname) between 3 and 20),
  constraint nickname_trimmed check (nickname = btrim(nickname)),
  constraint nickname_printable check (nickname !~ '[[:cntrl:]]')
);

-- Case-insensitive, so "Juan" can't impersonate "juan".
create unique index profiles_nickname_key on public.profiles (lower(nickname));

-- ---------------------------------------------------------------------------
-- phrases: the game content. Moderated by the admin in the table editor
-- (status pending -> approved / rejected).
-- ---------------------------------------------------------------------------
create table public.phrases (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  side public.side not null,
  author text,
  context text not null,
  status public.phrase_status not null default 'pending',
  submitted_by uuid references public.profiles (id) on delete set null,
  last_used_on date,
  created_at timestamptz not null default now(),
  constraint text_length check (char_length(btrim(text)) between 1 and 280),
  constraint context_length check (char_length(btrim(context)) between 1 and 280),
  constraint author_length check (author is null or char_length(btrim(author)) between 1 and 60),
  -- Peñistas are never named, not even in the database.
  constraint author_only_for_charanga check (author is null or side = 'charanga')
);

-- Round picking: approved phrases, never-used first, then least recently used.
create index phrases_pick_idx on public.phrases (last_used_on nulls first)
  where status = 'approved';

-- ---------------------------------------------------------------------------
-- daily_rounds: the 3 phrases of each day, the same for everyone.
-- ---------------------------------------------------------------------------
create table public.daily_rounds (
  round_date date not null,
  position smallint not null check (position between 1 and 3),
  phrase_id uuid not null references public.phrases (id) on delete restrict,
  primary key (round_date, position),
  unique (round_date, phrase_id)
);

-- ---------------------------------------------------------------------------
-- answers: the primary key is what enforces "one answer per phrase per day",
-- so the daily limit holds across browsers and incognito windows.
-- ---------------------------------------------------------------------------
create table public.answers (
  user_id uuid not null references public.profiles (id) on delete cascade,
  round_date date not null,
  position smallint not null,
  choice public.side not null,
  is_correct boolean not null,
  answered_at timestamptz not null default now(),
  primary key (user_id, round_date, position),
  foreign key (round_date, position)
    references public.daily_rounds (round_date, position) on delete cascade
);

create index answers_round_date_idx on public.answers (round_date);

-- ---------------------------------------------------------------------------
-- Row level security and grants.
-- Supabase grants ALL on new public tables to anon/authenticated by default,
-- so revoke everything first and grant back only what the client needs.
-- ---------------------------------------------------------------------------
alter table public.app_config enable row level security;
alter table public.profiles enable row level security;
alter table public.phrases enable row level security;
alter table public.daily_rounds enable row level security;
alter table public.answers enable row level security;

revoke all on public.app_config, public.profiles, public.phrases,
  public.daily_rounds, public.answers from anon, authenticated;

-- app_config: launch date is not secret; anyone can read it.
grant select on public.app_config to anon, authenticated;
create policy "config is readable by everyone"
  on public.app_config for select to anon, authenticated using (true);

-- profiles: each user sees and edits only their own row; only the nickname
-- is writable. Other players' nicknames reach the client via get_leaderboard.
grant select, insert (id, nickname), update (nickname) on public.profiles to authenticated;
create policy "users read their own profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy "users create their own profile"
  on public.profiles for insert to authenticated
  with check (id = (select auth.uid()));
create policy "users rename their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- phrases, daily_rounds: no grants, no policies. RPC access only.

-- answers: read-only, own rows. Inserts happen inside submit_answer().
grant select on public.answers to authenticated;
create policy "users read their own answers"
  on public.answers for select to authenticated
  using (user_id = (select auth.uid()));
