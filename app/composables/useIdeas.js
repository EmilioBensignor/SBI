const COLUMNS = 'id, tematica_id, orden, titulo, marca, insight, concepto, anotaciones, assets, created_by, created_at, updated_at'

const TEXT_FIELDS = ['insight', 'concepto', 'anotaciones']

const FALTA_IDENTIDAD = 'La idea necesita un título o una marca'

export const useIdeas = () => {
  const supabase = useSupabaseClient()
  const { removeFiles } = useStorage()

  const create = async (tematicaId, patch) => {
    const titulo = (patch.titulo || '').trim()
    const marca = (patch.marca || '').trim()
    if (!titulo && !marca) throw new Error(FALTA_IDENTIDAD)

    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser?.id) throw new Error('Sin sesión activa')

    const { data, error } = await supabase
      .from('ideas')
      .insert({
        tematica_id: tematicaId,
        titulo: titulo || null,
        marca: marca || null,
        insight: patch.insight?.trim() || null,
        concepto: patch.concepto?.trim() || null,
        anotaciones: patch.anotaciones?.trim() || null,
        assets: patch.assets || [],
        created_by: authUser.id,
      })
      .select(COLUMNS)
      .single()

    if (error) throw error
    return data
  }

  const update = async (id, patch) => {
    const clean = {}

    for (const field of TEXT_FIELDS) {
      if (field in patch) clean[field] = patch[field]?.trim() || null
    }
    if ('titulo' in patch) clean.titulo = (patch.titulo || '').trim() || null
    if ('marca' in patch) clean.marca = (patch.marca || '').trim() || null
    if ('titulo' in patch && 'marca' in patch && !clean.titulo && !clean.marca) {
      throw new Error(FALTA_IDENTIDAD)
    }
    if ('assets' in patch) clean.assets = patch.assets || []

    const { data, error } = await supabase
      .from('ideas')
      .update(clean)
      .eq('id', id)
      .select(COLUMNS)
      .single()

    if (error) throw error
    return data
  }

  const remove = async (idea) => {
    const { error } = await supabase
      .from('ideas')
      .delete()
      .eq('id', idea.id)

    if (error) throw error

    const paths = (idea.assets || []).filter((asset) => asset.path).map((asset) => asset.path)

    try {
      await removeFiles(paths)
    } catch {
      return
    }
  }

  return { create, update, remove }
}
