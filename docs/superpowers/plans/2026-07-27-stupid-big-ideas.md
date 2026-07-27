# Stupid Big Ideas Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Registro público de las ideas creativas de Motix — index sin sesión con la dinámica y las ideas ganadoras, CRUD para miembros Motix logueados.

**Architecture:** Nuxt 4 SSR con Nuxt UI v4 sobre la DB Supabase existente `Registro`. Una tabla nueva `ideas_tematicas` con estado derivado (`titulo is null` = en curso). El index es público y la edición vive sobre las mismas vistas, sin dashboard aparte. Assets como `jsonb` (mezcla de archivos en Storage y links externos).

**Tech Stack:** Nuxt ^4.5.1, Nuxt UI ^4.10, Tailwind CSS ^4.3.3, @nuxtjs/supabase ^2.0.9, @nuxt/fonts ^0.14, pnpm. (Versiones verificadas en npm el 2026-07-27 — son las últimas.)

## Global Constraints

- **Directorio de trabajo:** `/Users/lio/Desktop/Motix/Creatividad/SBI` (repo vacío, NO es git).
- **NO ejecutar ningún comando git.** El usuario valida todo en local primero. Los pasos de "Commit" de las tareas quedan explícitamente omitidos en este plan.
- **CERO comentarios en código JS/Vue.** Sin excepciones. Lo que necesite explicación va al `CLAUDE.md` del proyecto. En SQL de migraciones los comentarios sí van, en español.
- **Orden en `.vue`:** `<template>` → `<script setup>` → `<style scoped>` (style solo si Tailwind no alcanza). NUNCA `lang="ts"` en `.vue`.
- **Composables en `.js`**, patrón `useXxx`. JavaScript puro, sin TS.
- **Estado:** `useState` de Nuxt o composables. NUNCA Pinia ni Axios (`useFetch`/`$fetch`).
- **Gestor de paquetes:** pnpm.
- **UI en español rioplatense**, código en inglés (salvo dominio: `tematica`, `desarrollo`, `puntaje`, `correcciones`, `destaques`, `oportunidades`, `assets`).
- **Iconos:** `i-lucide-*` vía `UIcon`.
- **Light mode único:** `ui: { colorMode: false }` en `nuxt.config.ts`. Sin dark mode.
- **Errores de escritura:** banner rojo inline (`bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 px-3 py-2`), con `role="alert"`. Sin toasts.
- **Carga async:** `USkeleton`, nunca spinner full-screen.
- **Backend:** proyecto Supabase `Registro`, vía el MCP server `supabase-registro`. Reutiliza `user_profiles` y `is_motix_member()`. NO tocar ninguna tabla de finanzas.
- **Tabla nueva:** `public.ideas_tematicas`. Bucket nuevo: `ideas`.
- **Toda migration que cree tabla en `public` DEBE incluir GRANTs explícitos** (`anon` para lectura pública, `authenticated`, `service_role`) + RLS + policies. Sin grant, PostgREST da `42501`.
- **Antes de dar una tarea por terminada:** verificar que no haya errores de Tailwind en `main.css` ni de ESLint.

**Spec de referencia:** `docs/superpowers/specs/2026-07-27-stupid-big-ideas-design.md`

## Dirección visual

El código de cada tarea ya viene con las clases resueltas — **no improvisar un criterio propio ni "mejorar" el diseño por tarea.** Estas reglas son para resolver lo que el código no cubra y para mantener coherencia entre tareas.

- **Referencia:** editorial y silencioso, tipo archivo de estudio de diseño. La imagen y el texto mandan; el chrome desaparece.
- **Fondo blanco** (`bg-white`), no gris. El pcm-template usa `bg-stone-50` porque es un panel de admin; acá el index es una pieza pública.
- **Escala de grises `stone`**, nunca `gray` ni `slate`. Jerarquía: `stone-900` títulos, `stone-700` cuerpo, `stone-500` secundario, `stone-400` metadata, `stone-300` placeholders, `stone-200`/`stone-100` bordes.
- **Bordes finos y claros** (`border-stone-100` / `border-stone-200`). Sin sombras: cero `shadow-*` salvo el que traigan los componentes de Nuxt UI.
- **Radios generosos:** `rounded-2xl` en imágenes y contenedores, `rounded-xl` en items chicos, `rounded-full` en botones. Nada de esquinas rectas.
- **Inputs con `border-b`**, no cajas: el patrón del pcm-template (`border-b-2 border-stone-200 focus:border-primary-500`). Los textarea sí son cajas con `border` + `rounded-xl`.
- **Aire:** `gap-*` y `py-*` amplios. Las secciones del index separadas por `gap-16`, el contenido interno por `gap-6`/`gap-8`.
- **Tipografía Outfit** (ya en `main.css`). Títulos con `font-semibold tracking-tight`; nada de `font-bold`. Los labels y la metadata en `text-xs uppercase tracking-wide`.
- **Números tabulares** (`tabular-nums`) en puntaje y fechas.
- **Transiciones:** solo `transition-colors` y `transition-transform`, duración por default. La única excepción es el `duration-500` del zoom de la card. Nada de animaciones de entrada.
- **Estados vacíos son contenido, no error:** copy en rioplatense, tono tranquilo.
- **Responsive:** mobile-first. La grilla es `sm:grid-cols-2 lg:grid-cols-3`; la ficha es una columna `max-w-2xl` siempre.
- **Accesibilidad:** todo botón sin texto visible lleva `aria-label`; los errores llevan `role="alert"`; las imágenes llevan `alt` real (título o temática, nunca vacío ni "imagen").

## Estructura de archivos

```
SBI/
├── .env                          # gitignored, credenciales de Registro
├── .env.example
├── .gitignore
├── CLAUDE.md                     # doc del proyecto
├── nuxt.config.ts
├── package.json
├── supabase/
│   └── schema.sql                # migración idempotente (referencia; se aplica vía MCP)
└── app/
    ├── app.vue
    ├── app.config.ts
    ├── assets/css/main.css
    ├── utils/slugify.js
    ├── composables/
    │   ├── useAuth.js            # login / logout / user
    │   ├── useIdeas.js           # CRUD de ideas_tematicas
    │   └── useStorage.js         # upload / remove en bucket `ideas`
    ├── components/
    │   ├── ui/EmptyState.vue
    │   ├── idea/Card.vue         # card de la grilla
    │   ├── idea/AssetList.vue    # render de assets (links + files)
    │   ├── idea/Evaluacion.vue   # puntaje + 3 textos, oculta vacíos
    │   ├── idea/NuevaTematica.vue# modal de creación (fase 1)
    │   └── idea/Form.vue         # slideover de edición (fase 2)
    ├── layouts/
    │   ├── default.vue           # header público + sesión
    │   └── auth.vue              # centrado, para login
    └── pages/
        ├── index.vue
        ├── login.vue
        └── idea/[slug].vue
```

**Responsabilidades.** `useIdeas.js` es la única puerta a la tabla; ningún componente llama a `supabase.from('ideas_tematicas')` directo. `useStorage.js` es la única puerta al bucket. `Form.vue` compone el estado del formulario pero delega toda persistencia a los composables. `Card.vue` y `Evaluacion.vue` son presentacionales puros (props in, nada de fetch).

---

### Task 1: Scaffold del proyecto + config

Levanta un Nuxt 4 vacío que corre en local, con Tailwind v4, Nuxt UI y Supabase configurados apuntando a Registro. Deliverable testeable: `pnpm dev` sirve una home que dice el título y no tira errores.

**Files:**
- Create: `package.json`
- Create: `nuxt.config.ts`
- Create: `.env.example`
- Create: `.env`
- Create: `.gitignore`
- Create: `app/app.vue`
- Create: `app/app.config.ts`
- Create: `app/assets/css/main.css`
- Create: `app/pages/index.vue` (placeholder, se completa en Task 6)

**Interfaces:**
- Consumes: nada (primera tarea).
- Produces: proyecto Nuxt funcional. `useSupabaseClient()` y `useSupabaseUser()` disponibles globalmente (los inyecta `@nuxtjs/supabase`). Paleta Nuxt UI con `primary` y `neutral: 'stone'`.

- [ ] **Step 1: Crear `package.json`**

```json
{
  "name": "stupid-big-ideas",
  "type": "module",
  "private": true,
  "scripts": {
    "build": "nuxt build",
    "dev": "nuxt dev",
    "generate": "nuxt generate",
    "preview": "nuxt preview",
    "postinstall": "nuxt prepare"
  },
  "dependencies": {
    "@nuxt/fonts": "^0.14.0",
    "@nuxt/ui": "^4.10.0",
    "@nuxtjs/supabase": "^2.0.9",
    "nuxt": "^4.5.1",
    "tailwindcss": "^4.3.3",
    "vue": "^3.5.40",
    "vue-router": "^5.2.0"
  }
}
```

- [ ] **Step 2: Crear `.gitignore`**

```
node_modules
.nuxt
.output
.env
dist
.DS_Store
```

- [ ] **Step 3: Crear `.env.example`**

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_KEY=eyJ...anon-key
```

- [ ] **Step 4: Crear `.env` con las credenciales reales de Registro**

Pedirle a Lio el `SUPABASE_URL` y la anon key del proyecto **Registro** (Supabase Dashboard → Project Settings → API), o copiarlas del `.env` de la app de finanzas que ya usa esa DB. Mismo formato que `.env.example`.

No inventar valores: sin credenciales válidas la Task 5 en adelante no se puede verificar.

- [ ] **Step 5: Crear `nuxt.config.ts`**

Diferencia clave contra el pcm-template: acá el index es **público**, así que `redirectOptions.exclude` cubre `/`, `/idea/**` y `/login`. Sin eso, `@nuxtjs/supabase` redirige a login a los visitantes sin sesión.

```ts
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  ssr: true,

  modules: [
    '@nuxt/ui',
    '@nuxt/fonts',
    '@nuxtjs/supabase',
  ],

  app: {
    head: {
      htmlAttrs: { lang: 'es' },
      title: 'Stupid Big Ideas',
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'El registro de las ideas creativas de Motix' },
      ],
    },
  },

  css: ['~/assets/css/main.css'],
  components: [{ path: '~/components', pathPrefix: false }],
  imports: { dirs: ['composables/**'] },

  ui: { colorMode: false },

  supabase: {
    redirect: true,
    redirectOptions: {
      login: '/login',
      callback: '/confirm',
      exclude: ['/', '/idea/**', '/login'],
      saveRedirectToCookie: false,
    },
    cookieOptions: {
      maxAge: 60 * 60 * 24 * 30,
      sameSite: 'lax',
    },
    types: '',
  },

  fonts: {
    families: [
      { name: 'Outfit', provider: 'google', weights: [400, 500, 600, 700] },
    ],
  },

  typescript: {
    typeCheck: false,
    strict: false,
  },
})
```

- [ ] **Step 6: Crear `app/assets/css/main.css`**

```css
@import "tailwindcss";
@import "@nuxt/ui";

@theme {
  --font-sans: 'Outfit', system-ui, sans-serif;

  --breakpoint-sm: 480px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 1080px;
  --breakpoint-xl: 1280px;
  --breakpoint-xxl: 1440px;
}

button,
a,
[role="button"] {
  cursor: pointer;
}
```

- [ ] **Step 7: Crear `app/app.config.ts`**

```ts
export default defineAppConfig({
  ui: {
    colors: {
      primary: 'violet',
      success: 'green',
      warning: 'yellow',
      error: 'red',
      neutral: 'stone',
    },
  },
})
```

- [ ] **Step 8: Crear `app/app.vue`**

```vue
<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>
```

- [ ] **Step 9: Crear `app/pages/index.vue` placeholder**

```vue
<template>
  <h1 class="text-3xl text-stone-900 font-semibold tracking-tight">
    Stupid Big Ideas
  </h1>
</template>
```

- [ ] **Step 10: Instalar y correr**

```bash
cd /Users/lio/Desktop/Motix/Creatividad/SBI
pnpm install
pnpm dev
```

Verificar: `http://localhost:3000` muestra "Stupid Big Ideas", la consola no tiene errores de Tailwind ni de módulos, y **no** redirige a `/login`. Si redirige, revisar `redirectOptions.exclude`.

- [ ] **Step 11: Commit** — OMITIDO (ver Global Constraints: sin git en este proyecto).

---

### Task 2: Migración de la DB

Crea la tabla, los grants, las policies y el bucket en Registro. Deliverable testeable: queries de verificación que confirman que `anon` solo ve las completas.

**Files:**
- Create: `supabase/schema.sql` (copia de referencia en el repo)
- Aplica vía MCP `supabase-registro` → `apply_migration`

**Interfaces:**
- Consumes: `is_motix_member()` y `user_profiles` (ya existen en Registro).
- Produces: tabla `public.ideas_tematicas` con las columnas del spec; bucket `ideas` público. Contrato de lectura para `anon`: solo filas con `titulo is not null`.

- [ ] **Step 1: Verificar que `is_motix_member()` existe y es SECURITY DEFINER**

Vía MCP `supabase-registro` → `execute_sql`:

```sql
select p.proname, p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where p.proname = 'is_motix_member' and n.nspname = 'public';
```

Esperado: una fila, `security_definer = true`. Si `security_definer` es `false`, la función lee `user_profiles` con los permisos del caller y las policies de `authenticated` pueden fallar — avisarle a Lio antes de seguir, no arreglar `is_motix_member()` por cuenta propia (la usan las tablas de finanzas).

La policy de `anon` de este plan **no** llama a `is_motix_member()`, así que la lectura pública no depende de esto.

- [ ] **Step 2: Escribir `supabase/schema.sql`**

```sql
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
```

- [ ] **Step 3: Pedir confirmación a Lio antes de aplicar**

Es una escritura contra producción (la DB Registro tiene datos reales de finanzas). Anunciar: "voy a aplicar la migración `ideas_tematicas` en Registro vía MCP" y esperar el OK.

- [ ] **Step 4: Aplicar la migración**

MCP `supabase-registro` → `apply_migration`, name: `ideas_tematicas_v1`, query: el contenido completo de `supabase/schema.sql`.

- [ ] **Step 5: Verificar estructura y policies**

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'ideas_tematicas'
order by ordinal_position;

select policyname, cmd, roles::text
from pg_policies
where schemaname = 'public' and tablename = 'ideas_tematicas'
order by cmd, policyname;
```

Esperado: 16 columnas; 5 policies (`ideas_select_anon` para `{anon}`, y select/insert/update/delete `_motix` para `{authenticated}`).

- [ ] **Step 6: Verificar el filtro de `anon` con una fila de prueba**

Insertar una en curso y una completa como `service_role`, después leer como `anon`:

```sql
insert into public.ideas_tematicas (slug, tematica, titulo, created_by)
values
  ('prueba-en-curso', 'Prueba en curso', null, (select id from auth.users limit 1)),
  ('prueba-completa', 'Prueba completa', 'Idea ganadora', (select id from auth.users limit 1));

set local role anon;
select slug from public.ideas_tematicas;
reset role;
```

Esperado: la lectura como `anon` devuelve **solo** `prueba-completa`.

- [ ] **Step 7: Limpiar las filas de prueba**

```sql
delete from public.ideas_tematicas where slug in ('prueba-en-curso', 'prueba-completa');
```

- [ ] **Step 8: Commit** — OMITIDO (sin git).

---

### Task 3: `slugify` + `useStorage`

Las dos utilidades de base, sin UI. Deliverable testeable: un self-check de `slugify` que corre en node y un upload real al bucket.

**Files:**
- Create: `app/utils/slugify.js`
- Create: `app/composables/useStorage.js`
- Test: `app/utils/slugify.test.mjs`

**Interfaces:**
- Consumes: bucket `ideas` (Task 2).
- Produces:
  - `slugify(text) → string` — minúsculas, sin acentos, guiones; `''` si no queda nada usable.
  - `useStorage()` → `{ uploadFile(file, slug) → { publicUrl, path }, removeFiles(paths) → void }`.
    `removeFiles` acepta un array y no hace nada si viene vacío.

- [ ] **Step 1: Escribir el self-check de `slugify` (falla primero)**

Sin framework de test — un archivo con `assert` que corre con node, según las Global Constraints (nada de frameworks no pedidos).

Crear `app/utils/slugify.test.mjs`:

```js
import assert from 'node:assert/strict'
import { slugify } from './slugify.js'

assert.equal(slugify('Nostalgia'), 'nostalgia')
assert.equal(slugify('Días de Diseño'), 'dias-de-diseno')
assert.equal(slugify('  Espacios   raros  '), 'espacios-raros')
assert.equal(slugify('¿Qué pasa?'), 'que-pasa')
assert.equal(slugify('El futuro / el pasado'), 'el-futuro-el-pasado')
assert.equal(slugify('100% Analógico'), '100-analogico')
assert.equal(slugify('---'), '')
assert.equal(slugify(''), '')
assert.equal(slugify(null), '')

console.log('slugify OK')
```

- [ ] **Step 2: Correr el test y verificar que falla**

```bash
cd /Users/lio/Desktop/Motix/Creatividad/SBI
node app/utils/slugify.test.mjs
```

Esperado: FALLA con `ERR_MODULE_NOT_FOUND` (`slugify.js` no existe todavía).

- [ ] **Step 3: Implementar `app/utils/slugify.js`**

```js
export const slugify = (text) =>
  (text || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
```

- [ ] **Step 4: Correr el test y verificar que pasa**

```bash
node app/utils/slugify.test.mjs
```

Esperado: imprime `slugify OK`, exit code 0.

- [ ] **Step 5: Implementar `app/composables/useStorage.js`**

```js
const BUCKET = 'ideas'

export const useStorage = () => {
  const supabase = useSupabaseClient()

  const uploadFile = async (file, slug) => {
    const extension = (file.name.split('.').pop() || 'bin').toLowerCase()
    const timestamp = Date.now()
    const random = Math.random().toString(36).slice(2, 8)
    const path = `${slug}/${timestamp}-${random}.${extension}`

    const { error } = await supabase.storage
      .from(BUCKET)
      .upload(path, file, {
        contentType: file.type || 'application/octet-stream',
        cacheControl: '31536000',
        upsert: false,
      })

    if (error) throw error

    const { data: { publicUrl } } = supabase.storage.from(BUCKET).getPublicUrl(path)

    return { publicUrl, path }
  }

  const removeFiles = async (paths) => {
    const clean = (paths || []).filter(Boolean)
    if (!clean.length) return
    const { error } = await supabase.storage.from(BUCKET).remove(clean)
    if (error) throw error
  }

  return { uploadFile, removeFiles }
}
```

- [ ] **Step 6: Commit** — OMITIDO (sin git).

---

### Task 4: `useAuth` + login

Login funcional contra Registro. Deliverable testeable: entrar con un usuario Motix real y quedar logueado.

**Files:**
- Create: `app/composables/useAuth.js`
- Create: `app/layouts/auth.vue`
- Create: `app/pages/login.vue`

**Interfaces:**
- Consumes: `@nuxtjs/supabase` (Task 1).
- Produces: `useAuth()` → `{ user, login(email, password) → { ok, message? }, logout() }`.
  `user` es el ref de `useSupabaseUser()`. `login` nunca throwea: devuelve `{ ok: false, message }`.

- [ ] **Step 1: Crear `app/composables/useAuth.js`**

Sin registro público: los usuarios ya existen en Registro.

```js
export const useAuth = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  const login = async (email, password) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) {
      const msg = (error.message || '').toLowerCase()
      const isNetwork = msg.includes('network') || msg.includes('fetch')
      return {
        ok: false,
        message: isNetwork ? 'Sin conexión, intentá de nuevo' : 'Email o contraseña incorrectos',
      }
    }
    return { ok: true }
  }

  const logout = async () => {
    await supabase.auth.signOut()
    await navigateTo('/')
  }

  return { user, login, logout }
}
```

Nota: `logout` va a `/` (no a `/login`) porque el index es público.

- [ ] **Step 2: Crear `app/layouts/auth.vue`**

```vue
<template>
  <main class="min-h-dvh flex items-center justify-center bg-stone-50 px-6">
    <slot />
  </main>
</template>
```

- [ ] **Step 3: Crear `app/pages/login.vue`**

```vue
<template>
  <div class="w-full max-w-sm flex flex-col gap-8">
    <div class="flex flex-col items-center gap-2 text-center">
      <div class="size-14 flex items-center justify-center bg-primary-100 rounded-2xl text-3xl">💡</div>
      <h1 class="text-2xl text-stone-900 font-semibold tracking-tight">Stupid Big Ideas</h1>
      <p class="text-sm text-stone-500">Entrá para anotar ideas</p>
    </div>

    <form class="w-full flex flex-col gap-5" @submit.prevent="onSubmit">
      <div class="flex flex-col gap-1.5">
        <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Email</label>
        <input
          v-model="email"
          type="email"
          placeholder="vos@motix.com"
          class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-2"
          autocomplete="email"
          :disabled="loading"
          required
        >
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Contraseña</label>
        <div class="flex items-center border-b-2 border-stone-200 focus-within:border-primary-500 transition-colors">
          <input
            v-model="password"
            :type="showPassword ? 'text' : 'password'"
            placeholder="••••••••"
            class="w-full flex-1 bg-transparent text-base text-stone-900 placeholder:text-stone-300 outline-none py-2"
            autocomplete="current-password"
            :disabled="loading"
            required
          >
          <button
            type="button"
            class="size-8 flex items-center justify-center text-stone-400 hover:text-stone-700 transition-colors"
            :aria-label="showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'"
            @click="showPassword = !showPassword"
          >
            <UIcon :name="showPassword ? 'i-lucide-eye-off' : 'i-lucide-eye'" class="size-4" />
          </button>
        </div>
      </div>

      <p
        v-if="errorMessage"
        class="bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 px-3 py-2"
        role="alert"
      >
        {{ errorMessage }}
      </p>

      <div class="flex items-center justify-center mt-2">
        <button
          type="submit"
          :disabled="!email || !password || loading"
          :class="[
            'flex items-center gap-1.5 bg-primary-500 hover:bg-primary-600 disabled:bg-stone-200 rounded-full text-sm text-white disabled:text-stone-400 font-semibold disabled:cursor-not-allowed transition-all px-5 py-2.5',
            loading ? 'opacity-70' : ''
          ]"
        >
          <UIcon
            :name="loading ? 'i-lucide-loader-circle' : 'i-lucide-log-in'"
            :class="['size-4', loading ? 'animate-spin' : '']"
          />
          <span>{{ loading ? 'Entrando…' : 'Entrar' }}</span>
        </button>
      </div>

      <NuxtLink to="/" class="text-sm text-stone-400 hover:text-stone-700 text-center transition-colors">
        Volver al archivo
      </NuxtLink>
    </form>
  </div>
</template>

<script setup>
definePageMeta({ layout: 'auth' })

const { login, user } = useAuth()
const router = useRouter()
const route = useRoute()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)
const errorMessage = ref('')

watchEffect(() => {
  if (user.value) {
    const redirectTo = route.query.redirect_to?.toString() || '/'
    router.replace(redirectTo)
  }
})

const onSubmit = async () => {
  errorMessage.value = ''
  loading.value = true

  const result = await login(email.value.trim(), password.value)

  loading.value = false

  if (!result.ok) {
    errorMessage.value = result.message
    return
  }

  const redirectTo = route.query.redirect_to?.toString() || '/'
  await router.replace(redirectTo)
}
</script>
```

- [ ] **Step 4: Verificar el login en local**

`pnpm dev` → `http://localhost:3000/login`.

1. Credenciales incorrectas → banner rojo "Email o contraseña incorrectos", sin redirect.
2. Credenciales de un usuario Motix real de Registro (pedírselas a Lio) → redirige a `/`.
3. Recargar `/` → sigue logueado (cookie de 30 días).

- [ ] **Step 5: Commit** — OMITIDO (sin git).

---

### Task 5: `useIdeas`

La única puerta a la tabla. Deliverable testeable: crear, leer, actualizar y borrar desde la consola del browser logueado.

**Files:**
- Create: `app/composables/useIdeas.js`

**Interfaces:**
- Consumes: `slugify` (Task 3), `useStorage()` (Task 3), tabla `ideas_tematicas` (Task 2).
- Produces: `useIdeas()` → objeto con:
  - `fetchAll() → Promise<Idea[]>` — ordenadas por `fecha desc`. Lo que devuelve depende de la sesión: `anon` recibe solo completas (lo filtra RLS, no el cliente).
  - `fetchBySlug(slug) → Promise<Idea|null>`
  - `create({ tematica, fecha }) → Promise<Idea>` — genera slug único, setea `created_by`.
  - `update(id, patch) → Promise<Idea>` — acepta cualquier subconjunto de campos editables.
  - `remove(idea) → Promise<void>` — borra la fila y después los archivos de Storage.
  - `enCurso(idea) → boolean` — helper de estado derivado.

  `Idea` = todas las columnas de la tabla (ver Task 2).

- [ ] **Step 1: Crear `app/composables/useIdeas.js`**

El slug se genera de `tematica` con reintento por sufijo numérico ante `23505`. No se regenera al editar: la URL es estable una vez publicada.

```js
const COLUMNS = 'id, slug, tematica, fecha, titulo, imagen_url, imagen_path, desarrollo, assets, puntaje, correcciones, destaques, oportunidades, created_by, created_at, updated_at'

const TEXT_FIELDS = ['titulo', 'desarrollo', 'correcciones', 'destaques', 'oportunidades']

export const useIdeas = () => {
  const supabase = useSupabaseClient()
  const { removeFiles } = useStorage()

  const enCurso = (idea) => !idea?.titulo

  const fetchAll = async () => {
    const { data, error } = await supabase
      .from('ideas_tematicas')
      .select(COLUMNS)
      .order('fecha', { ascending: false })
      .order('created_at', { ascending: false })

    if (error) throw error
    return data || []
  }

  const fetchBySlug = async (slug) => {
    const { data, error } = await supabase
      .from('ideas_tematicas')
      .select(COLUMNS)
      .eq('slug', slug)
      .maybeSingle()

    if (error) throw error
    return data
  }

  const create = async ({ tematica, fecha }) => {
    const clean = (tematica || '').trim()
    const base = slugify(clean)
    if (!base) throw new Error('La temática no genera una URL válida')

    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser?.id) throw new Error('Sin sesión activa')

    for (let attempt = 0; attempt < 5; attempt++) {
      const slug = attempt === 0 ? base : `${base}-${attempt + 1}`
      const { data, error } = await supabase
        .from('ideas_tematicas')
        .insert({
          slug,
          tematica: clean,
          fecha: fecha || new Date().toISOString().slice(0, 10),
          created_by: authUser.id,
        })
        .select(COLUMNS)
        .single()

      if (!error) return data
      if (error.code !== '23505') throw error
    }

    throw new Error('Ya existe una temática con ese nombre')
  }

  const update = async (id, patch) => {
    const clean = {}

    for (const field of TEXT_FIELDS) {
      if (field in patch) clean[field] = patch[field]?.trim() || null
    }
    if ('tematica' in patch) {
      const tematica = (patch.tematica || '').trim()
      if (!tematica) throw new Error('La temática no puede quedar vacía')
      clean.tematica = tematica
    }
    if ('fecha' in patch) clean.fecha = patch.fecha
    if ('puntaje' in patch) clean.puntaje = patch.puntaje ?? null
    if ('assets' in patch) clean.assets = patch.assets || []
    if ('imagen_url' in patch) clean.imagen_url = patch.imagen_url || null
    if ('imagen_path' in patch) clean.imagen_path = patch.imagen_path || null

    const { data, error } = await supabase
      .from('ideas_tematicas')
      .update(clean)
      .eq('id', id)
      .select(COLUMNS)
      .single()

    if (error) throw error
    return data
  }

  const remove = async (idea) => {
    const { error } = await supabase
      .from('ideas_tematicas')
      .delete()
      .eq('id', idea.id)

    if (error) throw error

    const paths = [
      idea.imagen_path,
      ...(idea.assets || []).filter((a) => a.tipo === 'file').map((a) => a.path),
    ]
    await removeFiles(paths)
  }

  return { fetchAll, fetchBySlug, create, update, remove, enCurso }
}
```

Decisión: `remove` borra la fila **antes** de los archivos. Si falla el borrado de Storage quedan huérfanos en el bucket, pero la UI queda consistente. El orden inverso dejaría una idea sin imagen si falla el delete de la fila — peor.

- [ ] **Step 2: Verificar el CRUD desde la consola del browser**

Con `pnpm dev` corriendo y sesión Motix activa, en la consola de `http://localhost:3000`:

```js
const { create, fetchAll, update, remove, fetchBySlug } = useIdeas()

const idea = await create({ tematica: 'Nostalgia', fecha: '2026-07-27' })
console.log('creada', idea.slug, 'en curso:', !idea.titulo)

await update(idea.id, { titulo: 'La máquina del tiempo', puntaje: 8 })
console.log('completa', (await fetchBySlug(idea.slug)).titulo)

console.log('total', (await fetchAll()).length)

await remove(idea)
console.log('borrada', await fetchBySlug(idea.slug))
```

Esperado: crea con `slug = 'nostalgia'` y `titulo` null; el update la completa; `fetchBySlug` post-remove devuelve `null`.

- [ ] **Step 3: Verificar el reintento de slug duplicado**

```js
const { create, remove } = useIdeas()
const a = await create({ tematica: 'Nostalgia' })
const b = await create({ tematica: 'Nostalgia' })
console.log(a.slug, b.slug)
await remove(a); await remove(b)
```

Esperado: `nostalgia nostalgia-2`.

- [ ] **Step 4: Commit** — OMITIDO (sin git).

---

### Task 6: Index público — dinámica, buscador y grilla

La home completa en modo lectura. Deliverable testeable: sin sesión se ven la dinámica y las ideas completas, y el buscador filtra.

**Files:**
- Create: `app/layouts/default.vue`
- Create: `app/components/ui/EmptyState.vue`
- Create: `app/components/idea/Card.vue`
- Modify: `app/pages/index.vue` (reemplaza el placeholder de Task 1)

**Interfaces:**
- Consumes: `useIdeas()` (Task 5), `useAuth()` (Task 4).
- Produces:
  - `<EmptyState :icon :title :description />`
  - `<IdeaCard :idea />` — presentacional, linkea a `/idea/{slug}`. Muestra badge "En curso" si `!idea.titulo`.
  - `default.vue` con header: título a la izquierda, y a la derecha "Entrar" o "Salir" según sesión.

- [ ] **Step 1: Crear `app/layouts/default.vue`**

```vue
<template>
  <div class="min-h-dvh bg-white">
    <header class="flex justify-between items-center sticky top-0 z-10 border-b border-stone-100 bg-white/90 backdrop-blur px-6 py-3">
      <NuxtLink to="/" class="text-sm text-stone-900 font-semibold tracking-tight">
        Stupid Big Ideas
      </NuxtLink>

      <button
        v-if="user"
        type="button"
        class="flex items-center gap-1.5 rounded-full text-sm text-stone-500 hover:text-stone-900 transition-colors px-2 py-1"
        aria-label="Cerrar sesión"
        @click="logout"
      >
        <UIcon name="i-lucide-log-out" class="size-4" />
        <span>Salir</span>
      </button>
      <NuxtLink
        v-else
        to="/login"
        class="text-sm text-stone-400 hover:text-stone-900 transition-colors px-2 py-1"
      >
        Entrar
      </NuxtLink>
    </header>

    <main class="w-full max-w-5xl mx-auto px-6 py-12">
      <slot />
    </main>
  </div>
</template>

<script setup>
const { user, logout } = useAuth()
</script>
```

- [ ] **Step 2: Crear `app/components/ui/EmptyState.vue`**

```vue
<template>
  <div class="flex flex-col items-center gap-2 border border-dashed border-stone-200 rounded-2xl text-center px-6 py-16">
    <UIcon :name="icon" class="size-8 text-stone-300" />
    <p class="text-base text-stone-700 font-medium">{{ title }}</p>
    <p v-if="description" class="text-sm text-stone-500">{{ description }}</p>
  </div>
</template>

<script setup>
defineProps({
  icon: { type: String, default: 'i-lucide-lightbulb' },
  title: { type: String, required: true },
  description: { type: String, default: '' },
})
</script>
```

- [ ] **Step 3: Crear `app/components/idea/Card.vue`**

```vue
<template>
  <NuxtLink
    :to="`/idea/${idea.slug}`"
    class="group flex flex-col gap-3"
  >
    <div class="aspect-4/3 overflow-hidden bg-stone-100 rounded-2xl">
      <img
        v-if="idea.imagen_url"
        :src="idea.imagen_url"
        :alt="idea.titulo || idea.tematica"
        class="size-full object-cover group-hover:scale-[1.03] transition-transform duration-500"
        loading="lazy"
      >
      <div v-else class="size-full flex items-center justify-center">
        <UIcon name="i-lucide-image-off" class="size-6 text-stone-300" />
      </div>
    </div>

    <div class="flex flex-col gap-1">
      <div class="flex items-center gap-2">
        <span class="text-xs text-stone-400 tracking-wide uppercase">{{ idea.tematica }}</span>
        <span
          v-if="!idea.titulo"
          class="bg-amber-50 rounded-full text-[10px] text-amber-700 font-medium tracking-wide uppercase px-2 py-0.5"
        >
          En curso
        </span>
      </div>
      <h3 class="text-lg text-stone-900 font-medium leading-snug group-hover:text-primary-600 transition-colors">
        {{ idea.titulo || 'Sin idea ganadora todavía' }}
      </h3>
      <span class="text-xs text-stone-400">{{ fechaLarga }}</span>
    </div>
  </NuxtLink>
</template>

<script setup>
const props = defineProps({
  idea: { type: Object, required: true },
})

const fechaLarga = computed(() =>
  new Date(`${props.idea.fecha}T12:00:00`).toLocaleDateString('es-AR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
)
</script>
```

Nota: la fecha se parsea con `T12:00:00` a propósito — `new Date('2026-07-27')` se interpreta como UTC medianoche y en Argentina (UTC-3) muestra el día anterior.

- [ ] **Step 4: Reemplazar `app/pages/index.vue`**

Los 5 pasos son un array local, no datos de DB: es copy fijo.

```vue
<template>
  <div class="flex flex-col gap-16">
    <section class="flex flex-col gap-6">
      <div class="flex flex-col gap-3">
        <h1 class="text-4xl md:text-5xl text-stone-900 font-semibold tracking-tight">
          Stupid Big Ideas
        </h1>
        <p class="max-w-xl text-base text-stone-500 leading-relaxed">
          El registro de las ideas creativas de Motix. Cada semana elegimos una temática,
          pensamos por separado y volvemos a la mesa a elegir una.
        </p>
      </div>

      <ol class="max-w-2xl flex flex-col gap-1.5 border-l border-stone-200 pl-5">
        <li
          v-for="(paso, i) in pasos"
          :key="paso.titulo"
          class="flex gap-2 text-sm text-stone-500"
        >
          <span class="text-stone-300 font-medium tabular-nums">{{ i + 1 }}</span>
          <span><strong class="text-stone-700 font-medium">{{ paso.titulo }}.</strong> {{ paso.detalle }}</span>
        </li>
      </ol>
    </section>

    <section class="flex flex-col gap-6">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div class="w-full max-w-xs flex items-center gap-2 border-b border-stone-200 focus-within:border-primary-500 transition-colors">
          <UIcon name="i-lucide-search" class="size-4 text-stone-400" />
          <input
            v-model="query"
            type="search"
            placeholder="Buscar una idea…"
            class="w-full flex-1 bg-transparent text-sm text-stone-900 placeholder:text-stone-300 outline-none py-2"
            aria-label="Buscar ideas"
          >
        </div>

        <IdeaNuevaTematica v-if="user" @created="onCreated" />
      </div>

      <p
        v-if="errorMessage"
        class="bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 px-3 py-2"
        role="alert"
      >
        {{ errorMessage }}
      </p>

      <div v-if="pending" class="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
        <div v-for="n in 3" :key="n" class="flex flex-col gap-3">
          <USkeleton class="aspect-4/3 w-full rounded-2xl" />
          <USkeleton class="h-4 w-24" />
          <USkeleton class="h-5 w-full" />
        </div>
      </div>

      <EmptyState
        v-else-if="!ideas.length"
        title="Todavía no hay ideas"
        description="Cuando cargues la primera temática va a aparecer acá."
      />

      <EmptyState
        v-else-if="!filtradas.length"
        icon="i-lucide-search-x"
        title="Sin resultados"
        :description="`No encontramos nada para “${query}”.`"
      />

      <div v-else class="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
        <IdeaCard v-for="idea in filtradas" :key="idea.id" :idea="idea" />
      </div>
    </section>
  </div>
</template>

<script setup>
const { user } = useAuth()
const { fetchAll } = useIdeas()

const pasos = [
  { titulo: 'Propuesta de temática', detalle: 'Elegimos una y la anotamos acá.' },
  { titulo: 'Idear', detalle: 'Cada uno por su lado: observaciones, insights, referencias, TikToks, opiniones.' },
  { titulo: 'Desarrollo', detalle: 'Agrupamos todo en ~4 ideas, cada uno expone, debatimos y elegimos una.' },
  { titulo: 'Evaluación', detalle: 'Puntaje, correcciones, destaques y oportunidades.' },
  { titulo: 'De nuevo', detalle: 'Elegimos otra temática y arrancamos otra vez.' },
]

const query = ref('')
const errorMessage = ref('')

const { data: ideas, pending, refresh } = await useAsyncData(
  'ideas',
  () => fetchAll(),
  { default: () => [], watch: [user] }
)

const filtradas = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return ideas.value
  return ideas.value.filter((idea) =>
    [idea.tematica, idea.titulo, idea.desarrollo]
      .filter(Boolean)
      .some((field) => field.toLowerCase().includes(q))
  )
})

const onCreated = async (idea) => {
  errorMessage.value = ''
  await refresh()
  await navigateTo(`/idea/${idea.slug}`)
}
</script>
```

`watch: [user]` es necesario: al loguearse, RLS pasa a devolver también las en curso, así que hay que refetchear.

- [ ] **Step 5: Crear un stub de `app/components/idea/NuevaTematica.vue`**

El index lo referencia; la implementación real va en Task 8. Stub para que compile y se pueda verificar la vista pública ya:

```vue
<template>
  <span />
</template>

<script setup>
defineEmits(['created'])
</script>
```

- [ ] **Step 6: Verificar el index sin sesión**

`pnpm dev`, ventana privada (sin sesión), `http://localhost:3000`:

1. Se ven el título, el copy y los 5 pasos. No redirige a login.
2. Con la tabla vacía → EmptyState "Todavía no hay ideas".
3. Cargar 2-3 filas completas vía MCP `execute_sql` (con `titulo`, `fecha` distintas y una con `imagen_url` de placeholder) y recargar → aparecen en la grilla, ordenadas por fecha desc.
4. Buscar una palabra del título → filtra. Buscar `zzz` → EmptyState "Sin resultados".
5. Insertar una fila **sin** `titulo` → **no** aparece sin sesión.
6. Header muestra "Entrar".

- [ ] **Step 7: Verificar el index con sesión**

Logueado como Motix: la fila sin `titulo` **sí** aparece, con el badge "En curso". Header muestra "Salir".

- [ ] **Step 8: Limpiar las filas de prueba**

```sql
delete from public.ideas_tematicas where slug like 'prueba-%';
```

- [ ] **Step 9: Commit** — OMITIDO (sin git).

---

### Task 7: Ficha de la idea

La vista de detalle, en modo lectura. Deliverable testeable: la ficha renderiza todo lo cargado, oculta lo vacío, y da 404 si no existe.

**Files:**
- Create: `app/components/idea/AssetList.vue`
- Create: `app/components/idea/Evaluacion.vue`
- Create: `app/pages/idea/[slug].vue`

**Interfaces:**
- Consumes: `useIdeas()` (Task 5), `useAuth()` (Task 4).
- Produces:
  - `<IdeaAssetList :assets />` — no renderiza nada si el array está vacío.
  - `<IdeaEvaluacion :idea />` — no renderiza nada si `puntaje` y los 3 textos están todos vacíos.

- [ ] **Step 1: Crear `app/components/idea/AssetList.vue`**

```vue
<template>
  <section v-if="assets.length" class="flex flex-col gap-3">
    <h2 class="text-xs text-stone-400 font-medium tracking-wide uppercase">Assets</h2>
    <ul class="flex flex-col gap-2">
      <li v-for="(asset, i) in assets" :key="`${asset.url}-${i}`">
        <a
          :href="asset.url"
          target="_blank"
          rel="noopener noreferrer"
          class="group flex items-center gap-2.5 border border-stone-200 hover:border-stone-300 rounded-xl transition-colors px-3 py-2.5"
        >
          <UIcon
            :name="asset.tipo === 'file' ? 'i-lucide-paperclip' : 'i-lucide-link'"
            class="size-4 shrink-0 text-stone-400"
          />
          <span class="flex-1 text-sm text-stone-700 group-hover:text-stone-900 truncate transition-colors">
            {{ etiqueta(asset) }}
          </span>
          <UIcon name="i-lucide-arrow-up-right" class="size-3.5 shrink-0 text-stone-300" />
        </a>
      </li>
    </ul>
  </section>
</template>

<script setup>
const props = defineProps({
  assets: { type: Array, default: () => [] },
})

const etiqueta = (asset) => {
  if (asset.label) return asset.label
  try {
    return new URL(asset.url).hostname.replace(/^www\./, '')
  } catch {
    return asset.url
  }
}

const assets = computed(() => (props.assets || []).filter((a) => a?.url))
</script>
```

- [ ] **Step 2: Crear `app/components/idea/Evaluacion.vue`**

```vue
<template>
  <section v-if="tieneAlgo" class="flex flex-col gap-5 border-t border-stone-100 pt-8">
    <div class="flex items-center gap-3">
      <h2 class="text-xs text-stone-400 font-medium tracking-wide uppercase">Evaluación</h2>
      <div v-if="idea.puntaje" class="flex items-baseline gap-0.5">
        <span class="text-2xl text-stone-900 font-semibold tabular-nums">{{ idea.puntaje }}</span>
        <span class="text-sm text-stone-400">/10</span>
      </div>
    </div>

    <dl class="grid gap-5 sm:grid-cols-3">
      <div v-for="campo in camposCargados" :key="campo.key" class="flex flex-col gap-1.5">
        <dt class="text-xs text-stone-400 font-medium tracking-wide uppercase">{{ campo.label }}</dt>
        <dd class="text-sm text-stone-700 leading-relaxed whitespace-pre-line">{{ campo.value }}</dd>
      </div>
    </dl>
  </section>
</template>

<script setup>
const props = defineProps({
  idea: { type: Object, required: true },
})

const CAMPOS = [
  { key: 'correcciones', label: 'Correcciones' },
  { key: 'destaques', label: 'Destaques' },
  { key: 'oportunidades', label: 'Oportunidades' },
]

const camposCargados = computed(() =>
  CAMPOS
    .map((campo) => ({ ...campo, value: props.idea[campo.key] }))
    .filter((campo) => campo.value)
)

const tieneAlgo = computed(() => Boolean(props.idea.puntaje) || camposCargados.value.length > 0)
</script>
```

- [ ] **Step 3: Crear `app/pages/idea/[slug].vue`**

`IdeaForm` se referencia acá pero se implementa en Task 8; hasta entonces el botón Editar no abre nada.

```vue
<template>
  <article v-if="idea" class="max-w-2xl mx-auto flex flex-col gap-8">
    <NuxtLink
      to="/"
      class="flex items-center gap-1.5 w-fit text-sm text-stone-400 hover:text-stone-900 transition-colors"
    >
      <UIcon name="i-lucide-arrow-left" class="size-4" />
      <span>Volver</span>
    </NuxtLink>

    <div
      v-if="idea.imagen_url"
      class="overflow-hidden bg-stone-100 rounded-2xl"
    >
      <img :src="idea.imagen_url" :alt="idea.titulo || idea.tematica" class="w-full object-cover">
    </div>

    <header class="flex flex-col gap-3">
      <div class="flex flex-wrap items-center gap-2">
        <span class="text-xs text-stone-400 tracking-wide uppercase">{{ idea.tematica }}</span>
        <span class="text-stone-200">·</span>
        <span class="text-xs text-stone-400">{{ fechaLarga }}</span>
        <span
          v-if="!idea.titulo"
          class="bg-amber-50 rounded-full text-[10px] text-amber-700 font-medium tracking-wide uppercase px-2 py-0.5"
        >
          En curso
        </span>
      </div>

      <h1 class="text-3xl md:text-4xl text-stone-900 font-semibold tracking-tight leading-tight">
        {{ idea.titulo || 'Sin idea ganadora todavía' }}
      </h1>

      <div v-if="user" class="flex items-center gap-2 mt-1">
        <IdeaForm :idea="idea" @saved="onSaved" />
        <button
          type="button"
          class="flex items-center gap-1.5 rounded-full text-sm text-stone-400 hover:text-red-600 transition-colors px-2 py-1"
          @click="onDelete"
        >
          <UIcon name="i-lucide-trash-2" class="size-4" />
          <span>Borrar</span>
        </button>
      </div>
    </header>

    <p
      v-if="errorMessage"
      class="bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 px-3 py-2"
      role="alert"
    >
      {{ errorMessage }}
    </p>

    <section v-if="idea.desarrollo" class="flex flex-col gap-3">
      <h2 class="text-xs text-stone-400 font-medium tracking-wide uppercase">Desarrollo</h2>
      <div class="text-base text-stone-700 leading-relaxed whitespace-pre-line">
        {{ idea.desarrollo }}
      </div>
    </section>

    <IdeaAssetList :assets="idea.assets" />

    <IdeaEvaluacion :idea="idea" />
  </article>
</template>

<script setup>
const route = useRoute()
const { user } = useAuth()
const { fetchBySlug, remove } = useIdeas()

const errorMessage = ref('')

const { data: idea, refresh } = await useAsyncData(
  () => `idea-${route.params.slug}`,
  () => fetchBySlug(route.params.slug),
  { watch: [user] }
)

if (!idea.value) {
  throw createError({ statusCode: 404, statusMessage: 'Idea no encontrada', fatal: true })
}

useHead(() => ({
  title: `${idea.value?.titulo || idea.value?.tematica} — Stupid Big Ideas`,
}))

const fechaLarga = computed(() =>
  new Date(`${idea.value.fecha}T12:00:00`).toLocaleDateString('es-AR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
)

const onSaved = async () => {
  errorMessage.value = ''
  await refresh()
}

const onDelete = async () => {
  if (!confirm('¿Borrar esta idea? No se puede deshacer.')) return

  errorMessage.value = ''
  try {
    await remove(idea.value)
    await navigateTo('/')
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos borrar la idea'
  }
}
</script>
```

- [ ] **Step 4: Crear un stub de `app/components/idea/Form.vue`**

Implementación real en Task 8.

```vue
<template>
  <span />
</template>

<script setup>
defineProps({
  idea: { type: Object, required: true },
})
defineEmits(['saved'])
</script>
```

- [ ] **Step 5: Verificar la ficha**

Insertar vía MCP una idea completa (título, desarrollo multi-línea, `puntaje` 8, los 3 textos, `assets` con un link y un file) y una mínima (solo `tematica` + `titulo`).

1. `/idea/<slug-completa>` → todo renderiza; el desarrollo respeta los saltos de línea; los assets linkean y abren en pestaña nueva.
2. `/idea/<slug-minima>` → **no** aparecen los bloques Desarrollo, Assets ni Evaluación.
3. `/idea/no-existe` → 404.
4. Sin sesión, la URL de una idea en curso → 404 (RLS no la devuelve a `anon`).
5. El título del tab cambia según la idea.

- [ ] **Step 6: Verificar el borrado**

Logueado, en una idea de prueba: botón Borrar → confirmar → vuelve a `/` y desaparece de la grilla.

- [ ] **Step 7: Limpiar filas de prueba**

```sql
delete from public.ideas_tematicas where slug like 'prueba-%';
```

- [ ] **Step 8: Commit** — OMITIDO (sin git).

---

### Task 8: Crear temática + editar idea

Cierra el CRUD: el modal de creación (fase 1) y el slideover de edición (fase 2). Reemplaza los dos stubs. Deliverable testeable: el ciclo completo de la dinámica hecho desde la UI.

**Files:**
- Modify: `app/components/idea/NuevaTematica.vue` (reemplaza el stub de Task 6)
- Modify: `app/components/idea/Form.vue` (reemplaza el stub de Task 7)

**Interfaces:**
- Consumes: `useIdeas()` (Task 5), `useStorage()` (Task 3).
- Produces:
  - `<IdeaNuevaTematica @created="idea => …" />` — emite la idea creada.
  - `<IdeaForm :idea @saved="() => …" />` — emite después de persistir.

- [ ] **Step 1: Implementar `app/components/idea/NuevaTematica.vue`**

Solo temática + fecha: en el paso 1 de la dinámica no hay nada más que anotar.

```vue
<template>
  <div>
    <button
      type="button"
      class="flex items-center gap-1.5 bg-stone-900 hover:bg-stone-700 rounded-full text-sm text-white font-medium transition-colors px-4 py-2"
      @click="open = true"
    >
      <UIcon name="i-lucide-plus" class="size-4" />
      <span>Nueva temática</span>
    </button>

    <UModal v-model:open="open" title="Nueva temática">
      <template #body>
        <form class="flex flex-col gap-5" @submit.prevent="onSubmit">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Temática</label>
            <input
              v-model="tematica"
              type="text"
              placeholder="Nostalgia"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-2"
              :disabled="loading"
              required
              autofocus
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Fecha</label>
            <input
              v-model="fecha"
              type="date"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 outline-none transition-colors py-2"
              :disabled="loading"
              required
            >
          </div>

          <p
            v-if="errorMessage"
            class="bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 px-3 py-2"
            role="alert"
          >
            {{ errorMessage }}
          </p>

          <div class="flex items-center justify-end gap-2">
            <button
              type="button"
              class="rounded-full text-sm text-stone-500 hover:text-stone-900 transition-colors px-3 py-2"
              :disabled="loading"
              @click="open = false"
            >
              Cancelar
            </button>
            <button
              type="submit"
              :disabled="!tematica.trim() || loading"
              class="flex items-center gap-1.5 bg-primary-500 hover:bg-primary-600 disabled:bg-stone-200 rounded-full text-sm text-white disabled:text-stone-400 font-semibold disabled:cursor-not-allowed transition-all px-4 py-2"
            >
              <UIcon
                :name="loading ? 'i-lucide-loader-circle' : 'i-lucide-check'"
                :class="['size-4', loading ? 'animate-spin' : '']"
              />
              <span>{{ loading ? 'Creando…' : 'Crear' }}</span>
            </button>
          </div>
        </form>
      </template>
    </UModal>
  </div>
</template>

<script setup>
const emit = defineEmits(['created'])

const { create } = useIdeas()

const open = ref(false)
const tematica = ref('')
const fecha = ref(new Date().toISOString().slice(0, 10))
const loading = ref(false)
const errorMessage = ref('')

const onSubmit = async () => {
  errorMessage.value = ''
  loading.value = true

  try {
    const idea = await create({ tematica: tematica.value, fecha: fecha.value })
    open.value = false
    tematica.value = ''
    emit('created', idea)
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos crear la temática'
  } finally {
    loading.value = false
  }
}
</script>
```

- [ ] **Step 2: Implementar `app/components/idea/Form.vue`**

Todos los campos de la fase 2. Los uploads van a Storage recién al guardar, no al elegir el archivo: así un formulario cancelado no deja basura en el bucket.

```vue
<template>
  <div>
    <button
      type="button"
      class="flex items-center gap-1.5 rounded-full text-sm text-stone-500 hover:text-stone-900 transition-colors px-2 py-1"
      @click="abrir"
    >
      <UIcon name="i-lucide-pencil" class="size-4" />
      <span>Editar</span>
    </button>

    <USlideover v-model:open="open" title="Editar idea">
      <template #body>
        <form class="flex flex-col gap-6" @submit.prevent="onSubmit">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Temática</label>
            <input
              v-model="form.tematica"
              type="text"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 outline-none transition-colors py-2"
              required
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Fecha</label>
            <input
              v-model="form.fecha"
              type="date"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 outline-none transition-colors py-2"
              required
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Título de la idea</label>
            <input
              v-model="form.titulo"
              type="text"
              placeholder="La máquina del tiempo"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-2"
            >
          </div>

          <div class="flex flex-col gap-2">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Imagen</label>
            <div v-if="imagenPreview" class="relative overflow-hidden bg-stone-100 rounded-xl">
              <img :src="imagenPreview" alt="" class="w-full aspect-4/3 object-cover">
              <button
                type="button"
                class="absolute top-2 right-2 size-8 flex items-center justify-center bg-white/90 hover:bg-white rounded-full text-stone-600 hover:text-red-600 transition-colors"
                aria-label="Quitar imagen"
                @click="quitarImagen"
              >
                <UIcon name="i-lucide-x" class="size-4" />
              </button>
            </div>
            <input
              type="file"
              accept="image/*"
              class="text-sm text-stone-500 file:mr-3 file:bg-stone-100 file:hover:bg-stone-200 file:border-0 file:rounded-full file:text-sm file:text-stone-700 file:font-medium file:transition-colors file:px-3 file:py-1.5"
              @change="onImagenChange"
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Desarrollo</label>
            <textarea
              v-model="form.desarrollo"
              rows="8"
              placeholder="El desarrollo profundo de la idea…"
              class="w-full bg-transparent border border-stone-200 focus:border-primary-500 rounded-xl text-sm text-stone-900 placeholder:text-stone-300 leading-relaxed outline-none transition-colors px-3 py-2.5"
            />
          </div>

          <div class="flex flex-col gap-3">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Assets extra</label>

            <ul v-if="form.assets.length" class="flex flex-col gap-2">
              <li
                v-for="(asset, i) in form.assets"
                :key="`${asset.url}-${i}`"
                class="flex items-center gap-2 border border-stone-200 rounded-xl px-3 py-2"
              >
                <UIcon
                  :name="asset.tipo === 'file' ? 'i-lucide-paperclip' : 'i-lucide-link'"
                  class="size-4 shrink-0 text-stone-400"
                />
                <span class="flex-1 text-sm text-stone-700 truncate">{{ asset.label || asset.url }}</span>
                <button
                  type="button"
                  class="size-7 flex items-center justify-center text-stone-400 hover:text-red-600 transition-colors"
                  aria-label="Quitar asset"
                  @click="quitarAsset(i)"
                >
                  <UIcon name="i-lucide-x" class="size-3.5" />
                </button>
              </li>
            </ul>

            <div class="flex flex-col gap-2 border border-dashed border-stone-200 rounded-xl p-3">
              <div class="flex gap-2">
                <input
                  v-model="nuevoLink"
                  type="url"
                  placeholder="https://tiktok.com/…"
                  class="w-full flex-1 bg-transparent border-b border-stone-200 focus:border-primary-500 text-sm text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-1.5"
                >
                <input
                  v-model="nuevoLabel"
                  type="text"
                  placeholder="Etiqueta"
                  class="w-28 bg-transparent border-b border-stone-200 focus:border-primary-500 text-sm text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-1.5"
                >
                <button
                  type="button"
                  :disabled="!nuevoLink.trim()"
                  class="shrink-0 size-8 flex items-center justify-center bg-stone-100 hover:bg-stone-200 disabled:bg-stone-50 rounded-full text-stone-600 disabled:text-stone-300 transition-colors"
                  aria-label="Agregar link"
                  @click="agregarLink"
                >
                  <UIcon name="i-lucide-plus" class="size-4" />
                </button>
              </div>

              <input
                type="file"
                multiple
                class="text-sm text-stone-500 file:mr-3 file:bg-stone-100 file:hover:bg-stone-200 file:border-0 file:rounded-full file:text-sm file:text-stone-700 file:font-medium file:transition-colors file:px-3 file:py-1.5"
                @change="onArchivosChange"
              >
            </div>
          </div>

          <div class="flex flex-col gap-5 border-t border-stone-100 pt-5">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Puntaje</label>
              <input
                v-model.number="form.puntaje"
                type="number"
                min="1"
                max="10"
                placeholder="8"
                class="w-20 bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 tabular-nums outline-none transition-colors py-2"
              >
            </div>

            <div v-for="campo in CAMPOS_EVAL" :key="campo.key" class="flex flex-col gap-1.5">
              <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">{{ campo.label }}</label>
              <textarea
                v-model="form[campo.key]"
                rows="3"
                class="w-full bg-transparent border border-stone-200 focus:border-primary-500 rounded-xl text-sm text-stone-900 leading-relaxed outline-none transition-colors px-3 py-2.5"
              />
            </div>
          </div>

          <p
            v-if="errorMessage"
            class="bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 px-3 py-2"
            role="alert"
          >
            {{ errorMessage }}
          </p>

          <div class="flex items-center justify-end gap-2 border-t border-stone-100 pt-5">
            <button
              type="button"
              class="rounded-full text-sm text-stone-500 hover:text-stone-900 transition-colors px-3 py-2"
              :disabled="loading"
              @click="open = false"
            >
              Cancelar
            </button>
            <button
              type="submit"
              :disabled="loading"
              class="flex items-center gap-1.5 bg-primary-500 hover:bg-primary-600 disabled:bg-stone-200 rounded-full text-sm text-white disabled:text-stone-400 font-semibold disabled:cursor-not-allowed transition-all px-4 py-2"
            >
              <UIcon
                :name="loading ? 'i-lucide-loader-circle' : 'i-lucide-check'"
                :class="['size-4', loading ? 'animate-spin' : '']"
              />
              <span>{{ loading ? 'Guardando…' : 'Guardar' }}</span>
            </button>
          </div>
        </form>
      </template>
    </USlideover>
  </div>
</template>

<script setup>
const props = defineProps({
  idea: { type: Object, required: true },
})
const emit = defineEmits(['saved'])

const { update } = useIdeas()
const { uploadFile, removeFiles } = useStorage()

const CAMPOS_EVAL = [
  { key: 'correcciones', label: 'Correcciones' },
  { key: 'destaques', label: 'Destaques' },
  { key: 'oportunidades', label: 'Oportunidades' },
]

const open = ref(false)
const loading = ref(false)
const errorMessage = ref('')

const form = ref({})
const imagenFile = ref(null)
const imagenPreview = ref('')
const imagenQuitada = ref(false)
const archivosNuevos = ref([])
const pathsAQuitar = ref([])
const nuevoLink = ref('')
const nuevoLabel = ref('')

const abrir = () => {
  form.value = {
    tematica: props.idea.tematica || '',
    fecha: props.idea.fecha || '',
    titulo: props.idea.titulo || '',
    desarrollo: props.idea.desarrollo || '',
    puntaje: props.idea.puntaje ?? null,
    correcciones: props.idea.correcciones || '',
    destaques: props.idea.destaques || '',
    oportunidades: props.idea.oportunidades || '',
    assets: [...(props.idea.assets || [])],
  }
  imagenFile.value = null
  imagenPreview.value = props.idea.imagen_url || ''
  imagenQuitada.value = false
  archivosNuevos.value = []
  pathsAQuitar.value = []
  nuevoLink.value = ''
  nuevoLabel.value = ''
  errorMessage.value = ''
  open.value = true
}

const onImagenChange = (event) => {
  const file = event.target.files?.[0]
  if (!file) return
  imagenFile.value = file
  imagenPreview.value = URL.createObjectURL(file)
  imagenQuitada.value = false
}

const quitarImagen = () => {
  imagenFile.value = null
  imagenPreview.value = ''
  imagenQuitada.value = true
}

const agregarLink = () => {
  const url = nuevoLink.value.trim()
  if (!url) return
  form.value.assets.push({ tipo: 'link', url, label: nuevoLabel.value.trim() || '' })
  nuevoLink.value = ''
  nuevoLabel.value = ''
}

const onArchivosChange = (event) => {
  const files = Array.from(event.target.files || [])
  for (const file of files) {
    archivosNuevos.value.push(file)
    form.value.assets.push({ tipo: 'file', url: '', path: '', label: file.name, pendiente: true })
  }
  event.target.value = ''
}

const quitarAsset = (index) => {
  const [asset] = form.value.assets.splice(index, 1)
  if (asset.tipo === 'file' && asset.pendiente) {
    const i = archivosNuevos.value.findIndex((f) => f.name === asset.label)
    if (i !== -1) archivosNuevos.value.splice(i, 1)
    return
  }
  if (asset.tipo === 'file' && asset.path) pathsAQuitar.value.push(asset.path)
}

const onSubmit = async () => {
  errorMessage.value = ''
  loading.value = true

  try {
    const patch = {
      tematica: form.value.tematica,
      fecha: form.value.fecha,
      titulo: form.value.titulo,
      desarrollo: form.value.desarrollo,
      puntaje: form.value.puntaje || null,
      correcciones: form.value.correcciones,
      destaques: form.value.destaques,
      oportunidades: form.value.oportunidades,
    }

    if (imagenFile.value) {
      const { publicUrl, path } = await uploadFile(imagenFile.value, props.idea.slug)
      patch.imagen_url = publicUrl
      patch.imagen_path = path
      if (props.idea.imagen_path) pathsAQuitar.value.push(props.idea.imagen_path)
    } else if (imagenQuitada.value) {
      patch.imagen_url = null
      patch.imagen_path = null
      if (props.idea.imagen_path) pathsAQuitar.value.push(props.idea.imagen_path)
    }

    const assets = []
    for (const asset of form.value.assets) {
      if (!asset.pendiente) {
        assets.push(asset)
        continue
      }
      const file = archivosNuevos.value.find((f) => f.name === asset.label)
      if (!file) continue
      const { publicUrl, path } = await uploadFile(file, props.idea.slug)
      assets.push({ tipo: 'file', url: publicUrl, path, label: asset.label })
    }
    patch.assets = assets

    await update(props.idea.id, patch)
    await removeFiles(pathsAQuitar.value)

    open.value = false
    emit('saved')
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos guardar los cambios'
  } finally {
    loading.value = false
  }
}
</script>
```

- [ ] **Step 3: Verificar el ciclo completo de la dinámica**

Logueado como Motix, en `pnpm dev`:

1. `/` → "Nueva temática" → temática "Nostalgia", fecha de hoy → Crear.
2. Redirige a `/idea/nostalgia`, con badge "En curso" y sin bloques de contenido.
3. "Editar" → cargar título, imagen, desarrollo multi-línea, un link con etiqueta, dos archivos, puntaje 8 y los tres textos → Guardar.
4. La ficha muestra todo; el slideover se cerró; los assets abren bien.
5. `/` → la card tiene la imagen y el título, y el badge "En curso" desapareció.
6. Ventana privada → la idea aparece en el index y la ficha se ve completa.

- [ ] **Step 4: Verificar el reemplazo y borrado de imagen**

1. Editar → subir otra imagen → Guardar → se ve la nueva.
2. En el bucket `ideas` (Supabase Dashboard → Storage) la vieja ya no está.
3. Editar → quitar la imagen con la X → Guardar → la ficha vuelve al estado sin imagen.

- [ ] **Step 5: Verificar el borrado de assets**

Editar → quitar un asset de tipo file → Guardar → desaparece de la ficha y el archivo ya no está en el bucket. Un asset de tipo link se quita sin tocar Storage.

- [ ] **Step 6: Verificar que cancelar no deja basura**

Abrir Editar, elegir una imagen nueva, Cancelar. Volver a abrir: el preview es la imagen original. En el bucket no hay archivos nuevos (los uploads ocurren en el submit).

- [ ] **Step 7: Verificar el aislamiento de permisos**

Con un usuario de Registro con rol `user` (no `motix`), si Lio tiene uno a mano: el index no muestra las en curso y guardar da error de permisos. Si no hay un usuario así, dejarlo anotado como verificación pendiente en vez de crear usuarios en producción por cuenta propia.

- [ ] **Step 8: Commit** — OMITIDO (sin git).

---

### Task 9: `CLAUDE.md` del proyecto

La doc del proyecto, con el "por qué" que no va como comentario en el código.

**Files:**
- Create: `CLAUDE.md`

**Interfaces:**
- Consumes: todo lo construido en Tasks 1-8.
- Produces: nada de código.

- [ ] **Step 1: Escribir `CLAUDE.md`**

Estructura obligatoria (Stack → Convenciones → Reglas vigentes → Arquitectura → Estado actual). Contenido a documentar, como mínimo:

- **Stack:** la tabla de versiones de las Global Constraints.
- **Convenciones:** UI en español rioplatense, código en inglés salvo dominio; cero comentarios en JS/Vue; composables como única puerta a DB y Storage.
- **Reglas vigentes** (el "por qué" que no va comentado):
  - Backend en la DB **Registro**, concepto `ideas`, reutilizando `is_motix_member()`. No tocar tablas de finanzas.
  - **Estado derivado, no almacenado:** `titulo is null` = en curso. Sin columna de estado.
  - **El index es público:** de ahí `redirectOptions.exclude` con `/` y `/idea/**`. Sacarlo rompe el acceso anónimo.
  - **La policy de `anon` no llama a `is_motix_member()`** a propósito: anon no debe tocar `user_profiles`.
  - **`assets` como jsonb** y no tabla: 2-5 items, siempre leídos con la idea. Costo: limpiar Storage a mano al quitar un file.
  - **El slug no se regenera al editar** el título: la URL es estable una vez publicada.
  - **Los uploads ocurren en el submit**, no al elegir el archivo: un form cancelado no deja basura en el bucket.
  - **`remove` borra la fila antes de los archivos:** si falla Storage quedan huérfanos, pero la UI queda consistente.
  - **`watch: [user]` en los `useAsyncData`:** al loguearse RLS devuelve más filas, hay que refetchear.
  - **Fechas parseadas con `T12:00:00`:** evita el corrimiento de un día por UTC en Argentina.
  - **Búsqueda en cliente:** a ~50 filas/año alcanza; FTS en Postgres recién pasadas varias centenas.
- **Arquitectura:** el árbol de archivos con la responsabilidad de cada pieza.
- **Estado actual:** qué está hecho y qué queda (git init y deploy pendientes de decisión de Lio).

- [ ] **Step 2: Verificación final integral**

1. `pnpm dev` sin errores ni warnings de Tailwind.
2. Recorrer el checklist de la sección "Verificación" del spec, de punta a punta.
3. Confirmar que ningún `.js`/`.vue` quedó con comentarios: `grep -rn "//" app --include=*.vue --include=*.js` (revisar los hits a mano; las URLs `https://` matchean y son válidas).

- [ ] **Step 3: Commit** — OMITIDO (sin git).

---

## Notas de ejecución

- **Sin git:** ninguna tarea commitea. Cuando Lio dé el OK, `git init` + primer commit va aparte.
- **Escrituras contra producción:** la Task 2 escribe en la DB Registro, que tiene datos reales. Pedir confirmación antes de aplicar la migración (Task 2, Step 3).
- **Los stubs de Tasks 6 y 7** (`NuevaTematica.vue` y `Form.vue`) existen para que cada tarea sea verificable de forma aislada. La Task 8 los reemplaza; si se ejecuta el plan de corrido, igual conviene crearlos para no romper la verificación intermedia.
- **Credenciales:** la Task 1 Step 4 necesita el `SUPABASE_URL` y la anon key de Registro. Sin eso, de la Task 5 en adelante no se verifica nada.
