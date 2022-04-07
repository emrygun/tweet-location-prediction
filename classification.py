import os
import sys
import yaml
import json
import zeyrek
import numpy as np
import seaborn as sns

from sklearn.pipeline import make_pipeline
from sklearn.naive_bayes import BernoulliNB, GaussianNB, MultinomialNB
from sklearn.svm import SVC
from sklearn.feature_extraction.text import CountVectorizer, TfidfVectorizer

from sklearn.metrics import confusion_matrix, accuracy_score
import matplotlib.pyplot as plt
import sqlite3 as lite

script = sys.argv[1]
is_lemmatized = sys.argv[2]

lemmatized_filtered_tweet_cache_file_name = 'filtered_tweet_lemmatized_cache.json'
lemmatized_sample_tweet_cache_file_name = 'sample_tweet_lemmatized_cache.json'

#Get the config file
def get_config_file(file_name):
    with open(file_name, "r") as stream:
        return yaml.safe_load(stream)

def get_filtered_tweets_table(db, table):
    cnx = lite.connect(db)
    cur = cnx.cursor()
    cur.execute("SELECT * FROM " + table)
    return np.array(cur.fetchall())

config = get_config_file('config.yaml')
database = config['database_config']['database']

def get_lemmatized_tweets():
    with open(lemmatized_filtered_tweet_cache_file_name, "r") as read_file:
       filtered = np.array(json.load(read_file))

    with open(lemmatized_sample_tweet_cache_file_name, "r") as read_file:
       sample = np.array(json.load(read_file))

    return {
            "filtered": filtered,
            "sample": sample
        }

filtered_tweets = get_lemmatized_tweets()["filtered"] if (is_lemmatized == 'true') else \
        get_filtered_tweets_table(database, "filtered_tweets")
sample_tweets   = get_lemmatized_tweets()["sample"] if (is_lemmatized == 'true') else \
        get_filtered_tweets_table(database, "sample_tweets")

#Variables
tweet_idx_num               = 0
tweet_idx_id                = 1
tweet_idx_username          = 2
tweet_idx_screen_name       = 3
tweet_idx_text              = 4
tweet_idx_home_location     = 5
tweet_idx_mention_location  = 6
tweet_idx_lvalue_location   = 7

#Tweet columns
tweet_num               = filtered_tweets[:, tweet_idx_num]
tweet_id                = filtered_tweets[:, tweet_idx_id]
tweet_username          = filtered_tweets[:, tweet_idx_username]
tweet_screen_name       = filtered_tweets[:, tweet_idx_screen_name]
tweet_text              = filtered_tweets[:, tweet_idx_text]
tweet_home_location     = filtered_tweets[:, tweet_idx_home_location]
tweet_mention_location  = filtered_tweets[:, tweet_idx_mention_location]
tweet_lvalue_location   = filtered_tweets[:, tweet_idx_lvalue_location]

tweet_screen_name_splitted  = list(map(lambda name: name.split(' '), tweet_screen_name))
tweet_text_splitted         = list(map(lambda text: text.split(' '), tweet_text))
tweet_username_splitted     = list(map(lambda username: username.split(), tweet_username))
tweet_lvalue_splitted       = list(map(lambda lvalue: lvalue.split(), tweet_lvalue_location))

sample_tweet_text               = sample_tweets[:, tweet_idx_text]
sample_tweet_lvalue_location    = sample_tweets[:, tweet_idx_lvalue_location]


analyzer = zeyrek.MorphAnalyzer()
data_count = min(sample_tweet_text.size, tweet_text.size)
labels = ["istanbul", "izmir", "ankara", "kocaeli", "adana"]

lemmatized_string = lambda string : " ".join(map(lambda x : x[1][0], analyzer.lemmatize(string)))
lemmatize_list = lambda x : list(map(lambda string : lemmatized_string(string), x))

#Lemmatize data and cache
def lemmatize_and_cache():
    print(">> Lemmatizing tweets..")
    lemmatized_sample_tweet_text_list = lemmatize_list(sample_tweet_text)
    print(">> Sample tweets lemmatized.")
    lemmatized_filtered_tweet_text_list = lemmatize_list(tweet_text)
    print(">> Filtered tweets lemmatized.")

    filtered_tweets[:, tweet_idx_text] = lemmatized_filtered_tweet_text_list
    sample_tweets[:, tweet_idx_text] = lemmatized_sample_tweet_text_list

    with open(lemmatized_filtered_tweet_cache_file_name, 'w') as filtered_cache:
        json.dump(filtered_tweets.tolist(), filtered_cache)
    with open(lemmatized_sample_tweet_cache_file_name, 'w') as sample_cache:
        json.dump(sample_tweets.tolist(), sample_cache)

    print(">> Done!")


def show_confusion_matrix(prediction):
    mat = confusion_matrix(prediction, tweet_lvalue_location[:data_count])
    cf_matrix = sns.heatmap(mat.T, annot=True, fmt = "d", xticklabels=labels ,yticklabels=labels)
    print("The accuracy is {}".format(accuracy_score(sample_tweet_lvalue_location[:data_count], prediction[:data_count])))
    plt.xlabel("true labels")
    plt.ylabel("predicted label")
    plt.show()

#Classifications
################

#Naive Bayes Classification
def naive_bayes_classification():
    model = make_pipeline(CountVectorizer(), MultinomialNB())
    model.fit(tweet_text, tweet_lvalue_location)
    predicted_categories = model.predict(sample_tweet_text[:data_count])

    show_confusion_matrix(predicted_categories)

#Support Vector Classification
def svm_classification():
    model = make_pipeline(CountVectorizer(), SVC(kernel='rbf'))
    model.fit(tweet_text, tweet_lvalue_location)
    predicted_categories = model.predict(sample_tweet_text[:data_count])

    show_confusion_matrix(predicted_categories)

def run_script(x):
    funcs = {
        'lemmatize_data_and_cache': lemmatize_and_cache,
        'naive_bayes':              naive_bayes_classification,
        'svm':                      svm_classification
    }
    return funcs[x]()

run_script(script)
