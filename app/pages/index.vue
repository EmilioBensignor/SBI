<template>
  <div class="flex flex-col gap-10">
    <NuxtLink
      v-if="user && enCurso"
      :to="`/tematica/${enCurso.slug}`"
      class="group flex flex-col sm:flex-row sm:flex-wrap sm:items-center justify-between gap-3 border border-amber-200 hover:border-amber-300 rounded-2xl bg-amber-50/60 transition-colors px-4 iph:px-5 py-4"
    >
      <div class="min-w-0 flex flex-col gap-0.5">
        <span class="text-[10px] md:text-sm text-amber-700 font-medium tracking-wide uppercase">Temática</span>
        <span class="text-xl iph:text-2xl md:text-3xl text-stone-900 font-semibold tracking-tight text-balance">{{ enCurso.tematica }}</span>
      </div>
      <span class="shrink-0 flex items-center gap-1.5 text-sm md:text-base text-stone-500 group-hover:text-stone-900 transition-colors">
        Anotar ideas
        <UIcon name="i-lucide-arrow-right" class="size-4" />
      </span>
    </NuxtLink>

    <section class="flex flex-col gap-6">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div class="w-full sm:max-w-xs flex items-center gap-2 border-b border-stone-200 focus-within:border-primary-500 transition-colors">
          <UIcon name="i-lucide-search" class="size-4 text-stone-400" />
          <input
            v-model="query"
            type="search"
            placeholder="Buscar una temática…"
            class="w-full flex-1 bg-transparent text-sm md:text-base text-stone-900 placeholder:text-stone-300 outline-none py-2"
            aria-label="Buscar temáticas"
          >
        </div>

        <IdeaNuevaTematica v-if="user" @created="onCreated" />
      </div>

      <p
        v-if="errorMessage"
        class="bg-red-50 border border-red-200 rounded-lg text-sm md:text-base text-red-700 px-3 py-2"
        role="alert"
      >
        {{ errorMessage }}
      </p>

      <div v-if="pending" class="grid gap-x-6 gap-y-6 md:grid-cols-2 lg:grid-cols-3">
        <div v-for="n in 6" :key="n" class="flex flex-col gap-2 border border-stone-200 rounded-2xl px-5 py-5">
          <USkeleton class="h-3 w-28" />
          <USkeleton class="h-6 w-3/4" />
          <USkeleton class="h-4 w-full" />
          <USkeleton class="h-3 w-16 mt-1" />
        </div>
      </div>

      <EmptyState
        v-else-if="!listadas.length && !query"
        title="Todavía no hay temáticas"
        description="Cuando cargues la primera temática va a aparecer acá."
      />

      <EmptyState
        v-else-if="!filtradas.length"
        icon="i-lucide-search-x"
        title="Sin resultados"
        :description="`No encontramos nada para “${query}”.`"
      />

      <div v-else class="grid gap-x-6 gap-y-6 md:grid-cols-2 lg:grid-cols-3">
        <IdeaCard v-for="tematica in filtradas" :key="tematica.id" :tematica="tematica" />
      </div>
    </section>
  </div>
</template>

<script setup>
const { user } = useAuth()
const { fetchAll, estaCerrada } = useTematicas()

const query = ref('')
const errorMessage = ref('')

const { data: tematicas, status, refresh } = await useAsyncData(
  'tematicas',
  () => fetchAll(),
  { default: () => [], watch: [user], lazy: true }
)

const pending = computed(() => status.value === 'pending')

const enCurso = computed(() => tematicas.value.find((t) => !estaCerrada(t)) || null)

const listadas = computed(() =>
  enCurso.value ? tematicas.value.filter((t) => t.id !== enCurso.value.id) : tematicas.value
)

const filtradas = computed(() => {
  const q = query.value.trim().toLowerCase()
  if (!q) return listadas.value
  return listadas.value.filter((tematica) =>
    [tematica.tematica, tematica.desafio]
      .filter(Boolean)
      .some((field) => field.toLowerCase().includes(q))
  )
})

const onCreated = async (tematica) => {
  errorMessage.value = ''
  await refresh()
  await navigateTo(`/tematica/${tematica.slug}`)
}
</script>
