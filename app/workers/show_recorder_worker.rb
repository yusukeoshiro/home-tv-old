class ShowRecorderWorker
    include Sidekiq::Worker
    RECORD_PATH = "/mnt/PIHDD"

    def perform show_uuid
        show = Show.find_by(:uuid => show_uuid)
        puts "recording #{show.title} / #{show.uuid}"
        if show.is_over
            puts "the show is already finished!"
        else
            command = "recpt1 --b25 --strip #{show.channel_number} #{show.footage_duration} #{RECORD_PATH}/#{show.uuid}.ts &"
            # command = "recpt1 --b25 --strip #{show.channel_number} 10 #{RECORD_PATH}/#{show.uuid}.ts &"
            payload = {
                "command" => command,
                "show" => show
            }
            $redis.publish "command_request", payload.to_json

        end
    end
end