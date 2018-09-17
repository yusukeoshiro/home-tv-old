web: bundle exec puma -t 5:5 -p ${PORT:-3000} -e ${RACK_ENV:-development}
worker: bundle exec sidekiq -C config/sidekiq.yaml
recorder: ruby pi-tv/lib/main.rb
converter: ruby pi-tv/lib/watch.rb
