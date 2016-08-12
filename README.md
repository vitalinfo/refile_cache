# RefileCache

RefileCache - S3 file caching for Refile

Features:

- Caching images on S3

## Quick start, Rails

Add the gem:

``` ruby
gem "refile"
gem 'refile-s3', require: 'refile/s3'
gem "refile_cache"
```

Now you can upload files to S3 easily by using these accessors:

``` ruby
# config/initializers/refile.rb

aws = {
  access_key_id: "xyz",
  secret_access_key: "abc",
  region: "sa-east-1",
  bucket: "my-bucket",
}
Refile.cache = Refile::S3.new(prefix: "cache", **aws)
Refile.store = Refile::S3.new(prefix: "store", **aws)

#Setup Refile Cache
Refile.backends['image_cache'] = Refile::S3.new(prefix: 'image_cache', hasher: RefileCache::CacheHasher.new, **aws)

Refile.cdn_host = "https://your-dist-url.cloudfront.net"
```


## License

[MIT](LICENSE.txt)
