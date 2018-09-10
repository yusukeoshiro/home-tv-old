$redis = Redis.new(url: ENV["REDIS_URL"])

$google_auth_client = OAuth2::Client.new(ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],
    :site => "https://accounts.google.com", :authorize_url => "o/oauth2/auth", :token_url => "o/oauth2/token")
