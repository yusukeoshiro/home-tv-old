require 'listen'
require 'streamio-ffmpeg'
require 'securerandom'
require 'dotenv'
require 'json'
require 'oauth2'
require 'redis'
require 'net/http'
require_relative './util.rb'

Dotenv.load

RECORDED_PATH   = ENV['RECORDED_PATH']
CONVERTING_PATH = ENV['CONVERTING_PATH']
CONVERTED_PATH  = ENV['CONVERTED_PATH']

$redis = Redis.new(url: ENV['REDIS_URL'])

def encode_ts_to_mp4(file_path, is_delete=true)
  start = Time.now
  puts notify "Starting Encoding #{file_path}..."

  new_file_name = File.basename(file_path, File.extname(file_path)) + '.mp4'

  File.delete("#{CONVERTED_PATH}/#{new_file_name}") if File.file?("#{CONVERTING_PATH}/#{new_file_name}")
  tmp_name = SecureRandom.hex(3) + '.mp4'

  movie = FFMPEG::Movie.new(file_path) ; 0
  options = %w[-fflags +discardcorrupt -bsf:a aac_adtstoasc -c:a copy -b:v 5000k -c:v libx264 -vf scale=1440x1080]
  movie.transcode("#{CONVERTING_PATH}/#{tmp_name}", options) do |progress|
    puts progress
  end

  File.rename("#{CONVERTING_PATH}/#{tmp_name}", "#{CONVERTED_PATH}/#{new_file_name}")
  File.delete(file_path) if is_delete

  elapsed = Time.now - start
  puts notify "Finished Encoding #{new_file_name} in #{elapsed} seconds"

  update_recording_job(uuid_from_file_name(new_file_name), 'CONVERT')
  "#{CONVERTED_PATH}/#{new_file_name}"
end

if $0 == __FILE__ then
  while true
    puts "polling #{RECORDED_PATH}..."
    files_paths = Dir["#{RECORDED_PATH}/*.ts"]
    files_paths.each do |file_path|
      begin
        encode_ts_to_mp4(file_path) ; 0
      rescue FFMPEG::Error => e
        puts notify e.message
      end
    end
    sleep 10
  end
end
