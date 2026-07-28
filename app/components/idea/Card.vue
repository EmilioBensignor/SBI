<template>
  <NuxtLink
    :to="`/idea/${idea.slug}`"
    class="group flex flex-col gap-3"
  >
    <div class="aspect-4/3 overflow-hidden bg-stone-100 rounded-2xl">
      <img
        v-if="idea.imagen_url"
        :src="thumb(idea.imagen_url, 640)"
        :alt="idea.titulo || idea.tematica"
        class="size-full object-cover group-hover:scale-[1.03] transition-transform duration-500"
        width="640"
        height="480"
        loading="lazy"
        decoding="async"
      >
      <div v-else class="size-full flex items-center justify-center">
        <UIcon name="i-lucide-image-off" class="size-6 text-stone-300" />
      </div>
    </div>

    <div class="flex flex-col gap-1">
      <div class="flex items-center gap-2">
        <span class="text-xs md:text-sm text-stone-400 tracking-wide uppercase">{{ idea.tematica }}</span>
        <span
          v-if="!idea.titulo"
          class="bg-amber-50 rounded-full text-[10px] md:text-sm text-amber-700 font-medium tracking-wide uppercase px-2 py-0.5"
        >
          En curso
        </span>
      </div>
      <h3 class="text-lg text-stone-900 font-medium leading-snug group-hover:text-primary-600 transition-colors">
        {{ idea.titulo || 'Sin idea ganadora todavía' }}
      </h3>
      <span class="text-xs md:text-base text-stone-400">{{ fechaLarga }}</span>
    </div>
  </NuxtLink>
</template>

<script setup>
const props = defineProps({
  idea: { type: Object, required: true },
})

const { thumb } = useStorage()

const fechaLarga = computed(() =>
  new Date(`${props.idea.fecha}T12:00:00`).toLocaleDateString('es-AR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  })
)
</script>
