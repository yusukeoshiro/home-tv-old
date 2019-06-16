class ShowFetcher
  include Sidekiq::Worker
  def perform date
    util = ShowFetchUtil.new
    begin
      date = Date.parse(date)
      util.fetch(date)
    rescue => e
      puts e.message
    end
  end
end
