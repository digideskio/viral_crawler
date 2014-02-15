ViralCrawler::Application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
end
