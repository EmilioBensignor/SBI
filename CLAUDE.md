# CLAUDE.md — Stupid Big Ideas

Registro público de las ideas creativas de Motix. Cada semana el equipo elige una temática, idea por separado, debate y elige una ganadora. La app guarda esa ganadora: título, imagen, desarrollo, assets y evaluación.

El index es público y sin sesión. El CRUD requiere login de un miembro Motix.

## Stack

| Tecnología | Versión | Uso |
|---|---|---|
| Nuxt | ^4.5.1 | SSR, pages |
| Nuxt UI | ^4.10 | UModal, USlideover, USkeleton, UIcon |
| Tailwind CSS | ^4.3.3 | CSS-first, `@theme` en `main.css`, sin config file |
| @nuxtjs/supabase | ^2.0.9 | Auth + DB + Storage |
| @nuxt/fonts | ^0.14 | Outfit |

pnpm. JS puro. Light mode único (`ui: { colorMode: false }`). Deploy pendiente (Vercel).

**Backend: proyecto Supabase `Registro`** — el mismo de la app de finanzas de Motix. Las ideas son un concepto nuevo dentro de esa DB, no un proyecto aparte. Reutiliza `user_profiles`, el enum `user_role` (`admin`/`motix`/`user`) y la función `is_motix_member()` (SECURITY DEFINER). **No toca ninguna tabla de finanzas.**

## Convenciones

- UI en español rioplatense, código en inglés salvo el dominio (`tematica`, `desarrollo`, `puntaje`, `correcciones`, `destaques`, `oportunidades`, `assets`).
- **Cero comentarios en JS/Vue.** El porqué se documenta acá, no en el código.
- Los composables son la única puerta a la DB y a Storage: ningún componente llama a `supabase.from()` ni a `supabase.storage` directo.
- Iconos `i-lucide-*` vía `UIcon`.
- Errores de escritura: banner rojo inline (`bg-red-50 border border-red-200`), con `role="alert"`. Sin toasts.
- Carga async con `USkeleton`, nunca spinner full-screen.

## Reglas vigentes

- **Estado derivado, no almacenado.** Una temática está *en curso* si `titulo is null`, y *completa* si tiene título. No hay columna de estado que pueda desincronizarse.
- **El index es público.** De ahí `redirectOptions.exclude: ['/', '/idea/**', '/login']` en `nuxt.config.ts`. Sacarlo rompe el acceso anónimo, que es el requisito central del producto.
- **La policy de `anon` no llama a `is_motix_member()`** a propósito: anon no debe tocar `user_profiles`. Filtra solo por `titulo is not null`.
- **`assets` es `jsonb`, no una tabla.** Son 2-5 items por idea, siempre leídos junto con la idea, nunca consultados solos. Costo asumido: al quitar un asset de tipo `file` hay que limpiar Storage desde el composable.
- **El slug no se regenera al editar** el título: la URL es estable una vez publicada. Se genera de `tematica` al crear, con reintento por sufijo numérico ante `23505` (hasta 5 intentos).
- **Los uploads ocurren en el submit**, no al elegir el archivo: un formulario cancelado no deja basura en el bucket.
- **Cada asset pendiente lleva su propio `File`** (`asset.file`). Antes había un array paralelo `archivosNuevos` y se buscaba el archivo por nombre — dos archivos con el mismo nombre en un submit hacían que el segundo nunca se subiera.
- **`remove()` borra la fila antes que los archivos.** Si falla Storage quedan huérfanos, pero la UI queda consistente. El orden inverso dejaría una idea sin imagen si falla el delete de la fila.
- **La limpieza de Storage es best-effort y nunca invalida la operación principal.** Tanto en `remove()` como en el submit de `Form.vue`, el `removeFiles` va en su propio `try/catch`: si falla, la fila ya se borró o el update ya se guardó, y mostrar "no pudimos guardar" sería mentirle al usuario. El costo es un archivo huérfano en el bucket.
- **La temática en curso se muestra aparte, arriba de la grilla** (solo con sesión), y se excluye del listado para no duplicarla. Es el atajo para completarla al cierre de la reunión.
- **`watch: [user]` en los `useAsyncData`:** al loguearse, RLS devuelve también las en curso, así que hay que refetchear.
- **Fechas parseadas con `T12:00:00`:** `new Date('2026-07-27')` se interpreta como UTC medianoche y en Argentina (UTC-3) mostraría el día anterior.
- **Búsqueda en cliente.** A ~50 filas por año el filtro en memoria es instantáneo. Full-text search en Postgres recién tendría sentido pasadas varias centenas.
- **`href` de assets sanitizado:** solo `http:`, `https:` y `mailto:`; cualquier otro protocolo cae a `#`. Evita `javascript:` en un campo que escriben usuarios.

## Arquitectura

```
app/
  utils/slugify.js              — minúsculas, sin acentos, guiones
  composables/
    useAuth.js                  — login / logout / user. logout va a `/`, no a /login
    useIdeas.js                 — única puerta a ideas_tematicas
    useStorage.js               — única puerta al bucket `ideas`
  components/
    EmptyState.vue              — en la raíz a propósito: sin carpeta, sin prefijo
    idea/Card.vue               — card de la grilla (presentacional)
    idea/AssetList.vue          — links + archivos, oculto si no hay
    idea/Evaluacion.vue         — puntaje + 3 textos, oculta los vacíos
    idea/NuevaTematica.vue      — modal de creación (fase 1: temática + fecha)
    idea/Form.vue               — slideover de edición (fase 2: todo lo demás)
  layouts/
    default.vue                 — header público, "Entrar"/"Salir" según sesión
    auth.vue                    — centrado, para login
  pages/
    index.vue                   — dinámica + buscador + grilla
    idea/[slug].vue             — ficha editorial
    login.vue
supabase/schema.sql             — migración idempotente (ya aplicada en Registro)
```

**Creación en dos fases.** Crear una temática pide solo `tematica` + `fecha` — en el paso 1 de la dinámica no hay nada más que anotar. El resto se completa después desde la ficha.

**Auto-import con prefijo de carpeta** (`pathPrefix: true`): `components/idea/Card.vue` se usa como `<IdeaCard>`. Por eso `EmptyState.vue` vive en la raíz de `components/` y no en una subcarpeta: ahí no hay prefijo que anteponer y queda `<EmptyState>`. Con `pathPrefix: false` los nombres pierden la carpeta (`<Card>`), que no es lo que usan los templates.

## Datos

Tabla `public.ideas_tematicas` (16 columnas): `id`, `slug` (unique), `tematica`, `fecha`, `titulo`, `imagen_url`, `imagen_path`, `desarrollo`, `assets` (jsonb), `puntaje` (1-10), `correcciones`, `destaques`, `oportunidades`, `created_by`, `created_at`, `updated_at` (trigger).

Shape de `assets`:
```json
[
  { "tipo": "link", "url": "https://...", "label": "Referencia TikTok" },
  { "tipo": "file", "url": "https://...", "path": "slug/1234-ab.pdf", "label": "Moodboard" }
]
```

Bucket `ideas`, público. Path `{slug}/{timestamp}-{rand}.{ext}`.

**Permisos:** cualquier miembro Motix logueado edita o borra cualquier idea — es un pizarrón compartido. `created_by` se guarda para autoría, no para restringir.

## Estado actual

- **Hecho:** scaffold, auth, CRUD completo, index público con buscador, ficha editorial, formularios de creación y edición con upload de imagen y assets mixtos (archivo/link), migración aplicada en Registro.
- **Verificado end-to-end:** `anon` ve solo las ideas completas; una temática en curso da 404 sin sesión; la home renderiza la grilla y los 5 pasos.
- **Sin verificar** (requiere sesión de un usuario Motix real): el ciclo completo logueado — crear temática, completarla, subir imagen y assets, borrar. El código está escrito y compila; falta la pasada manual.
- **Pendiente:** deploy en Vercel, y el `.env` de producción con las credenciales de Registro.

## Setup

```bash
pnpm install
pnpm dev
```

`.env` necesita `SUPABASE_URL` y `SUPABASE_KEY` (anon) del proyecto **Registro**. La `service_role` no va acá: se expondría al browser.

Nota: hay un `pnpm-workspace.yaml` en la raíz del proyecto porque existe otro en `/Users/lio/` que hacía que `pnpm install` no instalara nada (falso "Already up to date").
