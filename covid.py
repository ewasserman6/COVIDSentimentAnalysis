# twitterexaqmple.py
# Demonstrates connecting to the twitter API and accessing the twitter stream
# Author: Eric Wasserman
# Email: ewasserman@chapman.edu
# Course: CPSC 353
# Assignment: PA01 Sentiment Analysis
# Version 1.2
# Date: February 15, 2016

# Demonstrates connecting to the twitter API and accessing the twitter stream

import twitter
import json
import sys
import codecs

# XXX: Go to http://dev.twitter.com/apps/new to create an app and get values
# for these credentials, which you'll need to provide in place of these
# empty string values that are defined as placeholders.
# See https://dev.twitter.com/docs/auth/oauth for more information
# on Twitter's OAuth implementation.

sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
print('Example 1')
print('Establish Authentication Credentials')

CONSUMER_KEY = 'S4z6E2aLlLHaaPR6cbChGOJVX'
CONSUMER_SECRET = '1USON4EKBgrVOXqx7uaSE8ZhsoL78atREDFUKTSCQgM93Oml5I'
OAUTH_TOKEN = '3147026412-PbF8eGGy47OwTatxhJ55uswopGoP1ZZwgGTnacZ'
OAUTH_TOKEN_SECRET = 'MQrNZ19lC8ifKc3j3KsfIFqSsIfC1RgTCSvvTx2uREdoN'

auth = twitter.oauth.OAuth(OAUTH_TOKEN, OAUTH_TOKEN_SECRET,
                           CONSUMER_KEY, CONSUMER_SECRET)

twitter_api = twitter.Twitter(auth=auth)

# XXX: Set this variable to a trending topic,
# or anything else for that matter. The example query below
# was a trending topic when this content was being developed
# and is used throughout the remainder of this chapter.

# q = '#MentionSomeoneImportantForYou'
q = input('Enter a search term: ')
print(q)
# print q
# input("Press Enter to continue")

p = input('Enter a search term: ')

print(p)

count = 1000

#See https://dev.twitter.com/docs/api/1.1/get/search/tweets

search_results = twitter_api.search.tweets(q=q,count=count)

#search_results1 = twitter_api.search.tweets(p=p, count=count)

#statuses = search_results1['statuses1']

statuses = search_results['statuses']

for _ in range(5):
    print("Length of statuses", len(statuses))
    try:
        next_results = search_results['search_metadata']['next_results']
    # except KeyError, e:  # No more results when next_results doesn't exist
    except KeyError:
        break

    # Create a dictionary from next_results, which has the following form:
    # ?max_id=313519052523986943&q=NCAA&include_entities=1
    kwargs = dict([kv.split('=') for kv in next_results[1:].split("&")])

    search_results = twitter_api.search.tweets(**kwargs)
    statuses += search_results['statuses']

#for _ in range(5):
#    try:
#        next_results1 = search_results1['search_metadata']['nextresults1']
#    except KeyError:
#        break

print()
print("---------------------------------------------------------------------")
print()

status_texts = [status['text']
		for status in statuses]

words = [w
	for t in status_texts
	for w in t.split()]

sent_file = open('AFINN-111.txt')

scores = {}  # initialize an empty dictionary
#scores1 = {}
for line in sent_file:
    term, score = line.split("\t")
    # The file is tab-delimited.
    # "\t" means "tab character"
    scores[term] = int(score)  # Convert the score to an integer.

score = 0
for word in words:
    uword = word.encode('utf-8')
    if word in scores.keys():
        score = score + scores[word]
print("The sentiment score of the coronavirus is: " , float(score))
