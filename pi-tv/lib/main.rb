require 'dotenv'
require 'redis'
require 'json'
require 'date'
require 'pry'
require_relative './util.rb'

Dotenv.load

RECORDING_PATH = ENV['RECORDING_PATH']
RECORDED_PATH  = ENV['RECORDED_PATH']

def record_show show

	Thread.new do
		# if true do
		publisher = Redis.new(url: ENV['REDIS_URL'])
		puts notify "Starting Recording #{show['show']['title']}"
		start_time = DateTime.parse(show['show']['start_time']).new_offset('+09:00')
		file_name = "#{start_time.strftime('%Y%m%d_%H%M')}_#{show['show']['uuid']}.ts"

		# check for open device, if any
		devices =      ['/dev/px4video2', '/dev/px4video3']
		free_devices = ['/dev/px4video2', '/dev/px4video3']
		quitable_device = nil
		quitable_process = nil
		device_to_use = nil
		recover_tv_process = false
		pids = %x(pidof recpt1).strip.split(' ')

		pids
		devices.each do |device|
			pids.each do |pid|
				command = %x( ps -p #{pid} -o args )
				if command.include? device
					puts command.class
					free_devices.delete_at( free_devices.index device )
					if command.include? 'http'
						puts 'http found'
						quitable_device = device
						quitable_process = pid
						puts '#{quitable_device} / #{quitable_process}'
					end
				end
			end
		end

		p 'free devices'
		p free_devices


		if free_devices.length > 0
			puts 'free device found'
			device_to_use = free_devices.first
		else
			puts 'free device not found'
			puts quitable_process.class
			if !quitable_process.nil?
				puts '++++++++++'
				result = %x(kill #{quitable_process})
				recover_tv_process = true
				puts 'killed TV process'
				device_to_use = quitable_device
			else
				puts 'killable process is not found...'
			end
		end


		if device_to_use
			puts notify 'recording using #{device_to_use}'

			command =  'recpt1 --b25 --device #{device_to_use} --strip #{show['show']['channel_number']} #{show['footage_duration']} #{RECORDING_PATH}/#{file_name}'
			# command = 'recpt1 --b25 --device #{device_to_use} --strip #{show['show']['channel_number']} 10 #{RECORDING_PATH}/#{file_name}'
			p command
			result = system(command)
			puts result
			File.rename('#{RECORDING_PATH}/#{file_name}', '#{RECORDED_PATH}/#{file_name}')
			notify 'Finished Recording #{show[:title]}'
			publisher.publish('convert_request', '#{RECORDED_PATH}/#{file_name}')

			if recover_tv_process
				command 'recpt1 --device #{quitable_device} --b25 --strip --sid hd --http 8888 | tee logs/log.tv &'
				system(command)
			end
		else
			puts notify 'sorry you don't have any device available now to record #{show['title']}'
		end
	end
end



puts 'recorder live...'
subscriber = Redis.new(url: ENV['REDIS_URL'])
subscriber.subscribe('command_request') do |on|
	on.message do |channel, data|
		begin
			data.force_encoding('utf-8')
			payload = JSON.parse data
			if payload['command'] == 'RECORD'
				show = payload['show']
				puts show
				record_show show
			end
			# command = payload['command']
			# show = payload['show']
			#
			# notify 'Starting Recording #{show['title']}'
			#
			# result = %x( #{command} )
			# puts result
			# notify 'Finished Recording #{show[:title]}'
		rescue => e
			puts e.message
			puts 'failed'
		end
	end
end
