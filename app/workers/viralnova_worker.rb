class ViralnovaWorker
  include Sidekiq::Worker

  def perform (image_link, article_id)
    article = Article.find(article_id)
    Logger.new(STDOUT).info '[Viralnova Worker] Saving article content...'
    thumbnail = URI.parse(image_link)
    article.thumbnail = thumbnail
    article.content = content(article)
    if article.save!
      Logger.new(STDOUT).info '[Viralnova Worker] Save complete.'
      Crawler.send_article article
    end
  end

  def content (article)
    agent = Mechanize.new
    article_page = agent.get article.url

    main = article_page.search('article.article')

    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.div.content {
        doc.header {
          doc.text main.css('header h2')[0].inner_text
        }
        doc.div {
          main.css('.entry-content')[0].children.each do |c|
            if c.name == 'p'
              doc.p {
                doc.text c.inner_html
              }
            elsif c.values.any? { |s| s.include?('gallery') }
              c.search('.gallery-item').each do |item|
                doc.div.gallery {
                  doc.div.image {
                    img = item.search('.gallery-icon img')[0]
                    img.remove_attribute 'height'
                    img.remove_attribute 'width'
                    img.set_attribute('src', Crawler.save_to_s3(img['src']))
                    doc.text img.to_html
                  }
                  doc.div.caption {
                    doc.text item.search('.gallery-caption').text.strip
                  }
                }
              end
            elsif c.values.present? && c.values.any? { |s| s.include?('vimeo-video') }
              doc.div.vimeo {
                doc.text c.inner_html
              }
            end
          end
        }
      }
    end

    HTMLEntities.new.decode(builder.to_html)
  end

end
