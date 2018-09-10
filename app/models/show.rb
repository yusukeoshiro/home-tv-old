class Show
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
        return 0 if self.end_time < DateTime.now

        if self.start_time < DateTime.now
            # started already
            return ( ( self.end_time - DateTime.now ) * 60 * 60 * 24 ).to_i
        else
            return self.duration
        end
    end

    def is_showing_now
        return (DateTime.now > self.start_time) && (DateTime.now <= self.end_time)
    end

    def record
        ShowRecorderWorker.perform_at( self.start_time, self.uuid )
    end

end