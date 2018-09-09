Rails.application.routes.draw do
    namespace 'api' do
        namespace 'v1' do
            get 'shows', :to => 'shows#index'
        end
    end
end