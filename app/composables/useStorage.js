const BUCKET = 'ideas'

export const useStorage = () => {
  const supabase = useSupabaseClient()

  const uploadFile = async (file, slug) => {
    const extension = (file.name.split('.').pop() || 'bin').toLowerCase()
    const timestamp = Date.now()
    const random = Math.random().toString(36).slice(2, 8)
    const path = `${slug}/${timestamp}-${random}.${extension}`

    const { error } = await supabase.storage
      .from(BUCKET)
      .upload(path, file, {
        contentType: file.type || 'application/octet-stream',
        cacheControl: '31536000',
        upsert: false,
      })

    if (error) throw error

    const { data: { publicUrl } } = supabase.storage.from(BUCKET).getPublicUrl(path)

    return { publicUrl, path }
  }

  const removeFiles = async (paths) => {
    const clean = (paths || []).filter(Boolean)
    if (!clean.length) return
    const { error } = await supabase.storage.from(BUCKET).remove(clean)
    if (error) throw error
  }

  const thumb = (url, width) => {
    if (!url || !url.includes('/storage/v1/object/public/')) return url
    return `${url.replace('/object/public/', '/render/image/public/')}?width=${width}&resize=contain&quality=75`
  }

  return { uploadFile, removeFiles, thumb }
}
