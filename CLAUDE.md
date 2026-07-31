# CLAUDE.md — Stupid Big Ideas

Registro público de las ideas creativas de Motix. Cada semana el equipo elige una temática, opcionalmente se plantea un desafío, y cada uno anota sus ideas. La app guarda la sesión completa: la temática con sus N ideas (título, insight, concepto, anotaciones, assets) y la evaluación de la sesión (puntaje en lamparitas 0-5, para destacar, para mejorar).

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

- UI en español rioplatense, código en inglés salvo el dominio (`tematica`, `desafio`, `insight`, `concepto`, `anotaciones`, `puntaje`, `destaques`, `oportunidades`, `assets`).
- **Cero comentarios en JS/Vue.** El porqué se documenta acá, no en el código.
- Los composables son la única puerta a la DB y a Storage: ningún componente llama a `supabase.from()` ni a `supabase.storage` directo.
- Iconos `i-lucide-*` vía `UIcon`.
- Errores de escritura: banner rojo inline (`bg-red-50 border border-red-200`), con `role="alert"`. Sin toasts.
- Carga async con `USkeleton`, nunca spinner full-screen. El skeleton espeja la estructura real de lo que reemplaza (mismo `gap`, mismo `aspect`) para que no salte el layout al cambiar.
- Transición de página de 180ms (`ease-out-quart`) definida en `main.css`, con `prefers-reduced-motion`. La animación comunica estado, no decora.

## Reglas vigentes

- **Una temática tiene N ideas.** `ideas_tematicas` es la sesión semanal; `ideas` son las ideas hijas. La evaluación (puntaje, destaques, oportunidades) es de la sesión, no de una idea: se puntúa la reunión, no cada ocurrencia.
- **Estado derivado, no almacenado.** Una temática está *cerrada* (= es pública) cuando tiene al menos una idea Y al menos uno de `puntaje`, `destaques` u `oportunidades`. O sea: fue trabajada y fue evaluada. No hay columna de estado que pueda desincronizarse. La regla vive en la función SQL `tematica_cerrada()` y espejada en `estaCerrada()` de `useTematicas.js` — si se toca una, tocar la otra.
- **La ficha vive en `/tematica/[slug]`, no en `/idea/`.** La página es de la temática y las ideas son sus hijas, así que la URL vieja mentía. No se eligió `/[slug]` en la raíz para no competir con `/login` ni con páginas futuras: una temática llamada "login" quedaría inaccesible.
- **El index es público.** De ahí `redirectOptions.exclude: ['/', '/tematica/**', '/login']` en `nuxt.config.ts`. Sacarlo rompe el acceso anónimo, que es el requisito central del producto. Si se renombra la carpeta de páginas hay que tocar este patrón: sin él, la ficha redirige al login para los anónimos.
- **La policy de `anon` no llama a `is_motix_member()`** a propósito: anon no debe tocar `user_profiles`. Filtra por `tematica_cerrada()`, que solo mira columnas de las dos tablas de ideas.
- **El puntaje y la evaluación se ocultan en el template, no por RLS.** RLS filtra filas, no columnas: un anónimo que mire la respuesta de red vería `puntaje`, `destaques` y `oportunidades` de una temática cerrada. El `v-if="user"` de `IdeaEvaluacion` es la única barrera. Es aceptable para un pizarrón de equipo; esconderlos de verdad pide una vista sin esas columnas.
- **`assets` es `jsonb`, no una tabla.** Van por idea, siempre leídos junto con ella, nunca consultados solos. Tipos: `imagen`, `audio`, `link`, `file` — el tipo de los archivos se deriva del MIME en `tipoDeArchivo()` de `useStorage.js`. Costo asumido: al quitar un asset con `path` hay que limpiar Storage desde el composable.
- **Sin imagen destacada por idea.** Las imágenes son un `tipo` más dentro de `assets`. Una columna `imagen_url` aparte duplicaría el manejo de Storage por un caso que el array ya cubre; la ficha renderiza las de tipo `imagen` en grande y el resto como lista.
- **El slug no se regenera al editar** el título: la URL es estable una vez publicada. Se genera de `tematica` al crear, con reintento por sufijo numérico ante `23505` (hasta 5 intentos).
- **Los uploads ocurren en el submit**, no al elegir el archivo: un formulario cancelado no deja basura en el bucket.
- **Cada asset pendiente lleva su propio `File`** (`asset.file`). Antes había un array paralelo `archivosNuevos` y se buscaba el archivo por nombre — dos archivos con el mismo nombre en un submit hacían que el segundo nunca se subiera.
- **`remove()` borra la fila antes que los archivos.** Si falla Storage quedan huérfanos, pero la UI queda consistente. El orden inverso dejaría una idea sin imagen si falla el delete de la fila.
- **La limpieza de Storage es best-effort y nunca invalida la operación principal.** Tanto en `remove()` como en el submit de `Form.vue`, el `removeFiles` va en su propio `try/catch`: si falla, la fila ya se borró o el update ya se guardó, y mostrar "no pudimos guardar" sería mentirle al usuario. El costo es un archivo huérfano en el bucket.
- **Borrar una temática borra sus ideas por `on delete cascade`.** Por eso `remove()` de `useTematicas` necesita la temática con sus ideas y assets cargados (los trae `fetchBySlug`) — es la única forma de juntar los paths para limpiar Storage antes de perder las filas.
- **La temática en curso se muestra aparte, arriba de la grilla** (solo con sesión), y se excluye del listado para no duplicarla. Es el atajo para anotar durante la reunión. Si hubiera más de una abierta se muestra la más reciente por fecha.
- **`watch: [user]` en los `useAsyncData`:** al loguearse, RLS devuelve también las en curso, así que hay que refetchear.
- **Fechas parseadas con `T12:00:00`:** `new Date('2026-07-27')` se interpreta como UTC medianoche y en Argentina (UTC-3) mostraría el día anterior.
- **Búsqueda en cliente.** A ~50 filas por año el filtro en memoria es instantáneo. Full-text search en Postgres recién tendría sentido pasadas varias centenas.
- **`href` de assets sanitizado:** solo `http:`, `https:` y `mailto:`; cualquier otro protocolo cae a `#`. Evita `javascript:` en un campo que escriben usuarios.
- **Un solo rail de ancho: `max-w-7xl` en el layout.** Header y `<main>` comparten contenedor y padding (`px-[max(env(safe-area-inset-left),1rem)] md:px-8`), así el borde vertical es el mismo en todas las pantallas. Las páginas no vuelven a centrarse por su cuenta: la ficha usa `max-w-prose` solo para la medida de lectura del texto, no como contenedor de página. Un `mx-auto` a nivel página rompe la alineación con el header.
- **Los `useAsyncData` van con `lazy: true`.** Sin eso el `await` de nivel superior bloquea la navegación entera: se clickeaba una card y no pasaba nada hasta que respondía Supabase. Con lazy la ruta cambia al instante y entra el skeleton.
- **El 404 de la ficha vive en un `watchEffect` y se dispara con `status === 'success'`,** no con `!pending`. Consecuencia de `lazy: true`: cuando corre el script todavía no hay dato, así que el `throw createError` no puede ir suelto. Y la condición no puede ser "dejó de estar pending", porque el estado inicial es `idle`: con eso el 404 saltaría antes de que el fetch arranque, sobre datos que sí existen. Es la parte más frágil de esa página; si se toca, verificar las dos direcciones — que un slug inexistente dé 404 **y** que una temática cerrada dé 200.
- **Las imágenes se sirven por la transformación de Supabase,** no crudas: `thumb(url, width)` en `useStorage.js` reescribe `/object/public/` a `/render/image/public/` con `width` y `quality=75`. Las cards piden 640px y la ficha 1280px; sin esto la grilla bajaba el original de varios MB para mostrarlo a ~340px. Va en el composable porque es la única puerta a Storage.
- **El transformador de imágenes corta a los 25 MB de archivo fuente,** y cuando corta devuelve `400 InvalidRequest` (`"The source image file is too large to process"`), no la imagen. Como *toda* imagen pasa por `thumb()`, un PNG grande no se degradaba: no se veía nada. Por eso el `<img>` de `IdeaAssetList` lleva `@error` que cae a la URL cruda, con guard contra el loop si la cruda también falla. Verificado con un PNG de 25 MB: transformada `400`, cruda `200`. El fallback baja el original entero — lo correcto de verdad sería comprimir al subir, pero eso pide un paso de resize en `uploadFile`.
- **Las imágenes abren en un visor, no en pestaña nueva.** El `<a target="_blank">` de `IdeaAssetList` pasó a `<button>` + `<dialog>` nativo: `showModal()` ya trae backdrop, cierre con Escape y trampa de foco sin librería ni estado global. Cierra también al clickear el backdrop — el handler compara `event.target === dialog`, que solo matchea el área de afuera. El visor pide `thumb(url, 2048)` y comparte el mismo fallback a URL cruda que la grilla.
- **Todo lo que es de la temática vive en el `<header>` de la ficha:** fecha, título con las lamparitas al lado, desafío y el bloque de destacar/mejorar. Antes la evaluación era una sección al pie, después de las ideas, y se leía como si fuera de la última idea en vez de la sesión. En las cards del index el puntaje va en la fila de la fecha con `ml-auto` (no pegado al título): así queda alineado a la derecha en todas sin importar el largo del título, que si no hacía que uno corto como "Fuego" tuviera el rating pegado y uno largo lo empujara a otra línea.
- **`Lamparitas` no muestra el número en `readonly`.** Tres lamparitas y media pintadas ya dicen 3.5; el "3.5" al lado era repetir lo mismo en dos lenguajes. En modo interactivo sí queda, porque ahí confirma lo que acabás de elegir. El dato sigue disponible para lectores de pantalla en el `aria-label` del contenedor.
- **`IdeaEvaluacion` es solo destaques y oportunidades** — sin título "Evaluación" ni lamparitas, que ahora viven en el header. Quedó como un `<dl>` de dos columnas y nada más.
- **Las lamparitas miden `size-10` en modo interactivo y `size-7` en readonly.** Cada una tiene dos mitades apretables (izquierda = `n - 0.5`), así que a 24px el objetivo para las medias quedaba en 12px. Con 40px cada mitad son 20px y el 3.5 se puede poner con el dedo.
- **Todos los `textarea` van con `resize-none`.** El agarre de resize nativo rompe el layout del slideover y no aporta nada: los `rows` ya están dimensionados por campo.
- **Ningún texto por debajo de `text-sm` en desktop.** Los tamaños chicos son mobile-only y suben por breakpoint (`text-sm md:text-base`, `text-xs md:text-sm`). Los labels uppercase con `tracking-wide` llegan hasta `md:text-sm` y no más: en `text-base` pesan igual que el texto de lectura y aplastan la jerarquía.
- **El index no tiene `h1`.** El nombre del proyecto vive en el header del layout y repetirlo abajo era decir dos veces lo mismo. El index es: temática en curso (apretable, solo con sesión), fila de buscador + botón, grilla. La descripción del producto sobrevive como `meta description` en `nuxt.config.ts`.
- **Las cards de la grilla no tienen imagen.** La portada de V1 era la imagen de la idea única; con N ideas habría que traerlas todas en el listado del index solo para elegir una miniatura. La card muestra fecha, temática, desafío y contador de ideas.
- **No sacar el weight 700 de Outfit** aunque ningún template lo use. Medido: sacarlo sube el CSS de 196K a 256K por cómo `@nuxt/fonts` genera los fallbacks, y el woff2 igual no se descarga.
- **La escala de breakpoints es la de Lio, no la de Tailwind.** `--breakpoint-*: initial` en `main.css` borra la default antes de redefinir: `iph` 402 / `sm` 480 / `md` 768 / `lg` 1080 / `xl` 1280 / `xxl` 1440. Sin esa línea conviven las dos escalas y `lg:` significa dos cosas distintas según dónde se mire. **Consecuencia al tocar código viejo: `sm:` pasó de 640px a 480px.** Por eso los `sm:grid-cols-2` de la grilla, de `IdeaEvaluacion` y de `IdeaAssetList` se movieron a `md:` — a 480px dos columnas quedan ilegibles.
- **`iph:` (402px) es el salto dentro de mobile,** entre el iPhone SE (~375) y el iPhone moderno (393-402). Se usa casi solo para tipografía, que es donde esos ~30px deciden si un título entra en dos líneas o se rompe en cuatro.
- **`mac:` es un breakpoint por ALTURA** (`min-width: 1280px and max-height: 900px`), definido con `@custom-variant`. Solo comprime padding vertical y escala tipográfica; nunca reordena ni esconde. La doble condición evita que un celular apaisado matchee.
- **Las safe-areas exigen `viewport-fit=cover` en el `<meta name="viewport">`.** Sin eso los `env(safe-area-inset-*)` valen 0 y todo el trabajo de notch y home indicator no hace nada. Se usa `px-[max(env(safe-area-inset-left),1rem)]`: el inset izquierdo aplica a ambos lados porque en portrait los dos son 0 y en landscape son simétricos.
- **La PWA es a mano, sin módulo:** `public/manifest.webmanifest` + `public/sw.js` + `app/plugins/pwa.client.js`. Mismo patrón que el repo Registro. El `sw.js` cachea el app shell y descarta todo lo que no sea del propio origen, lo que ya deja afuera a Supabase — por eso no hace falta el filtro `/api/` que sí tiene Registro.
- **`status-bar-style` es `default`, no `black-translucent`** como en Registro: SBI es light, y con translucent el texto de la status bar queda blanco sobre fondo blanco.
- **El manifest no fija `orientation`.** Registro la clava en `portrait` porque es solo mobile; SBI se usa también en Mac y la ficha con la grilla de dos columnas se lee mejor sin bloquear la rotación.
- **Nuxt está fijado en `4.4.8` sin `^`, y no hay que subirlo a 4.5.x.** Nuxt 4.5 arrastra Vite 8 con **rolldown**, que interopera mal el CJS de `tslib`: el build compila limpio pero al servirlo toda ruta SSR muere con `Cannot destructure property '__extends' of '__toESM(...).default'`, y en `pnpm dev` no se ve. No se arregla con `nitro.externals` (probado): la causa es el bundler, no la resolución de módulos. Registro corre 4.4.8 con Vite 7 + Rollup y nunca lo tuvo — de ahí sale el pin. Si algún día hay que subir, verificar `node .output/server/index.mjs` **antes** de deployar, porque `pnpm build` sale con éxito igual.
- **Un plugin `.client.js` mal nombrado se ejecuta en SSR.** Un duplicado tipo `pwa.client 2.js` (que dejan `git stash -u`/`pop` o un `mv` de ida y vuelta) no termina en `.client.js`, así que Nuxt lo trata como universal y revienta con `Cannot use 'in' operator to search for 'serviceWorker' in undefined` — la home entera cae a 500. Si aparece ese error, chequear `ls app/plugins/` antes que el código.

## Arquitectura

```
app/
  utils/slugify.js              — minúsculas, sin acentos, guiones
  composables/
    useAuth.js                  — login / logout / user. logout va a `/`, no a /login
    useTematicas.js             — única puerta a ideas_tematicas + `estaCerrada()`
    useIdeas.js                 — única puerta a ideas (las hijas)
    useStorage.js               — única puerta al bucket `ideas` + `thumb()` + `tipoDeArchivo()`
  components/
    EmptyState.vue              — en la raíz a propósito: sin carpeta, sin prefijo
    Lamparitas.vue              — puntaje 0-5 con medias; prop `readonly` para lectura
    idea/Card.vue               — card de temática en la grilla (presentacional)
    idea/Item.vue               — una idea en la ficha: textos + assets + editar/borrar
    idea/AssetList.vue          — imágenes inline, audios nativos, links y archivos
    idea/Evaluacion.vue         — lamparitas + destacar/mejorar, oculta los vacíos
    idea/NuevaTematica.vue      — modal de creación (temática + fecha + desafío)
    idea/TematicaForm.vue       — slideover: datos de la temática + evaluación
    idea/Form.vue               — slideover de idea; crea o edita según prop `idea`
  layouts/
    default.vue                 — header público + rail `max-w-7xl`, "Entrar"/"Salir" según sesión
    auth.vue                    — centrado, para login
  pages/
    index.vue                   — temática en curso + buscador + grilla
    tematica/[slug].vue         — ficha de la temática con sus ideas
    login.vue
supabase/schema.sql             — migración idempotente (V2)
```

**`idea/Form.vue` crea y edita.** Sin prop `idea` es "Agregar idea" (botón sólido) y llama a `create`; con `idea` es "Editar" (botón discreto) y llama a `update`. Dos componentes casi idénticos no se justificaban.

**Creación en dos fases.** Crear una temática pide `tematica` + `fecha` + `desafio` opcional — al abrir la sesión no hay nada más que anotar. Las ideas y la evaluación se cargan después desde la ficha.

**Auto-import con prefijo de carpeta** (`pathPrefix: true`): `components/idea/Card.vue` se usa como `<IdeaCard>`. Por eso `EmptyState.vue` vive en la raíz de `components/` y no en una subcarpeta: ahí no hay prefijo que anteponer y queda `<EmptyState>`. Con `pathPrefix: false` los nombres pierden la carpeta (`<Card>`), que no es lo que usan los templates.

## Datos

`public.ideas_tematicas` (11 columnas) — la sesión: `id`, `slug` (unique), `tematica`, `fecha`, `desafio`, `puntaje` (`numeric(2,1)`, 0-5), `destaques`, `oportunidades`, `created_by`, `created_at`, `updated_at` (trigger).

`public.ideas` (12 columnas) — las ideas hijas: `id`, `tematica_id` (FK, `on delete cascade`), `orden`, `titulo` (not null), `marca`, `insight`, `concepto`, `anotaciones`, `assets` (jsonb), `created_by`, `created_at`, `updated_at` (trigger). `marca` es opcional y se muestra como kicker arriba del título en la ficha.

**`tematica_cerrada()` es `security definer` y no puede dejar de serlo.** La policy de `anon` sobre `ideas` la llama, y la función lee `ideas`: bajo RLS eso se llama a sí mismo en loop y Postgres corta con `stack depth limit exceeded` (54001). Con `security definer` + `search_path` fijo saltea RLS y corta la recursión. Verificado: sin el fix, un `select` como `anon` revienta.

Shape de `assets`:
```json
[
  { "tipo": "imagen", "url": "https://...", "path": "slug/1234-ab.jpg", "label": "" },
  { "tipo": "audio", "url": "https://...", "path": "slug/1234-cd.m4a", "label": "Nota de voz" },
  { "tipo": "link", "url": "https://...", "label": "Referencia TikTok" },
  { "tipo": "file", "url": "https://...", "path": "slug/1234-ef.pdf", "label": "Moodboard" }
]
```

Bucket `ideas`, público. Path `{slug}/{timestamp}-{rand}.{ext}`.

**Permisos:** cualquier miembro Motix logueado edita o borra cualquier idea — es un pizarrón compartido. `created_by` se guarda para autoría, no para restringir.

## Estado actual

- **Hecho:** V2 (N ideas por temática) completa — schema aplicado en Registro, composables partidos en `useTematicas`/`useIdeas`, lamparitas 0-5, desafío, evaluación de sesión, ficha con lista de ideas, index sin `h1`.
- **Hecho (pasada responsive + PWA):** escala de breakpoints propia con `iph:` y `mac:`, safe-areas en los dos layouts con `viewport-fit=cover`, los `sm:grid-cols-2` migrados a `md:` por el cambio de escala, y PWA a mano (manifest + `sw.js` + plugin + íconos 180/192/512). Los íconos son placeholder 💡 generados con AppKit — reemplazables por los definitivos sin tocar código.
- **Verificado en la DB (SQL directo, con RLS):** la estructura quedó como el schema del repo; `tematica_cerrada()` da `false` con 0 ideas, `false` con 1 idea sin evaluar y `true` recién con idea + puntaje; `4.5` se guarda bien en `numeric(2,1)`; como rol `anon`, una temática cerrada devuelve 1 fila y al sacarle el puntaje devuelve 0. El build de producción pasa limpio.
- **Verificado en el browser (393×852 y 1512×982):** home, login, ficha con dos ideas y cards renderizan sin overflow horizontal, con el rail alineado al header en ambos tamaños. En el CSS compilado quedaron los seis breakpoints (402/480/768/1080/1280/1440) y el `mac:` como `(width>=1280px) and (height<=900px)`.
- **Verificado sobre el build de producción (`node .output/server/index.mjs`):** las seis rutas responden 200, el service worker se registra y queda `activated`, el cache `sbi-shell-v1` guarda los cinco archivos del shell, la home cacheada sirve el HTML completo offline, y el manifest sale con `Content-Type: application/manifest+json` y los campos de instalabilidad (name, short_name, start_url, display standalone, íconos 192 y 512).
- **Sin verificar** (requiere sesión en el browser de automatización): los slideovers de formulario abiertos a 393px. Revisado el CSS en su lugar — los únicos anchos fijos son el `w-24`/`w-28` del campo Etiqueta, que ya es `flex-1` en mobile y `w-28` recién desde `sm:`; todo el resto de los forms usa `w-full`.
- **Pendiente:** deploy en Vercel, y el `.env` de producción con las credenciales de Registro. El `.env` no se commitea: en Vercel las dos variables van por el panel. Ya no hay nada que lo bloquee: el build de producción levanta y sirve bien.
- **Conocido, sin arreglar:** si `fetchAll()` falla, `errorMessage` nunca se setea (el `error` del `useAsyncData` no se lee) y un fallo de red muestra "Todavía no hay temáticas", que es mentira. Los dos `onDelete` usan `confirm()` nativo en vez de un `UModal`. Reordenar ideas por drag quedó fuera: la columna `orden` existe pero siempre vale 0 y el orden efectivo es `created_at`.

## Setup

```bash
pnpm install
pnpm dev
```

`.env` necesita `SUPABASE_URL` y `SUPABASE_KEY` (anon) del proyecto **Registro**. La `service_role` no va acá: se expondría al browser.

Nota: hay un `pnpm-workspace.yaml` en la raíz del proyecto porque existe otro en `/Users/lio/` que hacía que `pnpm install` no instalara nada (falso "Already up to date").

**Antes de diagnosticar un 404 por `curl`, verificar quién escucha el puerto** (`lsof -ti:3000`). Suele haber un `nuxt dev` de otro proyecto ahí: las respuestas son de esa app y cualquier ruta propia da 404, lo que se lee como un bug del router que no existe. Levantar en un puerto libre y exportar el `.env` (`set -a; . ./.env; set +a`), porque `node .output/server/index.mjs` no lo lee solo y sin las vars todo responde 500.
