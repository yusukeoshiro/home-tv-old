class ReserveUtil
  def reserve
    reservations = Reservation.where(enabled: true).each
    if reservations.count.positive?
      Reservation.where(enabled: true).each do |reservation|
        if reservation.shows.count.positive?
          puts "Reserving #{reservation.keyword}"
          reservation.record
        end
      end
    else
      puts 'nothing to reserve!'
    end
  end
end
