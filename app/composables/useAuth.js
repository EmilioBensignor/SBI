export const useAuth = () => {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  const login = async (email, password) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) {
      const msg = (error.message || '').toLowerCase()
      const isNetwork = msg.includes('network') || msg.includes('fetch')
      return {
        ok: false,
        message: isNetwork ? 'Sin conexión, intentá de nuevo' : 'Email o contraseña incorrectos',
      }
    }
    return { ok: true }
  }

  const logout = async () => {
    await supabase.auth.signOut()
    await navigateTo('/')
  }

  return { user, login, logout }
}
