const COLUMNS = 'id, slug, tematica, fecha, desafio, puntaje, destaques, oportunidades, created_by, created_at, updated_at'

const IDEA_COLUMNS = 'id, tematica_id, orden, titulo, marca, insight, concepto, anotaciones, assets, created_by, created_at, updated_at'

const TEXT_FIELDS = ['desafio', 'destaques', 'oportunidades']

export const useTematicas = () => {
  const supabase = useSupabaseClient()
  const { removeFiles } = useStorage()

  const estaCerrada = (tematica) =>
    Boolean(tematica?.ideas?.length) &&
    (tematica.puntaje !== null || Boolean(tematica.destaques) || Boolean(tematica.oportunidades))

  const fetchAll = async () => {
    const { data, error } = await supabase
      .from('ideas_tematicas')
      .select(`${COLUMNS}, ideas(id)`)
      .order('fecha', { ascending: false })
      .order('created_at', { ascending: false })

    if (error) throw error
    return data || []
  }

  const fetchBySlug = async (slug) => {
    const { data, error } = await supabase
      .from('ideas_tematicas')
      .select(`${COLUMNS}, ideas(${IDEA_COLUMNS})`)
      .eq('slug', slug)
      .order('orden', { referencedTable: 'ideas' })
      .order('created_at', { referencedTable: 'ideas' })
      .maybeSingle()

    if (error) throw error
    return data
  }

  const create = async ({ tematica, fecha, desafio }) => {
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
          desafio: desafio?.trim() || null,
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

    const { data, error } = await supabase
      .from('ideas_tematicas')
      .update(clean)
      .eq('id', id)
      .select(COLUMNS)
      .single()

    if (error) throw error
    return data
  }

  const remove = async (tematica) => {
    const { error } = await supabase
      .from('ideas_tematicas')
      .delete()
      .eq('id', tematica.id)

    if (error) throw error

    const paths = (tematica.ideas || [])
      .flatMap((idea) => idea.assets || [])
      .filter((asset) => asset.path)
      .map((asset) => asset.path)

    try {
      await removeFiles(paths)
    } catch {
      return
    }
  }

  return { fetchAll, fetchBySlug, create, update, remove, estaCerrada }
}
