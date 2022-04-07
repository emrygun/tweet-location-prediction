require_relative 'tweet_collector'

namespace :tweet_collector do

  desc 'Runs a sample stream'
  task :sample_stream do
    begin
      abstract_stream_job stream_connect
    rescue
      retry
    end
  end

  task :filtered_stream do
    while true
      abstract_stream_job stream_connect(true)
    end
  end

  desc 'Updates filter rules'
  task :build_rules do
    delete_all_rules(get_all_rules)
    set_rules
    puts ">> Rules successfully updated"
  end

  desc 'Deletes filter rules'
  task :delete_rules do
    delete_all_rules(get_all_rules)
  end

  desc 'Updates database with new samples'
  task :update_db_with_samples do
    ActiveRecord::Base.establish_connection($DATABASE_CONFIG)

    timeout = 0
    begin
      abstract_stream_job do
        stream_connect(true) do |stream|
          stream_to_model(stream, true)
        end
        timeout = 0
      end
    rescue => e
      p e
      p ">> Reconnecting to api..."
      sleep 5
      timeout += 1
      retry
    end
  end

  desc 'Updates database with "filtered" samples'
  task :update_db_with_filtered_samples do
    ActiveRecord::Base.establish_connection($DATABASE_CONFIG)

    timeout = 0
    begin
      abstract_stream_job do
        stream_connect(true) do |stream|
          stream_to_model(stream, false)
        end
        timeout = 0
      end
    rescue => e
      p e
      p ">> Reconnecting to api..."
      sleep 5
      timeout += 1
      retry
    end
  end

end

namespace :classification do

  desc 'Naive Bayes classification.'
  task :naive_bayes do
    result = exec("python3 ./classification.py naive_bayes false")
  end

  desc 'Support vector classification.'
  task :svm do
    result = exec("python3 ./classification.py svm false")
  end

  namespace :lemmatized do
    desc 'Naive Bayes classification with lemmatized tweet texts.'
    task :naive_bayes do
      result = exec("python3 ./classification.py naive_bayes true")
    end

    desc 'Support vector classification with lemmatized tweet texts.'
    task :svm do
      result = exec("python3 ./classification.py svm true")
    end

    desc 'Create and cache lemmetized data as .json'
    task :lemmatize_and_cache do
      result = exec("python3 ./classification.py lemmatize_data_and_cache false")
    end
  end

end

namespace :db do

  desc 'Creates sample tweets table if not exist'
  task :create_sample_tweets_table do
    ActiveRecord::Base.establish_connection($DATABASE_CONFIG)
    CreateSampleTweetTable.migrate(:up)
    puts ">> Created sample_tweets table"
  end

  desc 'Creates filtered tweets table if not exist'
  task :create_filtered_tweets_table do
    ActiveRecord::Base.establish_connection($DATABASE_CONFIG)
    CreateFilteredTweetTable.migrate(:up)
    puts ">> Created filtered_tweets table"
  end

end
