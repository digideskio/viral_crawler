class Crawlers::Distractify

  def self.crawl
    Logger.new(STDOUT).info '[Distractify] Crawling...'
    agent = Mechanize.new
    page = agent.get 'http://distractify.com/'
    links = page.search('.img-container a, #sidebar1 .featured-post a, .top-posts a')

    send_error if links.blank?

    links.each do |l|
      url = l.attributes['href'].value

      article_page = agent.click(l)
      description = article_page.at('meta[@property="og:description"]')[:content]
      title = article_page.search('h1').inner_text

      article = Article.new(url: url, description: description, title: title)

      if article.save
        image_link = l.search('img')[0]['src']
        DistractifyWorker.perform_async(image_link, article.id)
      end
    end

    Logger.new(STDOUT).info '[Distractify] Completed.'
  end

  def self.send_error
    Logger.new(STDOUT).error '[Distractify] No links found...'
  end
end

