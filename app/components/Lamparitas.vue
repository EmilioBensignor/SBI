<template>
  <div
    :class="['flex items-center gap-1', readonly ? '' : 'w-fit']"
    :role="readonly ? 'img' : 'slider'"
    :aria-label="readonly ? `Puntaje ${etiqueta} de 5` : 'Puntaje de la sesión'"
    :aria-valuenow="readonly ? undefined : (modelValue ?? 0)"
    :aria-valuemin="readonly ? undefined : 0"
    :aria-valuemax="readonly ? undefined : 5"
    :tabindex="readonly ? undefined : 0"
    @keydown="onKeydown"
  >
    <div
      v-for="n in 5"
      :key="n"
      :class="['relative size-6', readonly ? '' : 'cursor-pointer']"
    >
      <UIcon name="i-lucide-lightbulb" class="size-6 text-stone-200" />
      <div
        class="absolute inset-0 overflow-hidden"
        :style="{ width: `${relleno(n) * 100}%` }"
      >
        <UIcon name="i-lucide-lightbulb" class="size-6 text-amber-400" />
      </div>

      <template v-if="!readonly">
        <button
          type="button"
          class="absolute inset-y-0 left-0 w-1/2"
          :aria-label="`${n - 0.5} lamparitas`"
          @click="emit('update:modelValue', n - 0.5)"
        />
        <button
          type="button"
          class="absolute inset-y-0 right-0 w-1/2"
          :aria-label="`${n} lamparitas`"
          @click="emit('update:modelValue', n)"
        />
      </template>
    </div>

    <span v-if="modelValue !== null" class="text-sm md:text-base text-stone-500 tabular-nums pl-1.5">
      {{ etiqueta }}
    </span>

    <button
      v-if="!readonly && modelValue !== null"
      type="button"
      class="flex items-center text-stone-300 hover:text-red-600 transition-colors pl-1"
      aria-label="Quitar puntaje"
      @click="emit('update:modelValue', null)"
    >
      <UIcon name="i-lucide-x" class="size-3.5" />
    </button>
  </div>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: Number, default: null },
  readonly: { type: Boolean, default: false },
})
const emit = defineEmits(['update:modelValue'])

const etiqueta = computed(() => {
  const valor = props.modelValue ?? 0
  return Number.isInteger(valor) ? String(valor) : valor.toFixed(1)
})

const relleno = (n) => {
  const valor = props.modelValue ?? 0
  if (valor >= n) return 1
  if (valor > n - 1) return valor - (n - 1)
  return 0
}

const onKeydown = (event) => {
  if (props.readonly) return
  const valor = props.modelValue ?? 0
  if (event.key === 'ArrowRight' || event.key === 'ArrowUp') {
    event.preventDefault()
    emit('update:modelValue', Math.min(5, valor + 0.5))
  }
  if (event.key === 'ArrowLeft' || event.key === 'ArrowDown') {
    event.preventDefault()
    emit('update:modelValue', Math.max(0, valor - 0.5))
  }
}
</script>
