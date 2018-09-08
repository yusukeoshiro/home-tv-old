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

end