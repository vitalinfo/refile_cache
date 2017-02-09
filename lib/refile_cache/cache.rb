module RefileCache

  class Cache
    def initialize(app)
      @app = app
    end

    def call(env)
      "#{self.class}::Logic".constantize.new(@app).call(env)
    end

    # This is for autoreloading to be working :D
    class Logic
      URL_PATH = /\A#{Refile.mount_point}\/.*\/store\/(fill|fit|limit|pad|convert)\//
      URL_PROCESSOR = /\A#{Refile.mount_point}\/(?<token>.*)\/(?<backend>.*)\/(?<processor>(fill|fit|limit|pad|convert))\/(?<splat>.*)\/(?<id>.*)\/(?<file>.*)/

      def initialize(app)
        @app = app
      end

      def call(env)
        # do not process other endpoints
        return @app.call(env) if env['PATH_INFO'] !~ URL_PATH
        # do not process invalid token
        return @app.call(env) unless valid_token?(env)

        params = get_params(env)
        cache_key = "cache#{params[:id]}#{params[:processor]}#{params[:splat].delete('/')}"

        if backend.exists?(cache_key)
          return [301, { 'Location' => "https://#{ENV['S3_BUCKET_NAME']}.s3.amazonaws.com/image_cache/#{cache_key}" }, []]
        end

        status, headers, response = @app.call(env)

        # cache only existing images
        if status == 200
          image = RefileCache::FileDouble.new(File.open(response.path).read, cache_key, content_type: headers['Content-Type'])
          backend.upload(image)
        end

        [status, headers, response]
      end

      def valid_token?(env)
        token = get_params(env)[:token]
        base_path = env['PATH_INFO'].gsub(::File.join(Refile.mount_point, token), '')

        Refile.valid_token?(base_path, token)
      end

      def get_params(env)
        env['PATH_INFO'].match(URL_PROCESSOR)
      end

      def backend
        Refile.backends.fetch('image_cache') do |name|
          log_error("Could not find backend: #{name}")
          halt 404
        end
      end

      def own_headers(filename, content_length)
        {
          'Content-Type' => 'image/jpeg',
          'Access-Control-Allow-Origin' => '*',
          'Access-Control-Allow-Headers' => '',
          'Access-Control-Allow-Method' => '',
          'Cache-Control' => 'public, max-age=31536000',
          'Expires' => (Time.now + 1.year).gmtime.to_s,
          'Content-Disposition' => "inline; filename=\"#{filename}\"",
          'Last-Modified' => (Time.now - 1.month).gmtime.to_s,
          'Content-Length' => content_length.to_s,
          'X-Content-Type-Options' => 'nosniff'
        }
      end

      def stream_file(env, file)
        if file.respond_to?(:path)
          path = file.path
        else
          path = Dir::Tmpname.create(get_params(env)[:id]) {}
          IO.copy_stream file, path
        end
        File.open(path)
      end
    end
  end
end
