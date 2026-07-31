<template>
  <div>
    <button
      type="button"
      class="flex items-center gap-1.5 rounded-full text-sm md:text-base text-stone-500 hover:text-stone-900 transition-colors px-2 py-1"
      @click="abrir"
    >
      <UIcon :name="esCalificar ? 'i-lucide-lightbulb' : 'i-lucide-pencil'" class="size-4" />
      <span>{{ esCalificar ? 'Calificar' : 'Editar' }}</span>
    </button>

    <USlideover v-model:open="open" :title="esCalificar ? 'Calificar la sesión' : 'Editar temática'">
      <template #body>
        <form class="flex flex-col gap-6" @submit.prevent="onSubmit">
          <template v-if="!esCalificar">
            <div class="flex flex-col gap-1.5">
              <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Temática</label>
              <input
                v-model="form.tematica"
                type="text"
                class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 outline-none transition-colors py-2"
                required
              >
            </div>

            <div class="flex flex-col gap-1.5">
              <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Fecha</label>
              <input
                v-model="form.fecha"
                type="date"
                class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 outline-none transition-colors py-2"
                required
              >
            </div>

            <div class="flex flex-col gap-1.5">
              <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Desafío</label>
              <textarea
                v-model="form.desafio"
                rows="3"
                placeholder="La consigna que nos planteamos esta semana…"
                class="w-full bg-transparent border border-stone-200 focus:border-primary-500 rounded-xl text-sm md:text-base text-stone-900 placeholder:text-stone-300 leading-relaxed resize-none outline-none transition-colors px-3 py-2.5"
              />
            </div>
          </template>

          <div v-else class="flex flex-col gap-5">
            <div class="flex flex-col gap-2">
              <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Puntaje de la sesión</label>
              <Lamparitas v-model="form.puntaje" />
            </div>

            <div v-for="campo in CAMPOS_EVAL" :key="campo.key" class="flex flex-col gap-1.5">
              <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">{{ campo.label }}</label>
              <textarea
                v-model="form[campo.key]"
                rows="3"
                :placeholder="campo.placeholder"
                class="w-full bg-transparent border border-stone-200 focus:border-primary-500 rounded-xl text-sm md:text-base text-stone-900 placeholder:text-stone-300 leading-relaxed resize-none outline-none transition-colors px-3 py-2.5"
              />
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
              :disabled="loading"
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
  modo: { type: String, default: 'datos' },
})
const emit = defineEmits(['saved'])

const { update } = useTematicas()

const esCalificar = computed(() => props.modo === 'calificar')

const CAMPOS_EVAL = [
  { key: 'destaques', label: 'Para destacar', placeholder: 'Lo que salió bien…' },
  { key: 'oportunidades', label: 'Para mejorar', placeholder: 'Lo que la próxima hacemos distinto…' },
]

const open = ref(false)
const loading = ref(false)
const errorMessage = ref('')

const form = ref({})

const abrir = () => {
  form.value = {
    tematica: props.tematica.tematica || '',
    fecha: props.tematica.fecha || '',
    desafio: props.tematica.desafio || '',
    puntaje: props.tematica.puntaje === null ? null : Number(props.tematica.puntaje),
    destaques: props.tematica.destaques || '',
    oportunidades: props.tematica.oportunidades || '',
  }
  errorMessage.value = ''
  open.value = true
}

const onSubmit = async () => {
  errorMessage.value = ''
  loading.value = true

  try {
    await update(props.tematica.id, esCalificar.value
      ? {
          puntaje: form.value.puntaje,
          destaques: form.value.destaques,
          oportunidades: form.value.oportunidades,
        }
      : {
          tematica: form.value.tematica,
          fecha: form.value.fecha,
          desafio: form.value.desafio,
        })
    open.value = false
    emit('saved')
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos guardar los cambios'
  } finally {
    loading.value = false
  }
}
</script>
