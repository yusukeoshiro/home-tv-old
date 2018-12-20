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
  field :show_uuid, type: String
  field :epg_date, type: Date
  field :tasks, type: Array
  field :complete, type: Boolean

  scope :to_move, -> { where('tasks.1' => { :$exists => false }, complete: false, tasks: 'MOVE') }
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

    jid = ShowRecorderWorker.perform_at(show.start_time, show.uuid)
    self.job_id = jid
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
