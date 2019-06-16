class Recording
  class AlreadyReservedError < StandardError; end
  class AlreadyOverError < StandardError; end

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :reservation, optional: true
  after_initialize :set_default, if: :new_record?
  before_destroy :unreserve
  before_save :evaluate_flags

  field :title, type: String
  field :error, type: String
  field :is_error, type: Boolean
  # field :file_name, type: String
  field :job_id, type: String
  field :tasks, type: Array
  field :complete, type: Boolean

  # show fields
  field :show_uuid, type: String
  field :start_time, type: DateTime
  field :end_time, type: DateTime
  field :epg_date, type: Date
  field :title, type: String
  field :description, type: String
  field :file_name, type: String
  field :channel_name, type: String
  field :channel_number, type: Integer
  field :duration, type: Integer

  scope :to_move, -> { where(complete: false) }

  index({ epg_date: 1 }, expire_after_seconds: 60 * 60 * 24 * 7)

  def set_default
    raise 'show_uuid must be set' if show_uuid.blank?

    self.tasks = %w[TRIGGER_RECORD RECORD CONVERT UPLOAD MOVE]
    self.epg_date = show.epg_date
    self.complete = false
  end

  def show
    @show ||= Show.find_by(uuid: show_uuid)
  end

  def record
    raise(AlreadyOverError) if show.over?
    raise(AlreadyReservedError) if reserved?

    self.start_time = show.start_time
    self.end_time = show.end_time
    self.epg_date = show.epg_date
    self.title = show.title
    self.description = show.description
    self.file_name = show.file_name
    self.channel_name = show.channel_name
    self.channel_number = show.channel_number
    self.duration = show.duration
  end

  def reserved?
    Recording.where(
      :show_uuid => show_uuid,
      :id.nin => [id.to_s]
    ).count.positive?
  end

  private

  def unreserve
    # unreserve code block here
  end

  def evaluate_flags
    self.complete = tasks.empty?
  end
end
