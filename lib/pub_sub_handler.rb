class PubSubHandler
  require 'google/cloud/pubsub'

  if Rails.env.development?
    Google::Cloud::PubSub.configure do |config|
      config.credentials = "#{Rails.root}/service_account.json"
    end
  end

  def self.publish(topic, payload)
    pubsub = Google::Cloud::Pubsub.new
    topic = pubsub.topic topic
    topic.publish payload.to_json
  end
end
