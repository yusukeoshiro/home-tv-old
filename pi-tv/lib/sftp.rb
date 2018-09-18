require 'net/sftp'
require 'dotenv'

Dotenv.load


path_to_upload = "/home/yusuke/home-tv/Videos/recording"
path_to_complete = "/home/yusuke/home-tv/Videos/recorded"
puts path_to_upload

while true 
    Dir["/home/pi/home-tv/Videos/recorded/*.ts"].each do |file_path|
        file_name = File.basename file_path
        command = "./upload.sh #{ENV["SFTP_USER_NAME"]} #{ENV["SFTP_HOST"]} #{path_to_upload} #{file_path}"
        puts command
        result = system(command)
        puts result

        command = "./move.sh #{ENV["SFTP_USER_NAME"]} #{ENV["SFTP_HOST"]} #{path_to_upload}/#{file_name} #{path_to_complete}/#{file_name}"
        puts command
        result = system(command)
        puts result
        File.delete file_path

    end    
    sleep 10
end

