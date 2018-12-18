require 'dotenv'
require 'redis'
require 'json'
require 'date'
require 'pry'
require 'log'
require_relative './util.rb'

Dotenv.load

RECORDING_PATH = ENV['RECORDING_PATH']
RECORDED_PATH  = ENV['RECORDED_PATH']
logger = Logger.new(STDOUT)

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
    logger.debug(notify "Starting Recording #{show['show']['title']}")
    start_time = DateTime.parse(show['show']['start_time']).new_offset('+09:00')
    file_name = "#{start_time.strftime('%Y%m%d_%H%M')}_#{show['show']['uuid']}.ts"

    device_to_use = nil
    recover_tv_process = false

    if open_devices.any?
      device_to_use = open_devices.first
    else
      if freeable_device.nil?
        logger.warn('sorry no device available! E1')
        raise 'sorry no device available! E1'
      end

      logger.debug('freeing tv process')
      device_to_use = freeable_device
      `kill #{freeable_process}`
      recover_tv_process = true
      sleep(5)
    end
    raise 'sorry no device available! E2' if device_to_use.nil?

    logger.debug(notify "recording using #{device_to_use}")

    command = "recpt1 --b25 --device #{device_to_use} --strip #{show['show']['channel_number']} #{show['footage_duration']} #{RECORDING_PATH}/#{file_name}"
    system(command)
    File.rename("#{RECORDING_PATH}/#{file_name}", "#{RECORDED_PATH}/#{file_name}")
    logger.debug(notify("Finished Recording #{show[:title]}"))
    update_recording_job(show['show']['uuid'], 'RECORD')
    return unless recover_tv_process
    return if open_devices.empty?

    sleep(5)
    command = "recpt1 --device #{open_devices.first} --b25 --strip --sid hd --http 8888 | tee logs/log.tv &"
    system(command)
  end
end

if __FILE__ == $0
  logger.debug('recorder live...')
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
        logger.fatal(e.message)
        logger.fatal('failed')
      end
    end
  end
end
