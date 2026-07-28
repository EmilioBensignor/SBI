<template>
  <section v-if="tieneAlgo" class="flex flex-col gap-5 border-t border-stone-100 pt-8">
    <div class="flex items-center gap-3">
      <h2 class="text-xs md:text-sm text-stone-400 font-medium tracking-wide uppercase">Evaluación</h2>
      <div v-if="idea.puntaje" class="flex items-baseline gap-0.5">
        <span class="text-2xl text-stone-900 font-semibold tabular-nums">{{ idea.puntaje }}</span>
        <span class="text-sm md:text-base text-stone-400">/10</span>
      </div>
    </div>

    <dl class="grid gap-5 sm:grid-cols-3">
      <div v-for="campo in camposCargados" :key="campo.key" class="flex flex-col gap-1.5">
        <dt class="text-xs md:text-sm text-stone-400 font-medium tracking-wide uppercase">{{ campo.label }}</dt>
        <dd class="text-sm md:text-base text-stone-700 leading-relaxed whitespace-pre-line">{{ campo.value }}</dd>
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
