# Múltiples ideas por temática — Diseño

Fecha: 2026-07-30
Estado: aprobado en brainstorming, pendiente de implementación

## Qué cambia

Hoy una fila de `ideas_tematicas` es a la vez la temática y la única idea ganadora de esa semana. El nuevo concepto separa los dos niveles: por temática se anotan **varias** ideas, y la evaluación (puntaje, destaques, oportunidades) pasa a ser de la sesión, no de una idea.

Además la temática gana un campo `desafio` opcional: la consigna que el equipo se plantea para esa semana.

No se migran datos. La DB casi no tiene contenido cargado, así que el schema se reescribe limpio. **Solo se toca lo de este repo** (`ideas_tematicas`, la tabla nueva `ideas`, el bucket `ideas`); ninguna tabla de finanzas del proyecto Registro se modifica.

## Modelo de datos

### `public.ideas_tematicas` (la temática / sesión)

| Columna | Tipo | Nota |
|---|---|---|
| `id` | uuid PK | |
| `slug` | text unique | se genera de `tematica` al crear, no se regenera al editar |
| `tematica` | text not null | |
| `fecha` | date not null | |
| `desafio` | text | **nuevo**, opcional |
| `puntaje` | numeric(2,1) check 0–5 | **cambia** de `int 1-10` a decimal 0–5 (lamparitas, medias permitidas) |
| `destaques` | text | cosas a destacar de la sesión |
| `oportunidades` | text | cosas a mejorar |
| `created_by` | uuid FK auth.users | |
| `created_at` / `updated_at` | timestamptz | trigger existente |

Se eliminan: `titulo`, `imagen_url`, `imagen_path`, `desarrollo`, `assets`, `correcciones`. Los cuatro primeros se mudan al nivel de idea; `correcciones` desaparece (la evaluación queda en destaques + oportunidades).

### `public.ideas` (nueva)

| Columna | Tipo | Nota |
|---|---|---|
| `id` | uuid PK | |
| `tematica_id` | uuid FK → `ideas_tematicas(id) on delete cascade` | |
| `orden` | int not null default 0 | reservado para reordenar; por ahora se ordena por `created_at` |
| `titulo` | text not null | único campo requerido |
| `insight` | text | |
| `concepto` | text | |
| `anotaciones` | text | |
| `assets` | jsonb not null default `'[]'` | |
| `created_by` | uuid FK auth.users | |
| `created_at` / `updated_at` | timestamptz | mismo trigger |

Índice: `ideas_tematica_id_idx on (tematica_id, orden, created_at)`.

**Decisión: sin imagen destacada aparte.** Imágenes, audios, links y archivos van todos en `assets` con un campo `tipo`. Una columna `imagen_url` separada duplicaría el manejo de Storage por un caso que el array ya cubre. La ficha renderiza las imágenes del array en grande; el resto como lista.

Shape de `assets`:

```json
[
  { "tipo": "imagen", "url": "https://…", "path": "slug/1234-ab.jpg", "label": "" },
  { "tipo": "audio",  "url": "https://…", "path": "slug/1234-cd.m4a", "label": "Nota de voz" },
  { "tipo": "file",   "url": "https://…", "path": "slug/1234-ef.pdf", "label": "Moodboard" },
  { "tipo": "link",   "url": "https://…", "label": "Referencia TikTok" }
]
```

`tipo` se deriva del MIME del archivo al subirlo (`image/*` → `imagen`, `audio/*` → `audio`, resto → `file`). Los links se agregan a mano y son siempre `link`.

## Visibilidad

Regla nueva de "temática cerrada", derivada, sin columna de estado:

> Una temática es pública cuando tiene **al menos una idea** Y **al menos uno** de `puntaje`, `destaques` u `oportunidades`.

Es decir: fue trabajada y fue evaluada. Una temática recién creada, o una con ideas pero sin evaluar, solo la ve el equipo logueado.

Qué ve cada uno:

| | anónimo | miembro Motix |
|---|---|---|
| Temáticas cerradas | sí | sí |
| Temática en curso / sin evaluar | no | sí |
| Ideas de una temática cerrada | sí | sí |
| `puntaje`, `destaques`, `oportunidades` | **no** | sí |
| `desafio` | sí | sí |

El score y la evaluación se ocultan en el template con `v-if="user"`, no por RLS: RLS filtra filas, no columnas. Un anónimo que mire la respuesta de red podría verlos. Es aceptable para un pizarrón de equipo; si hiciera falta esconderlos de verdad, la solución es una vista `ideas_tematicas_publicas` sin esas columnas, y queda fuera de alcance.

### Policies

`ideas_tematicas`:
- `anon select`: `exists (select 1 from ideas i where i.tematica_id = id)` **and** `(puntaje is not null or destaques is not null or oportunidades is not null)`. No llama a `is_motix_member()` a propósito — anon no debe tocar `user_profiles`.
- `authenticated` select/insert/update/delete: `is_motix_member()` (insert además exige `created_by = auth.uid()`).

`ideas`:
- `anon select`: su temática cumple la condición de arriba (subquery contra `ideas_tematicas`).
- `authenticated` select/insert/update/delete: `is_motix_member()`.

Grants explícitos para las dos tablas: `select` a `anon`; `select, insert, update, delete` a `authenticated` y `service_role`.

Storage: el bucket `ideas` y sus policies no cambian.

## Páginas

### Index (`/`)

Sin `h1`. El nombre del proyecto vive en el header del layout (ya está ahí).

Estructura, de arriba abajo:

1. **Temática en curso** — bloque apretable con label `Temática` arriba y recuadro, linkea a su ficha. Solo con sesión. Si no hay ninguna en curso, no se muestra nada.
2. **Fila de buscador + botón** — buscador público; botón "Nueva temática" solo con sesión.
3. **Grilla de temáticas** — todas las visibles según la regla de arriba, menos la en curso (que ya se muestra arriba y no se duplica).

"En curso" ahora significa: una temática que todavía no cumple la condición de cerrada. Si hubiera más de una abierta, se muestra la más reciente por fecha.

`IdeaCard` cambia: **sin imagen de portada** (la portada era la imagen de la idea única). Muestra temática, fecha, desafío si hay, y un contador de ideas. Se descarta usar la primera imagen de la primera idea como portada porque obliga a traer las ideas en el listado del index.

El buscador filtra en cliente por `tematica` y `desafio`.

### Ficha (`/idea/[slug]`)

Pasa a ser la ficha de la **temática**:

1. Volver.
2. Header: `tematica` como título, fecha, `desafio` si hay. Con sesión: botones editar temática / borrar.
3. Lista de ideas, expandidas (no acordeón — son el contenido principal). Cada una: título, insight, concepto, anotaciones, imágenes en grande, audios con `<audio controls>` nativo, links y archivos como lista. Con sesión, cada idea tiene editar / borrar.
4. Con sesión: botón "Agregar idea".
5. Con sesión: bloque de evaluación — lamparitas + destaques + oportunidades.

Si la temática no tiene ideas todavía: `EmptyState` con el CTA de agregar la primera.

El 404 sigue viviendo en el `watchEffect` (consecuencia de `lazy: true`); no se toca esa mecánica.

## Componentes y composables

Renombres — el dominio cambió y los nombres viejos mienten:

- `useIdeas.js` → **`useTematicas.js`**: `fetchAll`, `fetchBySlug` (trae la temática con sus ideas anidadas), `create` ({tematica, fecha, desafio}), `update`, `remove`, `estaCerrada`.
- Nuevo **`useIdeas.js`**: `create`, `update`, `remove` de ideas hijas. Sigue siendo la única puerta a la DB; la limpieza de Storage al borrar una idea o quitar un asset vive acá, best-effort.
- `useStorage.js`: se agrega `tipoDeArchivo(file)` para derivar `imagen`/`audio`/`file` del MIME. `thumb()` y el resto no cambian.

Componentes:

- `idea/NuevaTematica.vue` — suma campo `desafío` opcional.
- `idea/Form.vue` (332 líneas, hoy edita "la idea") se parte en dos:
  - **`idea/TematicaForm.vue`** — slideover: temática, fecha, desafío, puntaje (lamparitas), destaques, oportunidades.
  - **`idea/IdeaForm.vue`** — slideover: título, insight, concepto, anotaciones, assets (imágenes / audios / archivos / links). Se abre para crear y para editar.
- **`Lamparitas.vue`** (raíz de `components/`, sin prefijo) — 5 `i-lucide-lightbulb`. Click en la mitad izquierda del ícono = `.5`, derecha = entero. Prop `readonly` para el modo lectura de la ficha. Teclado: flechas ← → ajustan de a `.5`.
- `idea/AssetList.vue` — se extiende: imágenes inline, audios con `<audio controls>`, links y archivos como la lista actual. Sanitizado de `href` (solo `http:`/`https:`/`mailto:`) se mantiene.
- `idea/Evaluacion.vue` — puntaje como lamparitas en vez de `/10`, y solo dos campos (destaques, oportunidades). Se envuelve en `v-if="user"`.
- `idea/Card.vue` — sin imagen, con contador de ideas y desafío.

Los uploads siguen ocurriendo en el submit, no al elegir el archivo, y cada asset pendiente sigue llevando su propio `File`. Ambas reglas ya documentadas en el CLAUDE.md se conservan.

## Fuera de alcance

- Reordenar ideas por drag. La columna `orden` queda creada pero se llena con el default; el orden efectivo es `created_at`.
- Reemplazar el `confirm()` nativo del delete por un `UModal`.
- Vista SQL para esconder de verdad las columnas privadas de anon.
- Arreglar que `fetchAll()` no setee `errorMessage` (bug conocido preexistente).

## Verificación

1. `pnpm build` pasa limpio.
2. Anónimo: el index no muestra temáticas sin ideas ni sin evaluar; entrar por URL a una de esas da 404.
3. Anónimo: en una temática cerrada ve ideas y desafío, no ve lamparitas ni destaques/oportunidades.
4. Con sesión: crear temática con desafío → agregar dos ideas con assets de cada tipo → cargar puntaje `4.5` → la temática aparece pública.
5. Borrar una temática borra sus ideas (cascade) y no deja la UI inconsistente.
