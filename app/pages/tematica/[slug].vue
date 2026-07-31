<template>
  <div v-if="pending" class="flex flex-col gap-8">
    <USkeleton class="h-4 w-16" />
    <div class="flex flex-col gap-3">
      <USkeleton class="h-3 w-40" />
      <USkeleton class="h-9 w-2/3 max-w-md" />
      <USkeleton class="h-4 w-full max-w-prose" />
    </div>
    <div class="max-w-prose flex flex-col gap-2">
      <USkeleton class="h-6 w-1/2" />
      <USkeleton class="h-4 w-full" />
      <USkeleton class="h-4 w-4/5" />
    </div>
  </div>

  <div v-else-if="tematica" class="flex flex-col gap-8">
    <NuxtLink
      to="/"
      class="flex items-center gap-1.5 w-fit text-sm md:text-base text-stone-400 hover:text-stone-900 transition-colors"
    >
      <UIcon name="i-lucide-arrow-left" class="size-4" />
      <span>Volver</span>
    </NuxtLink>

    <header class="flex flex-col gap-3">
      <span class="text-xs md:text-base text-stone-400">{{ fechaLarga }}</span>

      <div class="flex flex-wrap items-center gap-x-4 gap-y-2">
        <h1 class="text-2xl iph:text-3xl md:text-4xl mac:text-3xl text-stone-900 font-semibold tracking-tight leading-tight text-balance">
          {{ tematica.tematica }}
        </h1>
        <Lamparitas v-if="tematica.puntaje !== null" :model-value="Number(tematica.puntaje)" readonly />
      </div>

      <div v-if="tematica.desafio" class="max-w-prose flex flex-col gap-1.5 border-l-2 border-amber-200 pl-4">
        <span class="text-xs md:text-sm text-amber-700 font-medium tracking-wide uppercase">Desafío</span>
        <p class="text-base text-stone-700 leading-relaxed whitespace-pre-line">{{ tematica.desafio }}</p>
      </div>

      <IdeaEvaluacion v-if="user" :tematica="tematica" class="max-w-3xl mt-1" />

      <div v-if="user" class="flex flex-wrap items-center gap-2 mt-1">
        <IdeaTematicaForm :tematica="tematica" @saved="onSaved" />
        <IdeaTematicaForm :tematica="tematica" modo="calificar" @saved="onSaved" />
        <button
          type="button"
          class="flex items-center gap-1.5 sm:ml-auto rounded-full text-sm md:text-base text-stone-400 hover:text-red-600 transition-colors px-2 py-1"
          @click="onDeleteTematica"
        >
          <UIcon name="i-lucide-trash-2" class="size-4" />
          <span>Borrar</span>
        </button>
      </div>
    </header>

    <p
      v-if="errorMessage"
      class="bg-red-50 border border-red-200 rounded-lg text-sm md:text-base text-red-700 px-3 py-2"
      role="alert"
    >
      {{ errorMessage }}
    </p>

    <section class="flex flex-col gap-8">
      <div v-if="ideas.length" class="grid gap-x-10 gap-y-8 lg:grid-cols-2">
        <IdeaItem
          v-for="idea in ideas"
          :key="idea.id"
          :idea="idea"
          :tematica="tematica"
          @saved="onSaved"
          @delete="onDeleteIdea"
        />
      </div>

      <EmptyState
        v-else
        icon="i-lucide-lightbulb"
        title="Todavía no hay ideas"
        description="Las ideas de esta temática van a aparecer acá."
      />

      <IdeaForm v-if="user" :tematica="tematica" @saved="onSaved" />
    </section>
  </div>
</template>

<script setup>
const route = useRoute()
const { user } = useAuth()
const { fetchBySlug, remove } = useTematicas()
const { remove: removeIdea } = useIdeas()

const errorMessage = ref('')

const { data: tematica, status, refresh } = await useAsyncData(
  () => `tematica-${route.params.slug}`,
  () => fetchBySlug(route.params.slug),
  { watch: [user], lazy: true }
)

const pending = computed(() => status.value !== 'success' && status.value !== 'error')

watchEffect(() => {
  if (status.value === 'success' && tematica.value === null) {
    throw createError({ statusCode: 404, statusMessage: 'Temática no encontrada', fatal: true })
  }
})

useHead(() => ({
  title: `${tematica.value?.tematica || 'Temática'} — Stupid Big Ideas`,
}))

const ideas = computed(() => tematica.value?.ideas || [])

const fechaLarga = computed(() => {
  if (!tematica.value?.fecha) return ''
  return new Date(`${tematica.value.fecha}T12:00:00`).toLocaleDateString('es-AR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
})

const onSaved = async () => {
  errorMessage.value = ''
  await refresh()
}

const onDeleteIdea = async (idea) => {
  if (!confirm(`¿Borrar “${idea.titulo}”? No se puede deshacer.`)) return

  errorMessage.value = ''
  try {
    await removeIdea(idea)
    await refresh()
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos borrar la idea'
  }
}

const onDeleteTematica = async () => {
  if (!confirm('¿Borrar esta temática y todas sus ideas? No se puede deshacer.')) return

  errorMessage.value = ''
  try {
    await remove(tematica.value)
    await navigateTo('/')
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos borrar la temática'
  }
}
</script>
