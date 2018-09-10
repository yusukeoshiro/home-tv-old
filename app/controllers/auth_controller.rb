class AuthController < ApplicationController

    def login
        redirect_url = $google_auth_client.auth_code.authorize_url(:redirect_uri => "http://localhost:3000/auth/callback", :scope => "profile email https://www.googleapis.com/auth/photoslibrary", :access_type => "offline", :approval_prompt => "force")
        p redirect_url
        redirect_to redirect_url
    end

    def callback

        begin
            code = params[:code]
            $access_token = $google_auth_client.auth_code.get_token(code, :redirect_uri => 'http://localhost:3000/auth/callback')
            $redis.set("google_auth_hash", $access_token.to_hash.to_json)
            puts $access_token.token
            redirect_to "/"

        rescue OAuth2::Error => e

        end

    end


end
