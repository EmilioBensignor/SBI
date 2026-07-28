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
