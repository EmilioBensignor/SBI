<template>
  <NuxtLink
    :to="`/tematica/${tematica.slug}`"
    class="group flex flex-col gap-2 border border-stone-200 hover:border-stone-300 rounded-2xl transition-colors px-5 py-5"
  >
    <div class="flex items-center gap-2">
      <span class="text-xs md:text-sm text-stone-400 tracking-wide uppercase">{{ fechaLarga }}</span>
      <span
        v-if="!cerrada"
        class="bg-amber-50 rounded-full text-[10px] md:text-sm text-amber-700 font-medium tracking-wide uppercase px-2 py-0.5"
      >
        En curso
      </span>
    </div>

    <h3 class="text-lg text-stone-900 font-medium leading-snug group-hover:text-primary-600 transition-colors">
      {{ tematica.tematica }}
    </h3>

    <p v-if="tematica.desafio" class="text-sm md:text-base text-stone-500 leading-relaxed line-clamp-2">
      {{ tematica.desafio }}
    </p>

    <span class="flex items-center gap-1.5 text-xs md:text-sm text-stone-400 pt-1">
      <UIcon name="i-lucide-lightbulb" class="size-3.5" />
      {{ cantidad === 1 ? '1 idea' : `${cantidad} ideas` }}
    </span>
  </NuxtLink>
</template>

<script setup>
const props = defineProps({
  tematica: { type: Object, required: true },
})

const { estaCerrada } = useTematicas()

const cantidad = computed(() => props.tematica.ideas?.length || 0)

const cerrada = computed(() => estaCerrada(props.tematica))

const fechaLarga = computed(() =>
  new Date(`${props.tematica.fecha}T12:00:00`).toLocaleDateString('es-AR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
)
</script>
