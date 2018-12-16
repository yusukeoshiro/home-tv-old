require 'sidekiq-scheduler'

class ReserveScheduler
  include Sidekiq::Worker

  def perform
    Reservation.where(enabled: true).each do |reservation|
      reservation.record
    end
  end
end
