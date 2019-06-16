FROM ruby:2.5.5

ENV BUNDLER_VERSION=2.0.1
ENV RACK_ENV=production
ENV RAILS_ENV=production

WORKDIR /app

# Install dependencies via Gemfile
COPY Gemfile Gemfile.lock ./
RUN gem install bundler
RUN bundle install

# Copy the rest of the files
COPY ./ ./

# start server
CMD ["bundle", "exec", "rails", "server", "-b=0.0.0.0", "-e=production"]
