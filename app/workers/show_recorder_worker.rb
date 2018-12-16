class ShowRecorderWorker
  include Sidekiq::Worker

  def perform(show_uuid)
    show = Show.find_by(uuid: show_uuid)
    puts "recording #{show.title} / #{show.uuid}"
    if show.over?
      puts 'the show is already finished!'
    else
      payload = {
        'command' => 'RECORD',
        'show' => {
          'show' => show,
          'footage_duration' => 10 # show.footage_duration
        }
      }
      $redis.publish 'command_request', payload.to_json

      recording = Recording.find_by(show_uuid: show_uuid)
      tasks = recording.tasks
      tasks.delete('TRIGGER_RECORD')
      recording.update(tasks: tasks)
    end
  end
end
