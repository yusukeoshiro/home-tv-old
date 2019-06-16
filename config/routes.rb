Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  get 'login', to: 'auth#login'
  get 'auth/callback', to: 'auth#callback'
  get '/', to: 'pages#top'
  get 'broadcaster_control', to: 'pages#broadcaster_control'
  # post 'broadcaster_control', to: 'pages#broadcaster_control'

  namespace 'api' do
    namespace 'v1' do
      get 'shows', to: 'shows#index'
      post 'show/:uuid/record', to: 'shows#record'
      post 'show/:uuid/update', to: 'shows#update'
      post 'broadcaster_control', to: 'broadcasters#instruct'

      post 'scheduler/fetch', to: 'shows#fetch'
      post 'scheduler/reserve', to: 'shows#reserve'
      post 'scheduler/move', to: 'shows#move'
    end
  end
end
