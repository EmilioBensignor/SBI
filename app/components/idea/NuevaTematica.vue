<template>
  <div>
    <button
      type="button"
      class="flex items-center gap-1.5 bg-stone-900 hover:bg-stone-700 rounded-full text-sm md:text-base text-white font-medium transition-colors px-4 py-2"
      @click="open = true"
    >
      <UIcon name="i-lucide-plus" class="size-4" />
      <span>Nueva temática</span>
    </button>

    <UModal v-model:open="open" title="Nueva temática">
      <template #body>
        <form class="flex flex-col gap-5" @submit.prevent="onSubmit">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Temática</label>
            <input
              v-model="tematica"
              type="text"
              placeholder="Nostalgia"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-2"
              :disabled="loading"
              required
              autofocus
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Fecha</label>
            <input
              v-model="fecha"
              type="date"
              class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 outline-none transition-colors py-2"
              :disabled="loading"
              required
            >
          </div>

          <div class="flex flex-col gap-1.5">
            <label class="text-xs md:text-sm text-stone-500 font-medium tracking-wide uppercase">Desafío</label>
            <textarea
              v-model="desafio"
              rows="3"
              placeholder="Opcional: la consigna de esta semana…"
              class="w-full bg-transparent border border-stone-200 focus:border-primary-500 rounded-xl text-sm md:text-base text-stone-900 placeholder:text-stone-300 leading-relaxed resize-none outline-none transition-colors px-3 py-2.5"
              :disabled="loading"
            />
          </div>

          <p
            v-if="errorMessage"
            class="bg-red-50 border border-red-200 rounded-lg text-sm md:text-base text-red-700 px-3 py-2"
            role="alert"
          >
            {{ errorMessage }}
          </p>

          <div class="flex items-center justify-end gap-2">
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
              :disabled="!tematica.trim() || loading"
              class="flex items-center gap-1.5 bg-primary-500 hover:bg-primary-600 disabled:bg-stone-200 rounded-full text-sm md:text-base text-white disabled:text-stone-400 font-semibold disabled:cursor-not-allowed transition-all px-4 py-2"
            >
              <UIcon
                :name="loading ? 'i-lucide-loader-circle' : 'i-lucide-check'"
                :class="['size-4', loading ? 'animate-spin' : '']"
              />
              <span>{{ loading ? 'Creando…' : 'Crear' }}</span>
            </button>
          </div>
        </form>
      </template>
    </UModal>
  </div>
</template>

<script setup>
const emit = defineEmits(['created'])

const { create } = useTematicas()

const open = ref(false)
const tematica = ref('')
const fecha = ref(new Date().toISOString().slice(0, 10))
const desafio = ref('')
const loading = ref(false)
const errorMessage = ref('')

const onSubmit = async () => {
  errorMessage.value = ''
  loading.value = true

  try {
    const creada = await create({
      tematica: tematica.value,
      fecha: fecha.value,
      desafio: desafio.value,
    })
    open.value = false
    tematica.value = ''
    desafio.value = ''
    emit('created', creada)
  } catch (e) {
    errorMessage.value = e.message || 'No pudimos crear la temática'
  } finally {
    loading.value = false
  }
}
</script>
