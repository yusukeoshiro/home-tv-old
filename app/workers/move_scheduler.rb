require 'sidekiq-scheduler'

class MoveScheduler
  include Sidekiq::Worker

  def perform
    util = DriveUtil.new
    util.move
  end
end
