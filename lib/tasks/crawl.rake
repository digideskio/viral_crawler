namespace :crawl do
  desc "Crawl all sites"
  task all: :environment do
  end

  desc "Crawl Viralnova"
  task viralnova: :environment do
    Crawlers::Viralnova.crawl
  end

  desc "Crawl Distractify"
  task distractify: :environment do
    Crawlers::Distractify.crawl
  end

  desc "Crawl Upworthy"
  task upworthy: :environment do
    Crawlers::Upworthy.crawl
  end

end
