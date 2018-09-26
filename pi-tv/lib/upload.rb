require "listen"
require "streamio-ffmpeg"
require "securerandom"
require "dotenv"
require "json"
require "oauth2"
require "redis"
require 'net/http'
require_relative "./util.rb"



Dotenv.load

RECORDED_PATH   = ENV["RECORDED_PATH"]
CONVERTING_PATH = ENV["CONVERTING_PATH"]
CONVERTED_PATH  = ENV["CONVERTING_PATH"]

$redis = Redis.new(url: ENV["REDIS_URL"])

class InsufficientQuota < Exception
end


class AccessTokenWrapper
	attr_accessor :access_token

	@@key = "google_auth_hash"

	def initialize
		google_auth_client = OAuth2::Client.new(ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], :site => "https://accounts.google.com", :authorize_url => "o/oauth2/auth", :token_url => "o/oauth2/token")
		hash =  JSON.parse( $redis.get( @@key ) )
		self.access_token = OAuth2::AccessToken.new( google_auth_client, hash["access_token"], hash )
	end

	def refresh!
		self.access_token = self.access_token.refresh!
		$redis.set( @@key, self.access_token.to_hash.to_json )
		# return self
	end

	def get_token
		if self.access_token.expired?
			self.refresh!
		end
		return self.access_token
	end
end

def get_upload_token file_path, access_token
	raise "#{file_path} is not a valid file path" if !File.file? file_path

	start = Time.now
	puts notify "Uploading #{file_path} to Google Photos"
	file_name = File.basename file_path
	
	command = "curl -X POST https://photoslibrary.googleapis.com/v1/uploads -T #{file_path} " + 
		" --header \"X-Goog-Upload-File-Name: #{file_name}\" --header \"X-Goog-Upload-Protocol: raw\" " + 
		" --header \"content-type: application/octet-stream\" " + 
        	" --header \"Authorization: Bearer #{access_token}\" "
	upload_token = %x( #{command} )

	puts upload_token

	raise "authentication invalid #{upload_token}" if upload_token.include? "Authentication session is not defined."
	raise InsufficientQuota.new "quota exeeded" if upload_token.include? "Insufficient tokens for quota"

	if upload_token
		elapsed = Time.now - start
		puts notify "Finished uploading #{file_path} in #{elapsed} seconds"
		return upload_token
	else
		raise notify "upload token was not retrieved by google photos api"
	end
end

def create_media upload_token, access_token, description
	puts upload_token
	puts "creating media..."
	uri = URI("https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate")
	https = Net::HTTP.new(uri.host, uri.port)
	https.use_ssl = true
	req = Net::HTTP::Post.new(uri.path)
	req.body = {
		"newMediaItems" => [
			{
				"description" => description,
				"simpleMediaItem" => {
					"uploadToken" => upload_token
				}
			}
		]
	}.to_json
	req["content-type"] = "application/json"
	req["Authorization"] = "Bearer #{access_token}"
	result = https.request(req)
	if result.code.to_i == 200
		puts notify "google photos media created!"
		return true
	else
		puts notify "error occured while creating the media!!"
		puts notify result.body
		raise "media was not created at google photos"
	end
end


def upload_to_google_photo file_path, description, is_delete=true
	token = AccessTokenWrapper.new
	upload_token = get_upload_token file_path, token.get_token.token
	create_media upload_token, token.get_token.token, description
	File.delete file_path if is_delete
end


def get_delay_time consecutive_error_count
	return consecutive_error_count ** 5 + 15
end


if $0 == __FILE__ then
    consecutive_error_count = 0
    while true
	delay_time = 10
	puts "polling #{CONVERTED_PATH}..."
        Dir["#{CONVERTED_PATH}/*.mp4"].each do |file_path|
	    begin
		upload_to_google_photo( file_path, "test") 
		consecutive_error_count = 0
	    rescue InsufficientQuota => e
		puts notify "insufficient quota left in google photo!!"
		delay_time = 60 * 60 * 12 # wait 12 hours
		break
            rescue => e
		puts notify e.message
		consecutive_error_count = consecutive_error_count + 1
		delay_time = get_delay_time consecutive_error_count
		break
	    end
        end
	puts "delay is #{delay_time}"
        sleep delay_time
    end
end
