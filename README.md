# ML Tweet Location Prediction

A demo application shows basics about using Twitter API v2 and tweet classification depending on location data.

## Features:
### Tweet Collector:
* Rebuild API rules (so API can use to fetch tweets).
* Delete API rules.
* Perform sample tweet stream monitoring.
* Listen sample tweet stream and save to database.
* Listen filtered tweet stream and save to database.
## Classification:
* Lemmatize tweets and cache (because lemmatizing ~10000 tweets is a costy job and takes time).
* SVM classification with/without lemmatized tweets.
* Naive Bayes classification with/without lemmatized tweets.

---

## Used Technologies
* Ruby (Rake, Active Record, Typhoeus)
* Python (Zeyrek, Numpy, Seaborn, Sklearn, Matbplot)
* Sqlite3

## Usage
### Twitter API 
To connect to Twitter API used in project, you need to insert your *API Key*, *API Key Secret* and *Bearer Token* to related field in `config.yaml`
```yaml
twitter_api:
  api_key:        xxxx
  api_key_secret: xxxx
  bearer_token:   xxxx
```
### Rake Tasks
Application features are used with rake tasks. To get the list of rake tasks, use `$ rake -T` in project directory.
```ruby
$ rake -T
rake classification:lemmatized:lemmatize_and_cache    # Create and cache lemmetized data as .json
rake classification:lemmatized:naive_bayes            # Naive Bayes classification with lemmatized tweet texts
rake classification:lemmatized:svm                    # Support vector classification with lemmatized tweet texts
rake classification:naive_bayes                       # Naive Bayes classification
rake classification:svm                               # Support vector classification
rake db:create_filtered_tweets_table                  # Creates filtered tweets table if not exist
rake db:create_sample_tweets_table                    # Creates sample tweets table if not exist
rake tweet_collector:build_rules                      # Updates filter rules
rake tweet_collector:delete_rules                     # Deletes filter rules
rake tweet_collector:sample_stream                    # Runs a sample stream
rake tweet_collector:update_db_with_filtered_samples  # Updates database with "filtered" samples
rake tweet_collector:update_db_with_samples           # Updates database with new samples
```
