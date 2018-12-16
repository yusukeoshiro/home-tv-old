require 'sidekiq-scheduler'

class FetchScheduler
  include Sidekiq::Worker

  def perform
    7.times do |i|
      ShowFetcher.perform_async Date.today + i
    end
  end

end
