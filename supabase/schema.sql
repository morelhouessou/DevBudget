-- DevBudget : schéma de synchronisation (Supabase / PostgreSQL)
--
-- À coller et exécuter UNE FOIS dans Supabase > SQL Editor > New query > Run.
-- Chaque utilisateur ne voit et ne modifie que ses propres lignes (RLS).
-- Ce script ne contient aucune clé ni aucun secret.
--
-- Périmètre : synchronisation des données d'un même utilisateur entre ses
-- appareils (et sauvegarde dans le cloud). Le partage d'un budget entre
-- plusieurs comptes utilisateurs n'est pas inclus : il demandera des tables
-- d'invitation et des règles d'accès supplémentaires.

-- Les identifiants sont générés par l'application (texte) : la clé primaire
-- est donc (owner_id, id) pour éviter toute collision entre utilisateurs.

create table if not exists public.members (
  owner_id   uuid not null default auth.uid()
             references auth.users (id) on delete cascade,
  id         text not null,
  name       text not null,
  role       text not null check (role in ('admin', 'member', 'viewer')),
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false,
  primary key (owner_id, id)
);

create table if not exists public.budgets (
  owner_id     uuid not null default auth.uid()
               references auth.users (id) on delete cascade,
  id           text not null,
  name         text not null,
  total_amount double precision not null check (total_amount > 0),
  start_date   timestamptz not null,
  end_date     timestamptz not null,
  category     text,
  recurring    boolean not null default false,
  currency     text,
  member_ids   text[] not null default '{}',
  is_shared    boolean not null default false,
  updated_at   timestamptz not null default now(),
  deleted      boolean not null default false,
  primary key (owner_id, id)
);

create table if not exists public.expenses (
  owner_id   uuid not null default auth.uid()
             references auth.users (id) on delete cascade,
  id         text not null,
  title      text not null,
  amount     double precision not null check (amount > 0),
  category   text not null,
  date       timestamptz not null,
  member_id  text not null,
  budget_id  text,
  is_income  boolean not null default false,
  currency   text,
  updated_at timestamptz not null default now(),
  deleted    boolean not null default false,
  primary key (owner_id, id)
);

-- Récupération des changements depuis la dernière synchronisation.
create index if not exists members_sync_idx  on public.members  (owner_id, updated_at);
create index if not exists budgets_sync_idx  on public.budgets  (owner_id, updated_at);
create index if not exists expenses_sync_idx on public.expenses (owner_id, updated_at);

-- L'horloge du serveur fait foi (pas celle du téléphone) : à chaque écriture,
-- updated_at est fixé par le serveur et owner_id est forcé à l'utilisateur
-- connecté (impossible d'écrire pour quelqu'un d'autre).
create or replace function public.devbudget_stamp()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at := now();
  new.owner_id := auth.uid();
  return new;
end;
$$;

drop trigger if exists members_stamp  on public.members;
drop trigger if exists budgets_stamp  on public.budgets;
drop trigger if exists expenses_stamp on public.expenses;

create trigger members_stamp  before insert or update on public.members
  for each row execute function public.devbudget_stamp();
create trigger budgets_stamp  before insert or update on public.budgets
  for each row execute function public.devbudget_stamp();
create trigger expenses_stamp before insert or update on public.expenses
  for each row execute function public.devbudget_stamp();

-- Sécurité : RLS activée, accès réservé aux utilisateurs connectés et
-- limité à leurs propres lignes. Aucun accès pour la clé anonyme seule.
alter table public.members  enable row level security;
alter table public.budgets  enable row level security;
alter table public.expenses enable row level security;

drop policy if exists "members: propriétaire" on public.members;
drop policy if exists "budgets: propriétaire" on public.budgets;
drop policy if exists "expenses: propriétaire" on public.expenses;

create policy "members: propriétaire" on public.members
  for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "budgets: propriétaire" on public.budgets
  for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "expenses: propriétaire" on public.expenses
  for all to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

revoke all on public.members, public.budgets, public.expenses from anon;
