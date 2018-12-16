Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  get 'login', to: 'auth#login'
  get 'auth/callback', to: 'auth#callback'
  get '/', to: 'pages#top'

  namespace 'api' do
    namespace 'v1' do
      get 'shows', to: 'shows#index'
      post 'show/:uuid/record', to: 'shows#record'
      post 'show/:uuid/update', to: 'shows#update'
    end
  end
end
