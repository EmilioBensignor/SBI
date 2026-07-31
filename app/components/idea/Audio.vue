<template>
  <div class="flex items-center gap-2.5 border border-stone-200 rounded-xl px-3 py-2.5">
    <button
      type="button"
      class="size-9 flex items-center justify-center shrink-0 bg-stone-100 hover:bg-stone-200 rounded-full text-stone-700 transition-colors"
      :aria-label="sonando ? 'Pausar' : 'Reproducir'"
      :aria-pressed="sonando"
      @click="alternar"
    >
      <UIcon :name="sonando ? 'i-lucide-pause' : 'i-lucide-play'" class="size-4" />
    </button>

    <span v-if="label" class="flex-1 text-sm md:text-base text-stone-700 truncate">{{ label }}</span>
  </div>
</template>

<script setup>
const props = defineProps({
  url: { type: String, required: true },
  label: { type: String, default: '' },
})

const sonando = ref(false)

let audio = null

const alternar = () => {
  if (!audio) {
    audio = new Audio(props.url)
    audio.addEventListener('ended', () => { sonando.value = false })
    audio.addEventListener('pause', () => { sonando.value = false })
    audio.addEventListener('play', () => { sonando.value = true })
  }

  if (audio.paused) audio.play()
  else audio.pause()
}

onBeforeUnmount(() => {
  audio?.pause()
  audio = null
})
</script>
