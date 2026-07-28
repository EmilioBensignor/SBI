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

    <NuxtLink
      v-if="user && enCurso"
      :to="`/idea/${enCurso.slug}`"
      class="group flex flex-wrap items-center justify-between gap-3 border border-amber-200 hover:border-amber-300 rounded-2xl bg-amber-50/60 transition-colors px-5 py-4"
    >
      <div class="flex flex-col gap-0.5">
        <span class="text-[10px] text-amber-700 font-medium tracking-wide uppercase">Temática en curso</span>
        <span class="text-lg text-stone-900 font-medium">{{ enCurso.tematica }}</span>
      </div>
      <span class="flex items-center gap-1.5 text-sm text-stone-500 group-hover:text-stone-900 transition-colors">
        Completar la idea ganadora
        <UIcon name="i-lucide-arrow-right" class="size-4" />
      </span>
    </NuxtLink>

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
        v-else-if="!listadas.length && !query"
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
const { fetchAll, enCurso: esEnCurso } = useIdeas()

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

const enCurso = computed(() => ideas.value.find(esEnCurso) || null)

const listadas = computed(() =>
  enCurso.value ? ideas.value.filter((idea) => idea.id !== enCurso.value.id) : ideas.value
)

const filtradas = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return listadas.value
  return listadas.value.filter((idea) =>
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
