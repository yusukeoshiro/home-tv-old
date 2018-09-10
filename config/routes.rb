Rails.application.routes.draw do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'

    get 'login', :to => 'auth#login'
    get 'auth/callback', :to => 'auth#callback'

    namespace 'api' do
        namespace 'v1' do
            get 'shows', :to => 'shows#index'
        end
    end
end