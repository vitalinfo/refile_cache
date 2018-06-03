require 'refile_cache/version'
require 'refile_cache/file_double'
require 'refile_cache/file_streamer'
require 'refile_cache/cache_hasher'
require 'refile_cache/cache'

require 'refile_cache/rails' if defined?(Rails::Railtie) && defined?(Refile::S3)
