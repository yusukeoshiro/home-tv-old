class VideoManipulationWorker
  include Sidekiq::Worker

  def perform

    recordings_to_move = []
    Recording.where(complete: false).each do |recording|
      recordings_to_move << recording if recording.tasks.length == 1 && recording.tasks.include?('MOVE')
    end
    return if recordings_to_move.empty?

    default_folder = DriveWrapper::File.find_by_name('Home TV')

    recordings_to_move.each do |recording|
      show = recording.show
      file_name = show.file_name + '.mp4'
      file = DriveWrapper::File.find_by_name(file_name)
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

      file.move_to_folder(target_folder.id)
      recording.tasks.delete('MOVE')
      recording.save
    end
  end
end
