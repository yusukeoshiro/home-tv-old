require 'sidekiq-scheduler'

class ReserveScheduler
  include Sidekiq::Worker

  def perform
    util = ReserveUtil.new
    util.reserve
  end
end
