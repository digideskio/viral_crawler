class UpworthyWorker
  include Sidekiq::Worker

  def perform (image_link, article_id)
    article = Article.find(article_id)
    Logger.new(STDOUT).info '[Upworthy Worker] Saving article content...'
    thumbnail = URI.parse(image_link)
    article.thumbnail = thumbnail
    article.content = content(article)
    if article.save!
      Logger.new(STDOUT).info '[Upworthy Worker] Save complete.'
      Crawler.send_article article
    end
  end

  def content (article)
    agent = Mechanize.new
    article_page = agent.get article.url

    main = article_page.search('article#nuggetContent')

    builder = Nokogiri::HTML::Builder.new do |doc|
      doc.div.content {
        doc.header {
          doc.text main.css('h1')[0].inner_text
        }
        doc.div {
          if main.css('header #lede').present?
            main.css('header #lede')[0].children.each do |c|
              if c.name == 'p'
                if c.children[-1].name == 'text'
                  doc.div {
                    doc.text c.inner_html
                  }
                elsif c.children[-1].name == 'img'
                  doc.div.image {
                    img = c.children[-1]
                    img.remove_attribute 'height'
                    img.remove_attribute 'width'
                    img.set_attribute('src', Crawler.save_to_s3('http:' + img['src']))
                    doc.text img.to_html
                  }
                end
              end
            end

            main.css('#content')[0].children.each do |content|

              if content.name == 'p'
                if content.children.present? && (content.children[0].name == 'img')
                  img = content.children[0]
                  img.remove_attribute 'height'
                  img.remove_attribute 'width'
                  img.set_attribute('src', Crawler.save_to_s3(img['src']))
                  doc.div.gallery {
                    doc.div.image {
                      doc.text img.to_html
                    }
                  }
                else
                  doc.p {
                    doc.text content.inner_html
                  }
                end
              elsif content.name == 'center'
                doc.div.gallery {
                  doc.div.image {
                    img = content.search('img')[0]
                    img.remove_attribute 'height'
                    img.remove_attribute 'width'
                    img.set_attribute('src', Crawler.save_to_s3('http:' + img['src']))
                    doc.text img.to_html
                  }
                }
              elsif content.name == 'img'
                doc.div.gallery {
                  doc.div.image {
                    img = content
                    img.remove_attribute 'height'
                    img.remove_attribute 'width'
                    img.set_attribute('src', Crawler.save_to_s3('http:' + img['src']))
                    doc.text img.to_html
                  }
                }
              elsif content.values.present? && content.values.any? { |s| s.include?('fluid-width-video-wrapper') }
                doc.div.vimeo {
                  doc.text content.inner_html
                }
              elsif content.name == 'iframe'
                doc.div.video {
                  doc.text content
                }
              end
            end
          end
        }
      }
    end

    HTMLEntities.new.decode(builder.to_html)
  end
end
