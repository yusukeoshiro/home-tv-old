class Show
  class AlreadyReservedError < StandardError; end
  class AlreadyOverError < StandardError; end

  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :description, type: String
  field :region, type: String
  field :date, type: Date
  field :epg_date, type: Date
  field :start_time, type: DateTime
  field :end_time, type: DateTime
  field :duration, type: Integer
  field :channel_name, type: String
  field :channel_number, type: Integer
  field :delete_on, type: Date
  field :uuid, type: String

  # validates_presence_of :title, :start_time, :end_time, :channel_number
  validates_presence_of :title, :start_time, :end_time

  index({ uuid: 1, epg_date: 1 }, unique: true)

  scope :showing_now, -> { where( :start_time.lte => DateTime.now, :end_time.gt => DateTime.now ) }

  # this will typically equal Show.duration but can be less if the show has started already
  def footage_duration
    return 0 if end_time < DateTime.now
    return ((end_time - DateTime.now) * 60 * 60 * 24 ).to_i if start_time < DateTime.now

    duration
  end

  def over?
    DateTime.now >= end_time
  end

  def showing_now?
    (DateTime.now > start_time) && (DateTime.now <= end_time)
  end

  def file_name
    @file_name ||= "#{start_time.new_offset('+09:00').strftime('%Y%m%d_%H%M')}_#{uuid}"
  end

end
