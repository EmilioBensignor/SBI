<template>
  <section v-if="assets.length" class="flex flex-col gap-3">
    <h2 class="text-xs text-stone-400 font-medium tracking-wide uppercase">Assets</h2>
    <ul class="flex flex-col gap-2">
      <li v-for="(asset, i) in assets" :key="`${asset.url}-${i}`">
        <a
          :href="href(asset.url)"
          target="_blank"
          rel="noopener noreferrer"
          class="group flex items-center gap-2.5 border border-stone-200 hover:border-stone-300 rounded-xl transition-colors px-3 py-2.5"
        >
          <UIcon
            :name="asset.tipo === 'file' ? 'i-lucide-paperclip' : 'i-lucide-link'"
            class="size-4 shrink-0 text-stone-400"
          />
          <span class="flex-1 text-sm text-stone-700 group-hover:text-stone-900 truncate transition-colors">
            {{ etiqueta(asset) }}
          </span>
          <UIcon name="i-lucide-arrow-up-right" class="size-3.5 shrink-0 text-stone-300" />
        </a>
      </li>
    </ul>
  </section>
</template>

<script setup>
const props = defineProps({
  assets: { type: Array, default: () => [] },
})

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

const assets = computed(() => (props.assets || []).filter((a) => a?.url))
</script>
