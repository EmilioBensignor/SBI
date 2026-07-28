const COLUMNS = 'id, slug, tematica, fecha, titulo, imagen_url, imagen_path, desarrollo, assets, puntaje, correcciones, destaques, oportunidades, created_by, created_at, updated_at'

const TEXT_FIELDS = ['titulo', 'desarrollo', 'correcciones', 'destaques', 'oportunidades']

export const useIdeas = () => {
  const supabase = useSupabaseClient()
  const { removeFiles } = useStorage()

  const enCurso = (idea) => !idea?.titulo

  const fetchAll = async () => {
    const { data, error } = await supabase
      .from('ideas_tematicas')
      .select(COLUMNS)
      .order('fecha', { ascending: false })
      .order('created_at', { ascending: false })

    if (error) throw error
    return data || []
  }

  const fetchBySlug = async (slug) => {
    const { data, error } = await supabase
      .from('ideas_tematicas')
      .select(COLUMNS)
      .eq('slug', slug)
      .maybeSingle()

    if (error) throw error
    return data
  }

  const create = async ({ tematica, fecha }) => {
    const clean = (tematica || '').trim()
    const base = slugify(clean)
    if (!base) throw new Error('La temática no genera una URL válida')

    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser?.id) throw new Error('Sin sesión activa')

    for (let attempt = 0; attempt < 5; attempt++) {
      const slug = attempt === 0 ? base : `${base}-${attempt + 1}`
      const { data, error } = await supabase
        .from('ideas_tematicas')
        .insert({
          slug,
          tematica: clean,
          fecha: fecha || new Date().toISOString().slice(0, 10),
          created_by: authUser.id,
        })
        .select(COLUMNS)
        .single()

      if (!error) return data
      if (error.code !== '23505') throw error
    }

    throw new Error('Ya existe una temática con ese nombre')
  }

  const update = async (id, patch) => {
    const clean = {}

    for (const field of TEXT_FIELDS) {
      if (field in patch) clean[field] = patch[field]?.trim() || null
    }
    if ('tematica' in patch) {
      const tematica = (patch.tematica || '').trim()
      if (!tematica) throw new Error('La temática no puede quedar vacía')
      clean.tematica = tematica
    }
    if ('fecha' in patch) clean.fecha = patch.fecha
    if ('puntaje' in patch) clean.puntaje = patch.puntaje ?? null
    if ('assets' in patch) clean.assets = patch.assets || []
    if ('imagen_url' in patch) clean.imagen_url = patch.imagen_url || null
    if ('imagen_path' in patch) clean.imagen_path = patch.imagen_path || null

    const { data, error } = await supabase
      .from('ideas_tematicas')
      .update(clean)
      .eq('id', id)
      .select(COLUMNS)
      .single()

    if (error) throw error
    return data
  }

  const remove = async (idea) => {
    const { error } = await supabase
      .from('ideas_tematicas')
      .delete()
      .eq('id', idea.id)

    if (error) throw error

    const paths = [
      idea.imagen_path,
      ...(idea.assets || []).filter((a) => a.tipo === 'file').map((a) => a.path),
    ]
    await removeFiles(paths)
  }

  return { fetchAll, fetchBySlug, create, update, remove, enCurso }
}
