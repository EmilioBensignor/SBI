<template>
  <div class="min-h-dvh bg-white">
    <header class="sticky top-0 z-10 border-b border-stone-100 bg-white/90 backdrop-blur">
      <div class="w-full max-w-7xl flex justify-between items-center mx-auto px-[max(env(safe-area-inset-left),1rem)] md:px-8 pt-[max(env(safe-area-inset-top),0.75rem)] pb-3">
        <NuxtLink to="/" class="text-sm md:text-base text-stone-900 font-semibold tracking-tight">
          Stupid Big Ideas
        </NuxtLink>

        <button
          v-if="user"
          type="button"
          class="flex items-center gap-1.5 rounded-full text-sm md:text-base text-stone-500 hover:text-stone-900 transition-colors px-2 py-1"
          aria-label="Cerrar sesión"
          @click="logout"
        >
          <UIcon name="i-lucide-log-out" class="size-4" />
          <span>Salir</span>
        </button>
        <NuxtLink
          v-else
          to="/login"
          class="text-sm md:text-base text-stone-400 hover:text-stone-900 transition-colors px-2 py-1"
        >
          Entrar
        </NuxtLink>
      </div>
    </header>

    <main class="w-full max-w-7xl mx-auto px-[max(env(safe-area-inset-left),1rem)] md:px-8 pt-8 md:pt-16 mac:pt-10 pb-[max(env(safe-area-inset-bottom),3rem)] md:pb-16 mac:pb-10">
      <slot />
    </main>
  </div>
</template>

<script setup>
const { user, logout } = useAuth()
</script>
