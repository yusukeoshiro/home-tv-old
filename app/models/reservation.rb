class Reservation
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :recordings

  field :keyword, type: String
  field :channel_number, type: Integer
  field :folder_name, type: String
  field :enabled, type: String, default: true
  # field :last_recorded_at, type: DateTime

  scope :actives, -> { where(enabled: true) }

  def record
    shows.each do |show|
      recording = Recording.new(
        show_uuid: show.uuid,
        reservation: self
      )
      next if recording.reserved?

      recording.record
      recording.save
    end
  end

  def shows
    criteria = Show.where(
      :end_time.gt => DateTime.now,
      :start_time.lte => DateTime.now + (6.0 / 24)) # only target shows that start in 6 hours from now

    criteria.where(channel_number: channel_number) if channel_number.present?
    criteria.where(title: /#{keyword}/) if keyword.present?
  end
end
