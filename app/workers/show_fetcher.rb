class ShowFetcher
    include Sidekiq::Worker
    def perform date
        begin
            require 'net/http'
            Time.zone = "Tokyo"
            channel_dictionary = {
                "1.NHK総合・東京" => 27,
                "2.Eテレ・東京" => 26,
                "4.日テレ" => 25,
                "5.テレビ朝日" => 24,
                "6.TBS" => 22,
                "7.テレビ東京"=> 23,
                "8.フジテレビ" => 21,
                "9.TOKYO　MX" => 16,
                "12.放送大学" => 28
            }

            date = Date.parse date
            Show.where(:epg_date => date).delete
            channels = []
            source = Net::HTTP.get("tver.jp", "/app/epg/23/#{date.strftime("%Y-%m-%d")}/otd/true")
            source.force_encoding("utf-8")
            doc = Nokogiri::HTML.parse(source)

            doc.xpath('//div[@class="station"]').each do |node|
                channels << node.content.strip
            end
            total_height = doc.css('.epgtime').last.attr("style")[/height:(.*?)px;/m, 1].to_i
            hour_height_approx = total_height.to_f / 24
            approximater = []

            doc.css(".pgbox").each do |show|
                if show.css(".min").first.content == "00"
                    title = show.css('.title').first.content
                    top = show.attr("style")[/top:(.*?)px;/m, 1].to_f
                    next if top == 0
                    hour_height = top / (top / hour_height_approx).round
                    approximater << hour_height
                end
            end

            hour_height_exact = approximater.inject{ |sum, el| sum + el }.to_f / approximater.size
            doc.css(".stationRate").each_with_index do |node,i|
                node.css('.pgbox').each_with_index do |show|

                    show_date = date
                    top = show.attr("style")[/top:(.*?)px;/m, 1].to_f
                    height = show.attr("style")[/height:(.*?)px;/m, 1].to_f
                    hour_index = (top / hour_height_exact)
                    hour = hour_index + 5
                    duration = height / hour_height_exact * 3600

                    if hour >= 24
                        show_date = date + 1
                    end

                    minutes = show.css(".min").first.content.to_i
                    start_time = Time.zone.local(show_date.year, show_date.month, show_date.day, hour  % 24, minutes, 0)
                    end_time = start_time + duration


                    s = Show.new
                    s.title = show.css('.title').first.content
                    s.start_time = DateTime.parse( start_time.to_s )
                    s.end_time = DateTime.parse( end_time.to_s )
                    s.date = show_date
                    s.epg_date = date
                    s.duration = duration
                    s.channel_name = channels[i]
                    s.channel_number = channel_dictionary[s.channel_name]
                    s.description = show.css('p').first.content
                    s.uuid = show.attr("id")
                    s.region = "Tokyo"
                    s.delete_on = date + 30

                    begin
                        s.save
                        # puts "saved #{s.title}"
                    rescue => e
                        puts "error #{e.message} #{s.start_time} #{s.title}"
                    end
                end
            end
        rescue => e
            puts e.message
        end
    end
end