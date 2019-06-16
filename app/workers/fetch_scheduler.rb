require 'sidekiq-scheduler'

class FetchScheduler
  include Sidekiq::Worker

  def perform
    util = ShowFetchUtil.new
    7.times do |i|
      begin
        fetch_date = Date.today + i
        puts "fetching #{fetch_date}..."
        util.fetch(fetch_date)
      rescue => e
        puts e.message
      end
    end
  end
end
