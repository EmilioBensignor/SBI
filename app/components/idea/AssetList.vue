<template>
  <div v-if="imagenes.length || audios.length || enlaces.length" class="flex flex-col gap-4">
    <div v-if="imagenes.length" class="grid gap-3" :class="imagenes.length > 1 ? 'sm:grid-cols-2' : ''">
      <a
        v-for="(asset, i) in imagenes"
        :key="`img-${asset.url}-${i}`"
        :href="href(asset.url)"
        target="_blank"
        rel="noopener noreferrer"
        class="overflow-hidden bg-stone-100 rounded-xl"
      >
        <img
          :src="thumb(asset.url, 1280)"
          :alt="asset.label || ''"
          class="w-full object-cover"
          loading="lazy"
          decoding="async"
        >
      </a>
    </div>

    <div v-if="audios.length" class="flex flex-col gap-2">
      <IdeaAudio
        v-for="(asset, i) in audios"
        :key="`audio-${asset.url}-${i}`"
        :url="asset.url"
        :label="asset.label"
      />
    </div>

    <ul v-if="enlaces.length" class="flex flex-col gap-2">
      <li v-for="(asset, i) in enlaces" :key="`link-${asset.url}-${i}`">
        <a
          :href="href(asset.url)"
          target="_blank"
          rel="noopener noreferrer"
          class="group flex items-center gap-2.5 border border-stone-200 hover:border-stone-300 rounded-xl transition-colors px-3 py-2.5"
        >
          <UIcon
            :name="asset.tipo === 'link' ? 'i-lucide-link' : 'i-lucide-paperclip'"
            class="size-4 shrink-0 text-stone-400"
          />
          <span class="flex-1 text-sm md:text-base text-stone-700 group-hover:text-stone-900 truncate transition-colors">
            {{ etiqueta(asset) }}
          </span>
          <UIcon name="i-lucide-arrow-up-right" class="size-3.5 shrink-0 text-stone-300" />
        </a>
      </li>
    </ul>
  </div>
</template>

<script setup>
const props = defineProps({
  assets: { type: Array, default: () => [] },
})

const { thumb } = useStorage()

const PROTOCOLOS = ['http:', 'https:', 'mailto:']

const href = (url) => {
  try {
    return PROTOCOLOS.includes(new URL(url).protocol) ? url : '#'
  } catch {
    return '#'
  }
}

const etiqueta = (asset) => {
  if (asset.label) return asset.label
  try {
    return new URL(asset.url).hostname.replace(/^www\./, '')
  } catch {
    return asset.url
  }
}

const cargados = computed(() => (props.assets || []).filter((a) => a?.url))

const imagenes = computed(() => cargados.value.filter((a) => a.tipo === 'imagen'))
const audios = computed(() => cargados.value.filter((a) => a.tipo === 'audio'))
const enlaces = computed(() => cargados.value.filter((a) => a.tipo !== 'imagen' && a.tipo !== 'audio'))
</script>
