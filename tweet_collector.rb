require 'yaml'
require 'json'
require 'typhoeus'
require 'sqlite3'
require 'active_record'

$CONFIG_FILE = 'config.yaml'
$CONFIG_KEY_DB = :database_config
$CONFIG_KEY_TWITTER_API = :twitter_api
$CONFIG_KEY_TWITTER_API_API_KEY = :api_key
$CONFIG_KEY_TWITTER_API_API_KEY_SECRET = :api_key_secret
$CONFIG_KEY_TWITTER_API_BEARER_TOKEN = :bearer_token

@config = YAML.load(File.read(File.expand_path("../#{$CONFIG_FILE}", __FILE__)), symbolize_names: true)

$DATABASE_CONFIG = @config[$CONFIG_KEY_DB]

twitter_api_config = @config[$CONFIG_KEY_TWITTER_API]
twitter_api_requests = twitter_api_config[:requests]

$BEARER_TOKEN = twitter_api_config[$CONFIG_KEY_TWITTER_API_BEARER_TOKEN]

$RULES_URL            = twitter_api_config[:rules_url]
$STREAM_URL           = twitter_api_config[:stream_url]
$FILTERED_STREAM_URL  = twitter_api_config[:filtered_stream_url]

$TWITTER_API_REQUEST_SET_RULES         = twitter_api_requests[:set_rules]
$TWITTER_API_REQUEST_GET_ALL_RULES     = twitter_api_requests[:get_all_rules]
$TWITTER_API_REQUEST_DELETE_ALL_RULES  = twitter_api_requests[:delete_all_rules]
$TWITTER_API_REQUEST_STREAM            = twitter_api_requests[:stream_connect]

@location_keywords = ["adana" ,"kocaeli", "istanbul", "izmir", "ankara"]

#Connections
def stream_connect(stream_filtered = false, &block)
  request_url = stream_filtered ? $FILTERED_STREAM_URL : $STREAM_URL
  request = Typhoeus::Request.new(request_url, $TWITTER_API_REQUEST_STREAM)
  request.on_body do |chunk|
    p chunk = JSON.parse(chunk)
    if block_given?
      yield(chunk)
    else
      p chunk
    end
  end
  request.run
end

# Post request to add rules to your stream
def set_rules
  $TWITTER_API_REQUEST_SET_RULES[:body] = JSON.dump $TWITTER_API_REQUEST_SET_RULES[:body]
  Typhoeus::Request.new($RULES_URL, $TWITTER_API_REQUEST_SET_RULES).run
end

def get_all_rules
  response = Typhoeus::Request.new($RULES_URL, $TWITTER_API_REQUEST_GET_ALL_RULES).run
  JSON.parse(response.body)
end

def delete_all_rules(rules)
  rules_data = rules['data']

  unless rules_data == nil
    ids = rules['data'].map { |rule| rule["id"] }
    payload = {
      delete: {
        ids: ids
      }
    }

    $TWITTER_API_REQUEST_DELETE_ALL_RULES[:body] = JSON.dump(payload)
    Typhoeus::Request.new($RULES_URL, $TWITTER_API_REQUEST_DELETE_ALL_RULES).run
  end
end

def abstract_stream_job(&block)
  if block_given?
    timeout = 0
    while true
      yield()
      sleep 5
      timeout += 1
    end
  end
end

#DB
class FilteredTweet < ActiveRecord::Base
end

class SampleTweet < ActiveRecord::Base
end

class CreateFilteredTweetTable < ActiveRecord::Migration[5.2]
  def up
    unless ActiveRecord::Base.connection.table_exists?(:filtered_tweets)
      create_table :filtered_tweets do |table|
        table.string :tweet_id
        table.string :name
        table.string :screen_name
        table.string :tweet_text
        table.string :home_location
        table.string :mention_location
        table.string :lvalue
      end
    end
  end
end

class CreateSampleTweetTable < ActiveRecord::Migration[5.2]
  def up
    unless ActiveRecord::Base.connection.table_exists?(:sample_tweets)
      create_table :sample_tweets do |table|
        table.string :tweet_id
        table.string :name
        table.string :screen_name
        table.string :tweet_text
        table.string :home_location
        table.string :mention_location
        table.string :lvalue
      end
    end
  end
end

#Utils
def stream_to_model(tweet_data, sample = false)
  data = tweet_data["data"]
  tweet_text = data["text"]
  mention_location = get_mention_location tweet_text
  author = tweet_data["includes"]["users"].select {|user| user["id"] == data["author_id"]}[0]
  home_location = author["location"]

  tweet_class = sample ? SampleTweet : FilteredTweet

  if sample == true
      tweet_text = get_tweet_text_without_locations tweet_text
  end

  p get_valid_location(home_location)
  p mention_location
  p tweet_data
  if ((mention_location != nil || (home_location_valid?(home_location) && home_location != nil)) && !tweet_text.include?("RT"))
    tweet_class.create do |tweet|

      home_location = get_valid_location(home_location)
      lvalue = home_location == nil ? mention_location : home_location


      tweet.tweet_id          = data["id"]
      tweet.name              = author["username"]
      tweet.screen_name       = author["name"]
      tweet.tweet_text        = tweet_text
      tweet.home_location     = home_location
      tweet.mention_location  = mention_location
      tweet.lvalue            = lvalue
    end
  end
end

def get_mention_location(text)
  m_location = text
    .split(' ')
    .reject(&:empty?)
    .select {|w| @location_keywords.any? {|loc| replace_invalid_characters(w).downcase.include? loc.downcase}}
    .uniq

  p m_location
  if m_location.size == 1
    p replace_invalid_characters(m_location[0])
    @location_keywords.select {|w| replace_invalid_characters(m_location[0]).downcase.include? w.downcase}[0]
  else
    nil
  end
end

def get_valid_location(str)
  return nil if str == nil
  @location_keywords.select {|w| replace_invalid_characters(str).downcase.include? w.downcase}[0]
end

def home_location_valid?(str)
  return true if str == nil
  replace_invalid_characters(str).downcase
  @location_keywords.include?(replace_invalid_characters(str).downcase)
end

def replace_invalid_characters(str)
  replacements = { 'İ' => 'i'}
  temp = str.dup
  temp.gsub(Regexp.union(replacements.keys), replacements)
end

def get_tweet_text_without_locations(str)
  temp = str.dup
  temp.gsub(Regexp.union(@location_keywords), "")
  temp.gsub /\S*[İi]zm[iİ]r\S*|\S*[İi]stanbul\S*|\S*ankara\S*|\S*kocael[iİ]\S*|\S*adana\S*/ui, ''
end
