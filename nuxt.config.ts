export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  ssr: true,

  modules: [
    '@nuxt/ui',
    '@nuxt/fonts',
    '@nuxtjs/supabase',
  ],

  app: {
    head: {
      htmlAttrs: { lang: 'es' },
      title: 'Stupid Big Ideas',
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' },
        { name: 'description', content: 'El registro de las ideas creativas de Motix' },
      ],
    },
  },

  css: ['~/assets/css/main.css'],
  components: [{ path: '~~/app/components', pathPrefix: true }],
  imports: { dirs: ['composables/**'] },

  ui: { colorMode: false },

  supabase: {
    redirect: true,
    redirectOptions: {
      login: '/login',
      callback: '/confirm',
      exclude: ['/', '/idea/**', '/login'],
      saveRedirectToCookie: false,
    },
    cookieOptions: {
      maxAge: 60 * 60 * 24 * 30,
      sameSite: 'lax',
    },
    types: '',
  },

  fonts: {
    families: [
      { name: 'Outfit', provider: 'google', weights: [400, 500, 600, 700] },
    ],
  },

  typescript: {
    typeCheck: false,
    strict: false,
  },
})
