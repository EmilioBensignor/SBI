<template>
  <section v-if="tieneAlgo" class="flex flex-col gap-5 border-t border-stone-100 pt-8">
    <div class="flex flex-wrap items-center gap-3">
      <h2 class="text-xs md:text-sm text-stone-400 font-medium tracking-wide uppercase">Evaluación</h2>
      <Lamparitas v-if="tematica.puntaje !== null" :model-value="Number(tematica.puntaje)" readonly />
    </div>

    <dl class="grid gap-5 sm:grid-cols-2">
      <div v-for="campo in camposCargados" :key="campo.key" class="flex flex-col gap-1.5">
        <dt class="text-xs md:text-sm text-stone-400 font-medium tracking-wide uppercase">{{ campo.label }}</dt>
        <dd class="text-sm md:text-base text-stone-700 leading-relaxed whitespace-pre-line">{{ campo.value }}</dd>
      </div>
    </dl>
  </section>
</template>

<script setup>
const props = defineProps({
  tematica: { type: Object, required: true },
})

const CAMPOS = [
  { key: 'destaques', label: 'Para destacar' },
  { key: 'oportunidades', label: 'Para mejorar' },
]

const camposCargados = computed(() =>
  CAMPOS
    .map((campo) => ({ ...campo, value: props.tematica[campo.key] }))
    .filter((campo) => campo.value)
)

const tieneAlgo = computed(() =>
  props.tematica.puntaje !== null || camposCargados.value.length > 0
)
</script>
