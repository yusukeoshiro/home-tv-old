class DriveWrapper
  class AccessToken
    include Singleton

    attr_accessor :client, :token
    def initialize
      self.client = OAuth2::Client.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
        {
          site: 'https://accounts.google.com',
          authorize_url: 'o/oauth2/auth',
          token_url: 'o/oauth2/token'
        })
      hash = JSON.parse($redis.get('google_auth_hash'))
      self.token = OAuth2::AccessToken.new(client, hash['access_token'], hash)
      self.token = token.refresh!
    end
  end

  class File
    attr_accessor :id, :folders, :name, :is_folder
    def initialize
      self.is_folder = false
    end

    def create
      return unless is_folder

      url = 'https://www.googleapis.com/drive/v2/files'
      options = {
        headers: {
          'Authorization' => "Bearer #{access_token.token.token}",
          'Content-Type' => 'application/json'
        },
        body: {
          mimeType: "application/vnd.google-apps.folder",
          title: name
        }.to_json
      }
      result = HTTParty.post(url, options)
      raise 'failed to move' unless result.code == 200

      result = JSON.parse(result.body)
      set_from_item(result)
    end

    def access_token
      @access_token ||= AccessToken.instance
    end

    def move_to_folder(folder_id)
      url = "https://www.googleapis.com/drive/v2/files/#{id}?addParents=#{folder_id}&removeParents=#{current_folders}"
      options = {
        headers: {
          Authorization: "Bearer #{access_token.token.token}"
        }
      }
      result = HTTParty.put(url, options)
      raise 'failed to move' unless result.code == 200

      :ok
    end

    def current_folders
      ids = []
      folders.each do |folder|
        ids << folder.id
      end
      ids.join(',')
    end

    def set_from_item(item)
      # file = DriveWrapper::File.new
      self.id = item['id']
      self.name = item['title']
      self.is_folder = item['mimeType'] == 'application/vnd.google-apps.folder'
      self.folders = []

      item['parents'].each do |obj|
        folder = DriveWrapper::File.new
        folder.id = obj['id']
        folder.is_folder = true
        self.folders << folder
      end
      self
    end

    def self.find_by_name(file_name)
      my_token = DriveWrapper::AccessToken.instance
      url = URI.encode("https://www.googleapis.com/drive/v2/files?q=title='#{file_name}'")

      options = {
        headers: {
          Authorization: "Bearer #{my_token.token.token}"
        }
      }
      result = HTTParty.get(url, options)
      result = JSON.parse(result.body)
      return nil if result['items'].nil?
      return nil unless result['items'].length == 1

      file = DriveWrapper::File.new
      file.set_from_item(result['items'].first)
      file
    end
  end
end
