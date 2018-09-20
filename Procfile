web: bundle exec puma -t 5:5  -e ${RACK_ENV:-development} -b tcp://0.0.0.0:3000
worker: bundle exec sidekiq -C config/sidekiq.yaml
#recorder: ruby pi-tv/lib/main.rb
converter: ruby pi-tv/lib/convert.rb
uploader: ruby  pi-tv/lib/upload.rb 
