require 'dotenv'
require 'redis'
require 'json'
require 'date'
require 'pry'
require_relative './util.rb'

Dotenv.load

RECORDING_PATH = ENV['RECORDING_PATH']
RECORDED_PATH  = ENV['RECORDED_PATH']

def open_devices
  devices = ['/dev/px4video2', '/dev/px4video3']
  pids = `pidof recpt1`.strip.split(' ')
  pids.each do |pid|
    command = `ps -p #{pid} -o args`
    devices.each do |device|
      devices.delete(device) if command.include? device
    end
  end
  devices
end

def freeable_device
  devices = ['/dev/px4video2', '/dev/px4video3']
  pids = `pidof recpt1`.strip.split(' ')
  pids.each do |pid|
    command = `ps -p #{pid} -o args`
    next unless command.include? 'http'

    devices.each do |device|
      return device if command.include?(device)
    end
  end
  nil
end

def freeable_process
  devices = ['/dev/px4video2', '/dev/px4video3']
  pids = `pidof recpt1`.strip.split(' ')
  pids.each do |pid|
    command = `ps -p #{pid} -o args`
    next unless command.include? 'http'

    devices.each do |device|
      return pid if command.include?(device)
    end
  end
  nil
end


def record_show(show)
  Thread.new do
    # if true do
    puts notify "Starting Recording #{show['show']['title']}"
    start_time = DateTime.parse(show['show']['start_time']).new_offset('+09:00')
    file_name = "#{start_time.strftime('%Y%m%d_%H%M')}_#{show['show']['uuid']}.ts"

    device_to_use = nil
    recover_tv_process = false

    if open_devices.any?
      puts 'free device found'
      device_to_use = open_devices.first
    else
      raise 'sorry no device available! E1' if freeable_device.nil?

      puts 'freeing tv process'
      device_to_use = freeable_device
      `kill #{freeable_process}`
      recover_tv_process = true

    end
    raise 'sorry no device available! E2' if device_to_use.nil?

    puts notify "recording using #{device_to_use}"

    command =  "recpt1 --b25 --device #{device_to_use} --strip #{show['show']['channel_number']} #{show['footage_duration']} #{RECORDING_PATH}/#{file_name}"
    result = system(command)
    puts result
    File.rename("#{RECORDING_PATH}/#{file_name}", "#{RECORDED_PATH}/#{file_name}")
    notify "Finished Recording #{show[:title]}"
    return unless recover_tv_process
    return if open_devices.empty?

    command = "recpt1 --device #{open_devices.first} --b25 --strip --sid hd --http 8888 | tee logs/log.tv &"
    system(command)
  end
end

if __FILE__ == $0
  puts 'recorder live...'
  subscriber = Redis.new(url: ENV['REDIS_URL'])
  subscriber.subscribe('command_request') do |on|
    on.message do |channel, data|
      begin
        data.force_encoding('utf-8')
        payload = JSON.parse data
        if payload['command'] == 'RECORD'
          show = payload['show']
          record_show(show)
        end
      rescue => e
        puts e.message
        puts 'failed'
      end
    end
  end
end
