module Api
  module V1
    class BroadcastersController < ApplicationController
      skip_before_action :verify_authenticity_token
      def instruct
        payload = JSON.parse request.body.read
        PubSubHandler.publish('broadcaster-control', payload)
        render :json => {}
      end
    end
  end
end
