# Stupid Big Ideas — Diseño

Fecha: 2026-07-27

Registro público de las ideas creativas de Motix. Cada semana el equipo elige una
temática, idea por separado, debate y elige una idea ganadora. Esta app guarda esa
ganadora: título, imagen, desarrollo, assets y evaluación.

El index es público y sin sesión. El CRUD requiere login de un miembro Motix.

## Stack

| Tecnología | Versión | Uso |
|---|---|---|
| Nuxt | ^4.5 | SSR, pages |
| Nuxt UI | ^4.6 | UButton, USlideover, UModal, USkeleton |
| Tailwind CSS | ^4.3 | CSS-first, `@theme` en `main.css`, sin config file |
| @nuxtjs/supabase | ^2.0 | Auth + DB + Storage |
| @nuxt/fonts | ^0.14 | Outfit |

pnpm. JS puro (sin TS en componentes/composables). Light mode único (`ui: { colorMode: false }`).
Deploy en Vercel.

**Backend: proyecto Supabase `Registro`** (el mismo de la app de finanzas de Motix).
Las ideas son un concepto nuevo dentro de esa DB, no un proyecto aparte. Se reutilizan
`user_profiles`, el enum `user_role` (`admin` / `motix` / `user`) y la función
`is_motix_member()` que ya existen. No se toca ninguna tabla de finanzas.

## La dinámica (lo que la app registra)

1. **Propuesta de temática** — se elige una temática y se anota en la app.
2. **Idear** — cada uno anota por su cuenta (fuera de la app): observaciones, insights,
   conceptos, ejecuciones. Se trae inspiración, fotos, videos, TikToks, opiniones.
3. **Desarrollo** — se agrupa todo en ~4 ideas, cada uno expone, se debate y se elige una.
   A la elegida, desarrollo más profundo y una mini ejecución (una imagen).
4. **Evaluación** — puntaje, correcciones, destaques, oportunidades.
5. **Nueva temática** — vuelve a empezar.

La app registra el paso 1 (al momento de elegir la temática) y los pasos 3–4 (al cierre
de la reunión). El paso 2 es deliberadamente fuera de la app.

## Datos

### Tabla `public.ideas_tematicas`

Una fila por semana/temática.

| campo | tipo | notas |
|---|---|---|
| `id` | uuid pk | `gen_random_uuid()` |
| `slug` | text unique not null | derivado del título de la temática, para la URL |
| `tematica` | text not null | único campo obligatorio del paso 1 |
| `fecha` | date not null | default `current_date` — la semana |
| `titulo` | text | la idea ganadora |
| `imagen_url` | text | URL pública de Storage |
| `imagen_path` | text | path en el bucket, para poder borrar el archivo |
| `desarrollo` | text | el desarrollo profundo |
| `assets` | jsonb not null default `'[]'` | ver shape abajo |
| `puntaje` | int | check `between 1 and 10` |
| `correcciones` | text | |
| `destaques` | text | |
| `oportunidades` | text | |
| `created_by` | uuid not null → `auth.users(id)` | quién la cargó |
| `created_at` | timestamptz not null default `now()` | |
| `updated_at` | timestamptz not null default `now()` | trigger en update |

Índice: `ideas_tematicas_fecha_idx on (fecha desc)`.

**Estado derivado, no almacenado.** Una temática está *en curso* si `titulo is null`, y
*completa* si tiene título. No hay columna de estado que pueda desincronizarse.

**Slug.** Se genera del `tematica` al crear (minúsculas, sin acentos, guiones). Si choca
con uno existente se le agrega un sufijo numérico. No se regenera al editar el título de
la idea — la URL es estable una vez publicada.

### Shape de `assets`

```json
[
  { "tipo": "link", "url": "https://tiktok.com/...", "label": "Referencia TikTok" },
  { "tipo": "file", "url": "https://...supabase.co/...", "path": "slug/1234-ab.pdf", "label": "Moodboard" }
]
```

`tipo: 'file'` lleva `path` (para borrar de Storage); `tipo: 'link'` no. `label` es opcional
y cae al hostname del link si está vacío.

**Por qué jsonb y no tabla aparte:** son 2–5 items por idea, siempre se leen junto con la
idea y nunca se consultan solos. Una tabla ahí es un join sin beneficio. El costo asumido:
al quitar un asset de tipo `file` hay que borrar el archivo de Storage desde el composable
(mismo patrón que `pcm-template`).

### Storage

Bucket `ideas`, público. Path: `{slug}/{timestamp}-{rand}.{ext}`.
Cubre tanto la imagen principal como los assets de tipo `file`.

### Acceso

- **`anon`**: `select` únicamente de las filas completas (`titulo is not null`). Las temáticas
  en curso no se filtran al público.
- **`authenticated` + `is_motix_member()`**: select / insert / update / delete completo.
- **`service_role`**: todo.
- Grants explícitos en la migración (sin grant, PostgREST devuelve `42501`).
- RLS activado, con policy de select partida en dos: una para `anon` con el filtro de
  `titulo is not null`, otra para `authenticated` con `is_motix_member()`.
- Storage: lectura pública del bucket `ideas`; insert / update / delete solo para
  `authenticated` con `is_motix_member()`.

**Permisos de edición:** cualquier miembro Motix logueado edita o borra cualquier idea.
Es un pizarrón compartido de 4 personas que deciden juntas; el permiso granular sería
fricción sin beneficio. `created_by` se guarda para mostrar autoría, no para restringir.

## Páginas

### `/` — index (público)

- **Header:** título "Stupid Big Ideas".
- **La dinámica:** los 5 pasos, una línea cada uno, numerados, texto chico y gris.
  Ultra breve — ocupa una pantalla y se termina. Es contexto, no contenido.
- **Con sesión:** si hay una temática en curso, se muestra arriba de la grilla con un CTA
  para completarla. Botón "Nueva temática".
- **Buscador:** un input que filtra en cliente por `tematica`, `titulo` y `desarrollo`.
  Se traen todas las ideas completas y se filtra en memoria — a ~50 filas por año el
  filtro es instantáneo y no hay índice que mantener. Full-text search en Postgres recién
  tendría sentido pasadas varias centenas de filas.
- **Grilla:** cards con imagen, título, temática y fecha. Orden por `fecha desc`.
- **Empty state** cuando no hay ideas o cuando la búsqueda no matchea.

### `/idea/[slug]` — ficha (pública)

Layout editorial, una columna angosta:

1. Imagen grande arriba.
2. Título.
3. Temática y fecha como dato chico.
4. Desarrollo, como texto corrido legible.
5. Assets, como lista de links y thumbs.
6. Evaluación al final: puntaje destacado + los campos de texto que estén cargados.

Los campos vacíos no se renderizan. Con sesión aparece un botón "Editar" que abre el
slideover, y uno de borrar con confirmación.

Si el slug no existe → 404 (`createError`). Si la idea existe pero está en curso y no hay
sesión, `anon` no la puede leer, así que también da 404 — correcto, no está publicada.

### `/login`

Solo login (email + password), sin registro público. Los usuarios ya existen en Registro.

## Componentes y composables

```
app/
  components/
    idea/Card.vue          — card de la grilla
    idea/Form.vue          — slideover de edición (todos los campos)
    idea/Evaluacion.vue    — bloque de puntaje + 3 textos, oculta los vacíos
    idea/AssetList.vue     — render de assets (links + files)
    ui/EmptyState.vue
  composables/
    useIdeas.js            — fetch, crear, actualizar, borrar
    useAssets.js           — upload y borrado en Storage
  utils/
    slugify.js
  pages/
    index.vue
    idea/[slug].vue
    login.vue
  layouts/
    default.vue
    auth.vue
```

**Creación en dos fases.** Crear una temática es un modal chico con solo `tematica` +
`fecha` — en el paso 1 no hay nada más que anotar. El resto se completa después desde la
ficha, vía el slideover.

## Errores y estados

- **Errores de escritura:** banner rojo inline (`bg-red-50 border-red-200`), mismo patrón
  que `pcm-template`. Sin toasts que se pierdan.
- **Slug duplicado (`23505`):** el composable lo traduce a mensaje amigable y reintenta con
  sufijo numérico.
- **Carga async:** `USkeleton` en la grilla, nunca spinner full-screen.
- **Upload fallido:** se aborta el guardado y se avisa; no se persiste una fila con
  `imagen_url` roto.
- **Borrado:** confirmación previa. Borra la fila y después los archivos de Storage
  (imagen + assets de tipo `file`).

## Verificación

1. `pnpm dev` levanta sin errores de Tailwind ni de Nuxt.
2. Sin sesión: el index lista solo ideas completas; una temática en curso no aparece ni por
   URL directa.
3. Con sesión Motix: crear temática → aparece "en curso" → completar desde la ficha →
   aparece en el index público.
4. Buscador: filtra por temática, título y desarrollo.
5. Subir imagen y un asset de cada tipo; borrar la idea y verificar que el bucket quedó
   limpio.
6. Un usuario con rol `user` (no `motix`) no puede escribir.

## Fuera de alcance

- Registro público de usuarios.
- Las 4 ideas del debate (el paso 2 y la exposición quedan fuera de la app, por diseño).
- Dark mode.
- Full-text search en Postgres.
- Comentarios o feedback multi-usuario por idea: la evaluación es un único bloque
  consensuado, no un hilo.
