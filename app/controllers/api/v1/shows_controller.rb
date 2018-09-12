module Api
    module V1
        class ShowsController < ApplicationController
            skip_before_action :verify_authenticity_token

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
                p uuid
                show = Show.find_by(:uuid => uuid)
                show.record
                render :json => {}
            end
        end
    end
end