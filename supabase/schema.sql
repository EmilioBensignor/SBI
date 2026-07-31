-- =====================================================
-- Stupid Big Ideas — Schema V2
-- Proyecto Supabase: Registro (concepto `ideas`)
-- Idempotente: seguro de re-correr.
--
-- V2 separa temática de idea: una temática tiene N ideas.
-- La evaluación (puntaje / destaques / oportunidades) es de la sesión.
-- Migración destructiva: V1 no tenía contenido real cargado.
-- =====================================================

-- 1. TABLA: ideas_tematicas (la temática / sesión semanal)
-- El estado es derivado, no almacenado: una temática es pública cuando
-- tiene al menos una idea y al menos un campo de evaluación cargado.
create table if not exists public.ideas_tematicas (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  tematica text not null,
  fecha date not null default current_date,
  desafio text,
  puntaje numeric(2,1) check (puntaje between 0 and 5),
  destaques text,
  oportunidades text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Migración desde V1: las columnas de idea única se mudaron a public.ideas.
-- La policy vieja de anon depende de `titulo`, así que cae antes que la columna.
-- Se recrea más abajo contra tematica_cerrada().
drop policy if exists ideas_select_anon on public.ideas_tematicas;

alter table public.ideas_tematicas drop column if exists titulo;
alter table public.ideas_tematicas drop column if exists imagen_url;
alter table public.ideas_tematicas drop column if exists imagen_path;
alter table public.ideas_tematicas drop column if exists desarrollo;
alter table public.ideas_tematicas drop column if exists assets;
alter table public.ideas_tematicas drop column if exists correcciones;
alter table public.ideas_tematicas add column if not exists desafio text;

-- El puntaje pasó de int 1-10 a numeric 0-5 (lamparitas con media). La escala
-- vieja no se puede reescalar sin inventar datos, así que se descarta — pero
-- solo la primera vez: re-correr esto sobre V2 no debe tocar los puntajes.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'ideas_tematicas'
      and column_name = 'puntaje'
      and data_type = 'integer'
  ) then
    alter table public.ideas_tematicas drop constraint if exists ideas_tematicas_puntaje_check;
    alter table public.ideas_tematicas alter column puntaje type numeric(2,1) using null;
  end if;
end $$;

alter table public.ideas_tematicas drop constraint if exists ideas_tematicas_puntaje_check;
alter table public.ideas_tematicas
  add constraint ideas_tematicas_puntaje_check check (puntaje between 0 and 5);

create index if not exists ideas_tematicas_fecha_idx
  on public.ideas_tematicas (fecha desc);

-- 2. TABLA: ideas (N por temática)
-- assets: [{tipo:'imagen'|'audio'|'file'|'link', url, path?, label?}] — siempre
-- se leen junto con la idea, nunca se consultan solos (de ahí jsonb y no tabla).
create table if not exists public.ideas (
  id uuid primary key default gen_random_uuid(),
  tematica_id uuid not null references public.ideas_tematicas(id) on delete cascade,
  orden int not null default 0,
  titulo text,
  marca text,
  insight text,
  concepto text,
  anotaciones text,
  assets jsonb not null default '[]'::jsonb,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.ideas add column if not exists marca text;

-- Una idea se identifica por su marca o por su título: al menos uno de los dos.
-- La marca es la que se muestra grande en la ficha, así que exigir `titulo`
-- obligaba a llenar el campo que se ve chico.
alter table public.ideas alter column titulo drop not null;
alter table public.ideas drop constraint if exists ideas_titulo_o_marca_check;
alter table public.ideas add constraint ideas_titulo_o_marca_check
  check (titulo is not null or marca is not null);

create index if not exists ideas_tematica_id_idx
  on public.ideas (tematica_id, orden, created_at);

-- 3. TRIGGER: updated_at
create or replace function public.ideas_touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists ideas_tematicas_touch on public.ideas_tematicas;
create trigger ideas_tematicas_touch
  before update on public.ideas_tematicas
  for each row execute function public.ideas_touch_updated_at();

drop trigger if exists ideas_touch on public.ideas;
create trigger ideas_touch
  before update on public.ideas
  for each row execute function public.ideas_touch_updated_at();

-- 4. GRANTS Data API
-- anon: solo lectura — el index es público (las policies filtran las abiertas)
grant select on public.ideas_tematicas to anon;
grant select, insert, update, delete on public.ideas_tematicas to authenticated;
grant select, insert, update, delete on public.ideas_tematicas to service_role;

grant select on public.ideas to anon;
grant select, insert, update, delete on public.ideas to authenticated;
grant select, insert, update, delete on public.ideas to service_role;

-- 5. RLS
alter table public.ideas_tematicas enable row level security;
alter table public.ideas enable row level security;

-- Una temática está cerrada (= es pública) cuando fue trabajada y evaluada.
-- SECURITY DEFINER es obligatorio: la policy de `ideas` llama a esta función,
-- y si la función leyera `ideas` bajo RLS se llamaría a sí misma en loop hasta
-- reventar el stack ("stack depth limit exceeded"). Con definer saltea RLS.
-- Las condiciones baratas van primero para cortocircuitar antes del exists.
create or replace function public.tematica_cerrada(t public.ideas_tematicas)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select (t.puntaje is not null or t.destaques is not null or t.oportunidades is not null)
    and exists (select 1 from public.ideas i where i.tematica_id = t.id);
$$;

grant execute on function public.tematica_cerrada(public.ideas_tematicas) to anon, authenticated, service_role;

-- Lectura pública: solo las temáticas cerradas. No llama a is_motix_member()
-- a propósito — anon no debe tocar user_profiles.
drop policy if exists ideas_select_anon on public.ideas_tematicas;
create policy ideas_select_anon on public.ideas_tematicas
  for select to anon
  using (public.tematica_cerrada(ideas_tematicas));

-- Miembros Motix: ven y editan todo, incluidas las en curso.
drop policy if exists ideas_select_motix on public.ideas_tematicas;
create policy ideas_select_motix on public.ideas_tematicas
  for select to authenticated
  using (is_motix_member());

drop policy if exists ideas_insert_motix on public.ideas_tematicas;
create policy ideas_insert_motix on public.ideas_tematicas
  for insert to authenticated
  with check (is_motix_member() and created_by = (select auth.uid()));

drop policy if exists ideas_update_motix on public.ideas_tematicas;
create policy ideas_update_motix on public.ideas_tematicas
  for update to authenticated
  using (is_motix_member())
  with check (is_motix_member());

drop policy if exists ideas_delete_motix on public.ideas_tematicas;
create policy ideas_delete_motix on public.ideas_tematicas
  for delete to authenticated
  using (is_motix_member());

-- Las ideas heredan la visibilidad de su temática.
drop policy if exists ideas_hijas_select_anon on public.ideas;
create policy ideas_hijas_select_anon on public.ideas
  for select to anon
  using (
    exists (
      select 1 from public.ideas_tematicas t
      where t.id = ideas.tematica_id and public.tematica_cerrada(t)
    )
  );

drop policy if exists ideas_hijas_select_motix on public.ideas;
create policy ideas_hijas_select_motix on public.ideas
  for select to authenticated
  using (is_motix_member());

drop policy if exists ideas_hijas_insert_motix on public.ideas;
create policy ideas_hijas_insert_motix on public.ideas
  for insert to authenticated
  with check (is_motix_member() and created_by = (select auth.uid()));

drop policy if exists ideas_hijas_update_motix on public.ideas;
create policy ideas_hijas_update_motix on public.ideas
  for update to authenticated
  using (is_motix_member())
  with check (is_motix_member());

drop policy if exists ideas_hijas_delete_motix on public.ideas;
create policy ideas_hijas_delete_motix on public.ideas
  for delete to authenticated
  using (is_motix_member());

-- 6. STORAGE: bucket ideas (público — las URLs se sirven directo)
insert into storage.buckets (id, name, public)
values ('ideas', 'ideas', true)
on conflict (id) do update set public = true;

drop policy if exists "ideas_public_read" on storage.objects;
create policy "ideas_public_read" on storage.objects
  for select using (bucket_id = 'ideas');

drop policy if exists "ideas_motix_insert" on storage.objects;
create policy "ideas_motix_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'ideas' and is_motix_member());

drop policy if exists "ideas_motix_update" on storage.objects;
create policy "ideas_motix_update" on storage.objects
  for update to authenticated
  using (bucket_id = 'ideas' and is_motix_member());

drop policy if exists "ideas_motix_delete" on storage.objects;
create policy "ideas_motix_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'ideas' and is_motix_member());
