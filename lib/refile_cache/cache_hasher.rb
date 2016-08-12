module RefileCache
  class CacheHasher
    def hash(uploadable = nil)
      uploadable.original_filename
    end
  end
end
