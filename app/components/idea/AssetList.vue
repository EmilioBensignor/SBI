<template>
  <div v-if="imagenes.length || audios.length || enlaces.length" class="flex flex-col gap-4">
    <div v-if="imagenes.length" class="grid gap-3" :class="imagenes.length > 1 ? 'md:grid-cols-2' : ''">
      <button
        v-for="(asset, i) in imagenes"
        :key="`img-${asset.url}-${i}`"
        type="button"
        class="overflow-hidden bg-stone-100 rounded-xl"
        :aria-label="asset.label ? `Ampliar ${asset.label}` : 'Ampliar imagen'"
        @click="abrir(asset)"
      >
        <img
          :src="thumb(asset.url, 1280)"
          :alt="asset.label || ''"
          class="w-full object-cover"
          loading="lazy"
          decoding="async"
          @error="onImgError($event, asset.url)"
        >
      </button>
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

    <dialog
      ref="visorRef"
      class="w-full max-w-6xl m-auto bg-transparent backdrop:bg-stone-900/80 p-4"
      @click="onBackdrop"
      @close="ampliada = null"
    >
      <img
        v-if="ampliada"
        :src="srcVisor"
        :alt="ampliada.label || ''"
        class="w-auto max-w-full max-h-[85dvh] mx-auto object-contain rounded-xl"
        @error="onImgError($event, ampliada.url)"
      >

      <button
        type="button"
        class="size-9 flex items-center justify-center fixed top-4 right-4 bg-stone-900/60 hover:bg-stone-900 rounded-full text-white transition-colors"
        aria-label="Cerrar"
        @click="cerrar"
      >
        <UIcon name="i-lucide-x" class="size-5" />
      </button>
    </dialog>
  </div>
</template>

<script setup>
const props = defineProps({
  assets: { type: Array, default: () => [] },
})

const { thumb } = useStorage()

const visorRef = ref(null)
const ampliada = ref(null)
const srcVisor = ref('')

const PROTOCOLOS = ['http:', 'https:', 'mailto:']

const abrir = (asset) => {
  ampliada.value = asset
  srcVisor.value = thumb(asset.url, 1280)
  visorRef.value?.showModal()

  const grande = thumb(asset.url, 2048)
  const previa = new Image()
  previa.onload = () => {
    if (ampliada.value === asset) srcVisor.value = grande
  }
  previa.src = grande
}

const cerrar = () => {
  visorRef.value?.close()
}

const onBackdrop = (event) => {
  if (event.target === visorRef.value) cerrar()
}

const href = (url) => {
  try {
    return PROTOCOLOS.includes(new URL(url).protocol) ? url : '#'
  } catch {
    return '#'
  }
}

const onImgError = (event, url) => {
  if (event.target.src === url) return
  event.target.src = url
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
