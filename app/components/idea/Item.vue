<template>
  <article class="flex flex-col gap-4 border-t border-stone-100 pt-6 md:pt-8">
    <header class="flex flex-wrap items-start justify-between gap-3">
      <div class="min-w-0 flex flex-col gap-1">
        <span v-if="idea.marca" class="text-xs md:text-sm text-stone-400 font-medium tracking-wide uppercase">
          {{ idea.titulo }}
        </span>
        <h3 class="text-lg iph:text-xl md:text-2xl text-stone-900 font-semibold tracking-tight leading-tight text-balance">
          {{ idea.marca || idea.titulo }}
        </h3>
      </div>

      <div v-if="user" class="flex items-center gap-3 shrink-0">
        <IdeaForm :tematica="tematica" :idea="idea" @saved="emit('saved')" />
        <button
          type="button"
          class="flex items-center gap-1.5 rounded-full text-sm md:text-base text-stone-400 hover:text-red-600 transition-colors px-2 py-1"
          @click="emit('delete', idea)"
        >
          <UIcon name="i-lucide-trash-2" class="size-4" />
          <span>Borrar</span>
        </button>
      </div>
    </header>

    <div v-for="campo in camposCargados" :key="campo.key" class="max-w-prose flex flex-col gap-1.5">
      <h4 class="text-xs md:text-sm text-stone-400 font-medium tracking-wide uppercase">{{ campo.label }}</h4>
      <p class="text-base text-stone-700 leading-relaxed whitespace-pre-line">{{ campo.value }}</p>
    </div>

    <IdeaAssetList :assets="idea.assets" />
  </article>
</template>

<script setup>
const props = defineProps({
  idea: { type: Object, required: true },
  tematica: { type: Object, required: true },
})
const emit = defineEmits(['saved', 'delete'])

const { user } = useAuth()

const CAMPOS = [
  { key: 'insight', label: 'Insight' },
  { key: 'concepto', label: 'Concepto' },
  { key: 'anotaciones', label: 'Anotaciones' },
]

const camposCargados = computed(() =>
  CAMPOS
    .map((campo) => ({ ...campo, value: props.idea[campo.key] }))
    .filter((campo) => campo.value)
)
</script>
