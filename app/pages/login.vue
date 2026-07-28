<template>
  <div class="w-full max-w-sm flex flex-col gap-8">
    <div class="flex flex-col items-center gap-2 text-center">
      <div class="size-14 flex items-center justify-center bg-primary-100 rounded-2xl text-3xl">💡</div>
      <h1 class="text-2xl text-stone-900 font-semibold tracking-tight">Stupid Big Ideas</h1>
      <p class="text-sm text-stone-500">Entrá para anotar ideas</p>
    </div>

    <form class="w-full flex flex-col gap-5" @submit.prevent="onSubmit">
      <div class="flex flex-col gap-1.5">
        <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Email</label>
        <input
          v-model="email"
          type="email"
          placeholder="vos@motix.com"
          class="w-full bg-transparent border-b-2 border-stone-200 focus:border-primary-500 text-base text-stone-900 placeholder:text-stone-300 outline-none transition-colors py-2"
          autocomplete="email"
          :disabled="loading"
          required
        >
      </div>

      <div class="flex flex-col gap-1.5">
        <label class="text-xs text-stone-500 font-medium tracking-wide uppercase">Contraseña</label>
        <div class="flex items-center border-b-2 border-stone-200 focus-within:border-primary-500 transition-colors">
          <input
            v-model="password"
            :type="showPassword ? 'text' : 'password'"
            placeholder="••••••••"
            class="w-full flex-1 bg-transparent text-base text-stone-900 placeholder:text-stone-300 outline-none py-2"
            autocomplete="current-password"
            :disabled="loading"
            required
          >
          <button
            type="button"
            class="size-8 flex items-center justify-center text-stone-400 hover:text-stone-700 transition-colors"
            :aria-label="showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'"
            @click="showPassword = !showPassword"
          >
            <UIcon :name="showPassword ? 'i-lucide-eye-off' : 'i-lucide-eye'" class="size-4" />
          </button>
        </div>
      </div>

      <p
        v-if="errorMessage"
        class="bg-red-50 border border-red-200 rounded-lg text-sm text-red-700 px-3 py-2"
        role="alert"
      >
        {{ errorMessage }}
      </p>

      <div class="flex items-center justify-center mt-2">
        <button
          type="submit"
          :disabled="!email || !password || loading"
          :class="[
            'flex items-center gap-1.5 bg-primary-500 hover:bg-primary-600 disabled:bg-stone-200 rounded-full text-sm text-white disabled:text-stone-400 font-semibold disabled:cursor-not-allowed transition-all px-5 py-2.5',
            loading ? 'opacity-70' : ''
          ]"
        >
          <UIcon
            :name="loading ? 'i-lucide-loader-circle' : 'i-lucide-log-in'"
            :class="['size-4', loading ? 'animate-spin' : '']"
          />
          <span>{{ loading ? 'Entrando…' : 'Entrar' }}</span>
        </button>
      </div>

      <NuxtLink to="/" class="text-sm text-stone-400 hover:text-stone-700 text-center transition-colors">
        Volver al archivo
      </NuxtLink>
    </form>
  </div>
</template>

<script setup>
definePageMeta({ layout: 'auth' })

const { login, user } = useAuth()
const router = useRouter()
const route = useRoute()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)
const errorMessage = ref('')

watchEffect(() => {
  if (user.value) {
    const redirectTo = route.query.redirect_to?.toString() || '/'
    router.replace(redirectTo)
  }
})

const onSubmit = async () => {
  errorMessage.value = ''
  loading.value = true

  const result = await login(email.value.trim(), password.value)

  loading.value = false

  if (!result.ok) {
    errorMessage.value = result.message
    return
  }

  const redirectTo = route.query.redirect_to?.toString() || '/'
  await router.replace(redirectTo)
}
</script>
