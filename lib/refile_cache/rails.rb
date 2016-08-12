module RefileCache
  class Railtie < Rails::Railtie
    initializer 'refile.cache_initialization' do
      insert_middleware
    end

    def insert_middleware
      Rails.application.middleware.use RefileCache::Cache
    end
  end
end
