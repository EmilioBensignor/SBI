<template>
  <div class="min-h-dvh bg-white">
    <header class="flex justify-between items-center sticky top-0 z-10 border-b border-stone-100 bg-white/90 backdrop-blur px-6 py-3">
      <NuxtLink to="/" class="text-sm text-stone-900 font-semibold tracking-tight">
        Stupid Big Ideas
      </NuxtLink>

      <button
        v-if="user"
        type="button"
        class="flex items-center gap-1.5 rounded-full text-sm text-stone-500 hover:text-stone-900 transition-colors px-2 py-1"
        aria-label="Cerrar sesión"
        @click="logout"
      >
        <UIcon name="i-lucide-log-out" class="size-4" />
        <span>Salir</span>
      </button>
      <NuxtLink
        v-else
        to="/login"
        class="text-sm text-stone-400 hover:text-stone-900 transition-colors px-2 py-1"
      >
        Entrar
      </NuxtLink>
    </header>

    <main class="w-full max-w-5xl mx-auto px-6 py-12">
      <slot />
    </main>
  </div>
</template>

<script setup>
const { user, logout } = useAuth()
</script>
