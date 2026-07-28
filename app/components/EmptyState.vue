<template>
  <div class="flex flex-col items-center gap-2 border border-dashed border-stone-200 rounded-2xl text-center px-6 py-16">
    <UIcon :name="icon" class="size-8 text-stone-300" />
    <p class="text-base text-stone-700 font-medium">{{ title }}</p>
    <p v-if="description" class="text-sm md:text-base text-stone-500">{{ description }}</p>
  </div>
</template>

<script setup>
defineProps({
  icon: { type: String, default: 'i-lucide-lightbulb' },
  title: { type: String, required: true },
  description: { type: String, default: '' },
})
</script>
