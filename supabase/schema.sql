-- =====================================================
-- Stupid Big Ideas — Schema V1
-- Proyecto Supabase: Registro (concepto `ideas`)
-- Idempotente: seguro de re-correr.
-- =====================================================

-- 1. TABLA: ideas_tematicas
-- Una fila por semana/temática. El estado es derivado, no almacenado:
-- `titulo is null` = en curso (paso 1), con titulo = completa (pasos 3-4).
-- assets: [{tipo:'file'|'link', url, path?, label?}] — 2-5 items, siempre se
-- leen junto con la idea, nunca se consultan solos (de ahí jsonb y no tabla).
create table if not exists public.ideas_tematicas (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  tematica text not null,
  fecha date not null default current_date,
  titulo text,
  imagen_url text,
  imagen_path text,
  desarrollo text,
  assets jsonb not null default '[]'::jsonb,
  puntaje int check (puntaje between 1 and 10),
  correcciones text,
  destaques text,
  oportunidades text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists ideas_tematicas_fecha_idx
  on public.ideas_tematicas (fecha desc);

-- 2. TRIGGER: updated_at
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

-- 3. GRANTS Data API
-- anon: solo lectura — el index es público (la policy filtra las incompletas)
grant select on public.ideas_tematicas to anon;
grant select, insert, update, delete on public.ideas_tematicas to authenticated;
grant select, insert, update, delete on public.ideas_tematicas to service_role;

-- 4. RLS
alter table public.ideas_tematicas enable row level security;

-- Lectura pública: solo las ideas ya completas. No llama a is_motix_member()
-- a propósito — anon no debe tocar user_profiles.
drop policy if exists ideas_select_anon on public.ideas_tematicas;
create policy ideas_select_anon on public.ideas_tematicas
  for select to anon
  using (titulo is not null);

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

-- 5. STORAGE: bucket ideas (público — las URLs se sirven directo)
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
