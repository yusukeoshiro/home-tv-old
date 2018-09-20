require 'net/sftp'
require 'dotenv'

Dotenv.load

path_to_watch =    "/home/pi/home-tv/Videos/recorded"
path_to_upload =   "/mnt/disks/videos/recording"
path_to_complete = "/mnt/disks/videos/recorded"

puts "uploader live..."
puts "watching #{path_to_watch}..."

while true 
    Dir["#{path_to_watch}/*.ts"].each do |file_path|
	puts "uploading #{file_path}..."
        file_name = File.basename file_path
        command = "./upload.sh #{ENV["SFTP_USER_NAME"]} #{ENV["SFTP_HOST"]} #{path_to_upload} #{file_path}"
        puts command
        result = system(command)
        puts "----------"             
        puts $?.exitstatus
	puts $?
	if $?.exitstatus == 0
		puts "upload complete!"
	else
		puts "upload failed!!"
		next
	end
        # puts result

        command = "./move.sh #{ENV["SFTP_USER_NAME"]} #{ENV["SFTP_HOST"]} #{path_to_upload}/#{file_name} #{path_to_complete}/#{file_name}"
        puts command
        result = system(command)
	puts "----------"
	puts $?.exitstatus
	puts $?
	if $?.exitstatus == 0
		puts "move complete!"
	        File.delete file_path
	else 
		puts "move failed!!"
	end
    end    
    sleep 10
end

