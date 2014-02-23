class Crawlers::Upworthy

  def self.crawl
    Logger.new(STDOUT).info '[Upworthy] Crawling...'
    agent = Mechanize.new
    page = agent.get 'http://www.upworthy.com/'
    links = page.search('.nugget .nugget-image a')

    send_error if links.blank?

    links.each do |l|
      url = 'http://www.upworthy.com' + l.attributes['href'].value

      article_page = agent.click(l)
      description = article_page.at('meta[@property="og:description"]')[:content]
      title = article_page.search('h1').inner_text

      article = Article.new(url: url, description: description, title: title)

      if article.save
        image_link = 'http:' + l.search('img')[0]['src']
        UpworthyWorker.perform_async(image_link, article.id)
      end
    end

    Logger.new(STDOUT).info '[Upworthy] Completed.'
  end

  def self.send_error
    Logger.new(STDOUT).error '[Upworthy] No links found...'
  end
end

