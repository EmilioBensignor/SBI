<template>
  <div>
    <button
      type="button"
      class="flex items-center gap-1.5 rounded-full text-sm text-stone-500 hover:text-stone-900 transition-colors px-2 py-1"
      @click="abrir"
    >
      <UIcon name="i-lucide-pencil" class="size-4" />
      <span>Editar</span>
    </button>

    <USlideover v-model:open="open" title="Editar idea">
      <template #body>
        <form class="flex flex-col gap-6" @submit.prevent="onSubmit">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Temática</label>
            <input
              v-model="form.tematica"
              type="text"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 outline-none transition-colors py-2"
              required
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Fecha</label>
            <input
              v-model="form.fecha"
              type="date"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 outline-none transition-colors py-2"
              required
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Título de la idea</label>
            <input
              v-model="form.titulo"
              type="text"
              placeholder="La máquina del tiempo"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-2"
            >
          </div>

          <div class="flex flex-col gap-2">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Imagen</label>
            <div v-if="imagenPreview" class="relative overflow-hidden bg-stone-100 rounded-xl">
              <img :src="imagenPreview" alt="" class="w-full aspect-4/3 object-cover">
              <button
                type="button"
                class="absolute top-2 right-2 size-8 flex items-center justify-center bg-white/90 hover:bg-white rounded-full text-stone-600 hover:text-red-600 transition-colors"
                aria-label="Quitar imagen"
                @click="quitarImagen"
              >
                <UIcon name="i-lucide-x" class="size-4" />
              </button>
            </div>
            <input
              type="file"
              accept="image/*"
              class="text-sm text-stone-500 file:mr-3 file:bg-stone-100 file:hover:bg-stone-200 file:border-0 file:rounded-full file:text-sm file:text-stone-700 file:font-medium file:transition-colors file:px-3 file:py-1.5"
              @change="onImagenChange"
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Desarrollo</label>
            <textarea
              v-model="form.desarrollo"
              rows="8"
              placeholder="El desarrollo profundo de la idea…"
              class="w-full bg-transparent border border-stone-200 focus:border-primary-500 rounded-xl text-sm text-stone-900 placeholder:text-stone-300 leading-relaxed outline-none transition-colors px-3 py-2.5"
            />
          </div>

          <div class="flex flex-col gap-3">
            <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Assets extra</label>

            <ul v-if="form.assets.length" class="flex flex-col gap-2">
              <li
                v-for="(asset, i) in form.assets"
                :key="`${asset.url}-${i}`"
                class="flex items-center gap-2 border border-stone-200 rounded-xl px-3 py-2"
              >
                <UIcon
                  :name="asset.tipo === 'file' ? 'i-lucide-paperclip' : 'i-lucide-link'"
                  class="size-4 shrink-0 text-stone-400"
                />
                <span class="flex-1 text-sm text-stone-700 truncate">{{ asset.label || asset.url }}</span>
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
              <div class="flex gap-2">
                <input
                  v-model="nuevoLink"
                  type="url"
                  placeholder="https://tiktok.com/…"
                  class="w-full flex-1 bg-transparent border-b border-stone-200 focus:border-primary-500 text-sm text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-1.5"
                >
                <input
                  v-model="nuevoLabel"
                  type="text"
                  placeholder="Etiqueta"
                  class="w-28 bg-transparent border-b border-stone-200 focus:border-primary-500 text-sm text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-1.5"
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
                class="text-sm text-stone-500 file:mr-3 file:bg-stone-100 file:hover:bg-stone-200 file:border-0 file:rounded-full file:text-sm file:text-stone-700 file:font-medium file:transition-colors file:px-3 file:py-1.5"
                @change="onArchivosChange"
              >
            </div>
          </div>

          <div class="flex flex-col gap-5 border-t border-stone-100 pt-5">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Puntaje</label>
              <input
                v-model.number="form.puntaje"
                type="number"
                min="1"
                max="10"
                placeholder="8"
                class="w-20 bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 tabular-nums outline-none transition-colors py-2"
              >
            </div>

            <div v-for="campo in CAMPOS_EVAL" :key="campo.key" class="flex flex-col gap-1.5">
              <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">{{ campo.label }}</label>
              <textarea
                v-model="form[campo.key]"
                rows="3"
                class="w-full bg-transparent border border-stone-200 focus:border-primary-500 rounded-xl text-sm text-stone-900 leading-relaxed outline-none transition-colors px-3 py-2.5"
              />
            </div>
          </div>

          <p
            v-if="errorMessage"
            class="bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 px-3 py-2"
            role="alert"
          >
            {{ errorMessage }}
          </p>

          <div class="flex items-center justify-end gap-2 border-t border-stone-100 pt-5">
            <button
              type="button"
              class="rounded-full text-sm text-stone-500 hover:text-stone-900 transition-colors px-3 py-2"
              :disabled="loading"
              @click="open = false"
            >
              Cancelar
            </button>
            <button
              type="submit"
              :disabled="loading"
              class="flex items-center gap-1.5 bg-primary-500 hover:bg-primary-600 disabled:bg-stone-200 rounded-full text-sm text-white disabled:text-stone-400 font-semibold disabled:cursor-not-allowed transition-all px-4 py-2"
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
  idea: { type: Object, required: true },
})
const emit = defineEmits(['saved'])

const { update } = useIdeas()
const { uploadFile, removeFiles } = useStorage()

const CAMPOS_EVAL = [
  { key: 'correcciones', label: 'Correcciones' },
  { key: 'destaques', label: 'Destaques' },
  { key: 'oportunidades', label: 'Oportunidades' },
]

const open = ref(false)
const loading = ref(false)
const errorMessage = ref('')

const form = ref({})
const imagenFile = ref(null)
const imagenPreview = ref('')
const imagenQuitada = ref(false)
const pathsAQuitar = ref([])
const nuevoLink = ref('')
const nuevoLabel = ref('')

const abrir = () => {
  form.value = {
    tematica: props.idea.tematica || '',
    fecha: props.idea.fecha || '',
    titulo: props.idea.titulo || '',
    desarrollo: props.idea.desarrollo || '',
    puntaje: props.idea.puntaje ?? null,
    correcciones: props.idea.correcciones || '',
    destaques: props.idea.destaques || '',
    oportunidades: props.idea.oportunidades || '',
    assets: [...(props.idea.assets || [])],
  }
  imagenFile.value = null
  imagenPreview.value = props.idea.imagen_url || ''
  imagenQuitada.value = false
  pathsAQuitar.value = []
  nuevoLink.value = ''
  nuevoLabel.value = ''
  errorMessage.value = ''
  open.value = true
}

const onImagenChange = (event) => {
  const file = event.target.files?.[0]
  if (!file) return
  imagenFile.value = file
  imagenPreview.value = URL.createObjectURL(file)
  imagenQuitada.value = false
}

const quitarImagen = () => {
  imagenFile.value = null
  imagenPreview.value = ''
  imagenQuitada.value = true
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
    form.value.assets.push({ tipo: 'file', url: '', path: '', label: file.name, pendiente: true, file })
  }
  event.target.value = ''
}

const quitarAsset = (index) => {
  const [asset] = form.value.assets.splice(index, 1)
  if (asset.tipo === 'file' && !asset.pendiente && asset.path) pathsAQuitar.value.push(asset.path)
}

const onSubmit = async () => {
  errorMessage.value = ''
  loading.value = true

  try {
    const patch = {
      tematica: form.value.tematica,
      fecha: form.value.fecha,
      titulo: form.value.titulo,
      desarrollo: form.value.desarrollo,
      puntaje: form.value.puntaje || null,
      correcciones: form.value.correcciones,
      destaques: form.value.destaques,
      oportunidades: form.value.oportunidades,
    }

    if (imagenFile.value) {
      const { publicUrl, path } = await uploadFile(imagenFile.value, props.idea.slug)
      patch.imagen_url = publicUrl
      patch.imagen_path = path
      if (props.idea.imagen_path) pathsAQuitar.value.push(props.idea.imagen_path)
    } else if (imagenQuitada.value) {
      patch.imagen_url = null
      patch.imagen_path = null
      if (props.idea.imagen_path) pathsAQuitar.value.push(props.idea.imagen_path)
    }

    const assets = []
    for (const asset of form.value.assets) {
      if (!asset.pendiente) {
        assets.push(asset)
        continue
      }
      if (!asset.file) continue
      const { publicUrl, path } = await uploadFile(asset.file, props.idea.slug)
      assets.push({ tipo: 'file', url: publicUrl, path, label: asset.label })
    }
    patch.assets = assets

    await update(props.idea.id, patch)

    try {
      await removeFiles(pathsAQuitar.value)
    } catch {
      pathsAQuitar.value = []
    }

    open.value = false
    emit('saved')
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos guardar los cambios'
  } finally {
    loading.value = false
  }
}
</script>
