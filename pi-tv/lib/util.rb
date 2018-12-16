require 'net/http'
require 'dotenv'
require 'json'

Dotenv.load

def notify(message)
  uri = URI(ENV['NOTIFY_URL'])
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  req = Net::HTTP::Post.new(uri.path)
  req.body = {
    'value1' => message
  }.to_json
  req['content-type'] = 'application/json'
  result = https.request(req)
  raise result.body if result.code.to_i != 200

  message
rescue => e
  puts 'error occured while sending push notification to IFTTT!!'
  puts e.message
end

def update_recording_job(show_uuid, status)
  url = ENV['UPDATE_URL'].gsub(':UUID', show_uuid)
  p url
  uri = URI(url)
  https = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Post.new(uri.path)
  req.body = {
    'finished' => status
  }.to_json
  req['content-type'] = 'application/json'
  result = https.request(req)
  raise result.body if result.code.to_i != 200
  :ok
rescue => e
  puts 'something went wrong...'
  puts e.message
end

def uuid_from_file_name(file_name)
  base = File.basename(file_name, '.mp4')
  uuid = base.split('_')[2]
  uuid
end
