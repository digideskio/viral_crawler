class Crawler

  def self.send_article (article)
    params = { thumbnail_url: create_link(article.thumbnail.path),
      original_url: article.url,
      original_content: article.content,
      original_description: article.description,
      original_title: article.title
    }
    RestClient.post 'http://www.sharesthebest.com/create_blog', article: params
  end

  def self.save_to_s3 (src)
    filename = src.split('/').last
    regex = /^(http|https):/ =~ src
    source = regex.nil? ? 'http:' + src : src
    image = MiniMagick::Image.open(source)
    s3 = AWS::S3.new
    bucket = s3.buckets[ENV['S3_BUCKET_NAME']]
    path = create_path(filename)
    obj = bucket.objects[path]
    obj.write(Pathname.new(image.path))

    create_link('/' + path)
  end

  def self.create_path (filename)
    "images/#{rand(99)}/#{rand(99)}/#{filename}"
  end

  def self.create_link (path)
    "http://#{ENV['S3_BUCKET_NAME']}.s3.amazonaws.com" + path
  end

end
