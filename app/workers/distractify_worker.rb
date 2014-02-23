class DistractifyWorker
  include Sidekiq::Worker

  def perform (image_link, article_id)
    article = Article.find(article_id)
    Logger.new(STDOUT).info '[Distractify Worker] Saving article content...'
    thumbnail = URI.parse(image_link)
    article.thumbnail = thumbnail
    article.content = content(article)
    if article.save!
      Logger.new(STDOUT).info '[Distractify Worker] Save complete.'
      Crawler.send_article article
    end
  end

  def content (article)
    agent = Mechanize.new
    article_page = agent.get article.url

    main = article_page.search('section.active-tab')

    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.div.content {
        doc.header {
          doc.text main.css('h1')[0].inner_text
        }
        doc.div {
          if main.css('.intro.post-description').present?
            doc.div {
              doc.text main.css('.intro.post-description').inner_html
            }
          end

          main.css('.list-post').each do |lp|
            lp.children.each do |c|
              if c.name == 'p'
                doc.p {
                  doc.text c.inner_html
                }
              elsif c.name == 'img'
                doc.div.gallery {
                  doc.div.image {
                    img = c
                    img.remove_attribute 'height'
                    img.remove_attribute 'width'
                    img.set_attribute('src', Crawler.save_to_s3(img['src']))
                    doc.text img.to_html
                  }
                }
              elsif c.name == 'span'
                doc.div.source {
                  doc.text c.inner_html
                }
              elsif c.name == 'h2'
                doc.p {
                  doc.text c.inner_text
                }
              elsif c.name == 'iframe'
                doc.div.video {
                  doc.text c
                }
              end
            end
          end

          doc.div {
            if main.css('.conclusion').present?
              main.css('.conclusion')[0].children.each do |c|
                if c.name == 'p'
                  doc.p {
                    doc.text c.inner_text
                  }
                end
              end
            end
          }
        }
      }
    end

    HTMLEntities.new.decode(builder.to_html)
  end
end
