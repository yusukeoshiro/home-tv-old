require 'sidekiq-scheduler'

class MoveScheduler
  include Sidekiq::Worker

  def perform
    my_token = DriveWrapper::AccessToken.instance
    my_token.token = my_token.token.refresh!
    recordings_to_move = Recording.to_move
    return if recordings_to_move.empty?

    default_folder = DriveWrapper::File.find_by_name('Home TV')

    recordings_to_move.each do |recording|
      p recording.show.title
      show = recording.show
      file_name = show.file_name + '.mp4'
      p 'searching google drive by ' + file_name
      file = DriveWrapper::File.find_by_name(file_name)
      p 'found...'
      p file
      next if file.nil?

      target_folder = nil
      if recording.reservation.present?
        target_folder = DriveWrapper::File.find_by_name(recording.reservation.folder_name)
        if target_folder.nil?
          target_folder = DriveWrapper::File.new
          target_folder.name = recording.reservation.folder_name
          target_folder.is_folder = true
          target_folder.create
          target_folder.move_to_folder(default_folder.id)
        end
      else
        target_folder = default_folder
      end

      p 'target folder is...'
      p target_folder

      file.move_to_folder(target_folder.id)

      extension = File.extname(file.name)
      name = File.basename(file.name, '.*')
      new_file_name = "#{name}_#{show.title}#{extension}"
      file.rename(new_file_name)

      recording.tasks = []
      recording.save
    end
  end
end
