<template>
  <div>
    <button
      v-if="idea"
      type="button"
      class="flex items-center gap-1.5 rounded-full text-sm md:text-base text-stone-500 hover:text-stone-900 transition-colors px-2 py-1"
      @click="abrir"
    >
      <UIcon name="i-lucide-pencil" class="size-4" />
      <span>Editar</span>
    </button>

    <button
      v-else
      type="button"
      class="flex items-center gap-1.5 bg-stone-900 hover:bg-stone-700 rounded-full text-sm md:text-base text-white font-medium transition-colors px-4 py-2"
      @click="abrir"
    >
      <UIcon name="i-lucide-plus" class="size-4" />
      <span>Agregar idea</span>
    </button>

    <USlideover v-model:open="open" :title="idea ? 'Editar idea' : 'Nueva idea'">
      <template #body>
        <form class="flex flex-col gap-6" @submit.prevent="onSubmit">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Título</label>
            <input
              v-model="form.titulo"
              type="text"
              placeholder="La máquina del tiempo"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-2"
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Marca</label>
            <input
              v-model="form.marca"
              type="text"
              placeholder="Coca-Cola"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-2"
            >
          </div>

          <div v-for="campo in CAMPOS" :key="campo.key" class="flex flex-col gap-1.5">
            <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">{{ campo.label }}</label>
            <textarea
              v-model="form[campo.key]"
              :rows="campo.rows"
              :placeholder="campo.placeholder"
              class="w-full bg-transparent border border-stone-200 focus:border-primary-500 rounded-xl text-sm md:text-base text-stone-900 placeholder:text-stone-300 leading-relaxed resize-none outline-none transition-colors px-3 py-2.5"
            />
          </div>

          <div class="flex flex-col gap-3">
            <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Imágenes, audios y links</label>

            <ul v-if="form.assets.length" class="flex flex-col gap-2">
              <li
                v-for="(asset, i) in form.assets"
                :key="`${asset.url}-${i}`"
                class="flex items-center gap-2 border border-stone-200 rounded-xl px-3 py-2"
              >
                <UIcon :name="ICONOS[asset.tipo] || 'i-lucide-paperclip'" class="size-4 shrink-0 text-stone-400" />
                <span class="flex-1 text-sm md:text-base text-stone-700 truncate">{{ asset.label || asset.url }}</span>
                <button
                  type="button"
                  class="size-7 flex items-center justify-center text-stone-400 hover:text-red-600 transition-colors"
                  aria-label="Quitar asset"
                  @click="quitarAsset(i)"
                >
                  <UIcon name="i-lucide-x" class="size-3.5" />
                </button>
              </li>
            </ul>

            <div class="flex flex-col gap-2 border border-dashed border-stone-200 rounded-xl p-3">
              <div class="flex flex-wrap items-end gap-2">
                <input
                  v-model="nuevoLink"
                  type="url"
                  placeholder="https://tiktok.com/…"
                  class="w-full sm:w-auto sm:flex-1 bg-transparent border-b border-stone-200 focus:border-primary-500 text-sm md:text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-1.5"
                >
                <input
                  v-model="nuevoLabel"
                  type="text"
                  placeholder="Etiqueta"
                  class="w-24 flex-1 sm:w-28 sm:flex-none bg-transparent border-b border-stone-200 focus:border-primary-500 text-sm md:text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-1.5"
                >
                <button
                  type="button"
                  :disabled="!nuevoLink.trim()"
                  class="shrink-0 size-8 flex items-center justify-center bg-stone-100 hover:bg-stone-200 disabled:bg-stone-50 rounded-full text-stone-600 disabled:text-stone-300 transition-colors"
                  aria-label="Agregar link"
                  @click="agregarLink"
                >
                  <UIcon name="i-lucide-plus" class="size-4" />
                </button>
              </div>

              <input
                type="file"
                multiple
                accept="image/*,audio/*,.pdf,.doc,.docx,.ppt,.pptx"
                class="w-full text-sm md:text-base text-stone-500 file:mr-3 file:bg-stone-100 file:hover:bg-stone-200 file:border-0 file:rounded-full file:text-sm file:md:text-base file:text-stone-700 file:font-medium file:transition-colors file:px-3 file:py-1.5"
                @change="onArchivosChange"
              >
            </div>
          </div>

          <p
            v-if="errorMessage"
            class="bg-red-50 border border-red-200 rounded-lg text-sm md:text-base text-red-700 px-3 py-2"
            role="alert"
          >
            {{ errorMessage }}
          </p>

          <div class="flex items-center justify-end gap-2 border-t border-stone-100 pt-5">
            <button
              type="button"
              class="rounded-full text-sm md:text-base text-stone-500 hover:text-stone-900 transition-colors px-3 py-2"
              :disabled="loading"
              @click="open = false"
            >
              Cancelar
            </button>
            <button
              type="submit"
              :disabled="loading || !tieneIdentidad"
              class="flex items-center gap-1.5 bg-primary-500 hover:bg-primary-600 disabled:bg-stone-200 rounded-full text-sm md:text-base text-white disabled:text-stone-400 font-semibold disabled:cursor-not-allowed transition-all px-4 py-2"
            >
              <UIcon
                :name="loading ? 'i-lucide-loader-circle' : 'i-lucide-check'"
                :class="['size-4', loading ? 'animate-spin' : '']"
              />
              <span>{{ loading ? 'Guardando…' : 'Guardar' }}</span>
            </button>
          </div>
        </form>
      </template>
    </USlideover>
  </div>
</template>

<script setup>
const props = defineProps({
  tematica: { type: Object, required: true },
  idea: { type: Object, default: null },
})
const emit = defineEmits(['saved'])

const { create, update } = useIdeas()
const { uploadFile, removeFiles, tipoDeArchivo } = useStorage()

const CAMPOS = [
  { key: 'insight', label: 'Insight', rows: 3, placeholder: 'La verdad humana detrás de la idea…' },
  { key: 'concepto', label: 'Concepto', rows: 3, placeholder: 'Cómo se traduce en una pieza…' },
  { key: 'anotaciones', label: 'Anotaciones', rows: 5, placeholder: 'Lo que salió en el debate…' },
]

const ICONOS = {
  imagen: 'i-lucide-image',
  audio: 'i-lucide-audio-lines',
  link: 'i-lucide-link',
  file: 'i-lucide-paperclip',
}

const open = ref(false)
const loading = ref(false)
const errorMessage = ref('')

const form = ref({ assets: [] })
const pathsAQuitar = ref([])
const nuevoLink = ref('')
const nuevoLabel = ref('')

const tieneIdentidad = computed(() =>
  Boolean(form.value.titulo?.trim() || form.value.marca?.trim())
)

const abrir = () => {
  form.value = {
    titulo: props.idea?.titulo || '',
    marca: props.idea?.marca || '',
    insight: props.idea?.insight || '',
    concepto: props.idea?.concepto || '',
    anotaciones: props.idea?.anotaciones || '',
    assets: [...(props.idea?.assets || [])],
  }
  pathsAQuitar.value = []
  nuevoLink.value = ''
  nuevoLabel.value = ''
  errorMessage.value = ''
  open.value = true
}

const agregarLink = () => {
  const url = nuevoLink.value.trim()
  if (!url) return
  form.value.assets.push({ tipo: 'link', url, label: nuevoLabel.value.trim() || '' })
  nuevoLink.value = ''
  nuevoLabel.value = ''
}

const onArchivosChange = (event) => {
  const files = Array.from(event.target.files || [])
  for (const file of files) {
    form.value.assets.push({
      tipo: tipoDeArchivo(file),
      url: '',
      path: '',
      label: file.name,
      pendiente: true,
      file,
    })
  }
  event.target.value = ''
}

const quitarAsset = (index) => {
  const [asset] = form.value.assets.splice(index, 1)
  if (!asset.pendiente && asset.path) pathsAQuitar.value.push(asset.path)
}

const onSubmit = async () => {
  errorMessage.value = ''
  loading.value = true

  try {
    const assets = []
    for (const asset of form.value.assets) {
      if (!asset.pendiente) {
        assets.push(asset)
        continue
      }
      if (!asset.file) continue
      const { publicUrl, path } = await uploadFile(asset.file, props.tematica.slug)
      assets.push({ tipo: asset.tipo, url: publicUrl, path, label: asset.label })
    }

    const patch = {
      titulo: form.value.titulo,
      marca: form.value.marca,
      insight: form.value.insight,
      concepto: form.value.concepto,
      anotaciones: form.value.anotaciones,
      assets,
    }

    if (props.idea) await update(props.idea.id, patch)
    else await create(props.tematica.id, patch)

    try {
      await removeFiles(pathsAQuitar.value)
    } catch {
      pathsAQuitar.value = []
    }

    open.value = false
    emit('saved')
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos guardar la idea'
  } finally {
    loading.value = false
  }
}
</script>
