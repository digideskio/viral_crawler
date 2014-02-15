class Crawlers::Viralnova

  def self.crawl
    Logger.new(STDOUT).info 'Crawling VIRALNOVA...'
    agent = Mechanize.new
    viralnova = agent.get 'http://www.viralnova.com/'
    links = viralnova.search('ul.advanced-recent-posts li')

    send_error if links.blank?

    links.each do |l|
      link = l.search('a').first
      url = link.attributes['href'].value

      article_page = agent.click(link)
      description = article_page.at('meta[@property="og:description"]')[:content]
      title = article_page.search('article.article').css('header h2')[0].inner_text

      article = Article.new(url: url, description: description, title: title)

      if article.save
        image_link = link.search('img')[0]['src']
        ViralnovaWorker.perform_async(image_link, article.id)
      end
    end

    Logger.new(STDOUT).info 'Completed.'
  end

  def self.send_error
    Logger.new(STDOUT).error 'No links found...'

  end

end
