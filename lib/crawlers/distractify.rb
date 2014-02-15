class Crawlers::Viralnova

  def self.crawlagent = Mechanize.new
    page = agent.get('http://distractify.com/')
    # .sidebar-post a, .sidebar-post img
    # .featured-post a .featured-img img
    # .img-container a img
    articles = []
    links = page.search('.img-container a, .featured-post a, .top-posts a')

    # links.each do |l|
    #   url = l.attributes['href'].value
    #   thumbnail_url = l.search('img')[0]['src']
    #   articles << {url: url, thumbnail: thumbnail_url}
    # end

    content = agent.click(links.first)
    main = content.search('section.active-tab .list-post')
    main.css('img').each do |img|
      # save img['src']

      img.set_attribute('src', 'DAMIEN SRC')
    end

    p main.inner_html
  end

end
