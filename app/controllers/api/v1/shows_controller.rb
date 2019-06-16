module Api
  module V1
    class ShowsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def fetch
        util = ShowFetchUtil.new
        7.times do |i|
          begin
            fetch_date = Date.today + i
            puts "fetching #{fetch_date}..."
            util.fetch(fetch_date)
          rescue => e
            puts e.message
          end
        end
        render(json: {})
      end

      def reserve
        util = ReserveUtil.new
        util.reserve
        render(json: {})
      end

      def move
        util = DriveUtil.new
        util.move
        render(json: {})
      end

      def update
        uuid = params[:uuid]
        finished = params['finished']
        recording = Recording.find_by(show_uuid: uuid)
        recording.tasks.delete(finished)
        recording.save

        render(json: {})
      end

      def index
        date = nil
        region = nil
        is_error = false
        error_message = ""
        shows = []

        if params[:date].present?
          date = Date.parse params[:date]
          Show.where(epg_date: date).each do |show|
            shows << show
          end
        else
          is_error = true
          error_message = "Please supply date parameter in your request"
        end

        if is_error
          render :json => {
            message: error_message
          }, :status => :bad_request
        else
          render :json => {
            result: shows
          }
        end
      end

      def record
        uuid = params[:uuid]
        recording = Recording.new(
          show_uuid: uuid
        )
        recording.record
        recording.save
        render :json => {}

      rescue Recording::AlreadyReservedError
        render(
          status: 400,
          json: {
            message: 'すでに録画されています'
          }
        )
      rescue Recording::AlreadyOverError
        render(
          status: 400,
          json: {
            message: 'すでに終了しています'
          }
        )
      end
    end
  end
end
