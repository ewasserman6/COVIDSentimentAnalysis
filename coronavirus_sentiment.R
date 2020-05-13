library(tidyverse)
library(tidytext) 
library(wordcloud2)
library(textdata)
library(lubridate)
library(rtweet)
library(ggthemes)
library('maps')

fix.contractions <- function(doc) {
  doc <- gsub("won't", "will not", doc)
  doc <- gsub("can't", "can not", doc)
  doc <- gsub("n't", " not", doc)
  doc <- gsub("'ll", " will", doc)
  doc <- gsub("'re", " are", doc)
  doc <- gsub("'ve", " have", doc)
  doc <- gsub("'m", " am", doc)
  doc <- gsub("'d", " would", doc)
  doc <- gsub("'s", "", doc)
  return(doc)
}

removeSpecialChars <- function(x) gsub("[^a-zA-Z0-9 ]", " ", x)

api_key <- 'XXXXXXXXXXXXXXXXXXXXXXXXX'
api_secret_key <- 'XXXXXXXXXXXXXXXXXXXXXXXXX'
access_token <- 'XXXXXXXXXXXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXX'
access_token_secret <- 'XXXXXXXXXXXXXXXXXXXXXXXXX'

token <- create_token(
  app = "NAME OF YOUR APP HERE",
  consumer_key = api_key,
  consumer_secret = api_secret_key,
  access_token = access_token,
  access_secret = access_token_secret)

Rona <- search_tweets("#coronavirus", n = 15000, lang = 'en',
                     tweet_mode = 'extended', include_rts = FALSE,
                     retryonratelimit = TRUE, geocode = lookup_coords("usa"))

Rona_sc <- search_tweets("coronavirus stimulus check", n = 15000, lang = 'en',
                     tweet_mode = 'extended', include_rts = FALSE,
                     retryonratelimit = TRUE, geocode = lookup_coords("usa"))
view(Rona_sc)

Rona_trump <- search_tweets("#coronavirus #trump", n = 15000, lang = 'en',
                     tweet_mode = 'extended', include_rts = FALSE,
                     retryonratelimit = TRUE, geocode = lookup_coords("usa"))


Rona$text <- iconv(Rona$text, to = "ASCII", sub = " ")  # Convert to basic ASCII text to avoid silly characters
Rona$text <- tolower(Rona$text)  # Make everything consistently lower case
Rona$text <- gsub("rt", " ", Rona$text)  # Remove the "RT" (retweet) so duplicates are duplicates
Rona$text <- gsub("@\\w+", " ", Rona$text)  # Remove user names (all proper names if you're wise!)
Rona$text <- gsub("http.+ |http.+$", " ", Rona$text)  # Remove links
Rona$text <- gsub("[[:punct:]]", " ", Rona$text)  # Remove punctuation
Rona$text <- gsub("[ |\t]{2,}", " ", Rona$text)  # Remove tabs
Rona$text <- gsub("amp", " ", Rona$text)  # "&" is "&amp" in HTML, so after punctuation removed ...
Rona$text <- gsub("^ ", "", Rona$text)  # Leading blanks
Rona$text <- gsub(" $", "", Rona$text)  # Lagging blanks
Rona$text <- gsub(" +", " ", Rona$text) # General spaces (should just do all whitespaces no?)
Rona <- distinct(Rona, text, .keep_all = TRUE)  # Now get rid of duplicates!

Rona$text <- fix.contractions(Rona$text)
Rona$text <- removeSpecialChars(Rona$text)

#Remove common words
badWords <- c("coronavirus", "covid19", "covid", "trump")

#This creates the tidy dataframe of every word per tweet on a single line, but all words are still mapped to individual tweets.
tidy_Rona <- Rona %>%
  unnest_tokens(word, text) %>%
  anti_join(stop_words) %>%
  distinct() %>%
  filter(!word %in% badWords) %>%
  filter(nchar(word) > 3)

help("search_tweets")
#most popular words
tidy_Rona %>%
  count(word, sort = TRUE) %>%
  top_n(20) %>%
  ungroup() %>%
  mutate(word = reorder(word, n)) %>%
  ggplot() +
  geom_col(aes(word, n)) +
  theme(legend.position = "none", 
        plot.title = element_text(hjust = 0.5),
        panel.grid.major = element_blank()) +
  xlab("") + 
  ylab("Tweet Count") +
  ggtitle("Most Frequently Used Words in #coronavirus Tweets containing 'trump'") +
  scale_y_continuous(breaks = seq(0,1000,100)) +
  theme_clean() +
  coord_flip()

#wordcloud
tweet_counts <- tidy_Rona %>%
  count(word, sort = TRUE) 
tweet_counts

wordcloud2(tweet_counts[1:300, ], size = .5)

#Grabbing sentiments
Rona_bing <- tidy_Rona %>%
  inner_join(get_sentiments("bing"))

Rona_nrc <- tidy_Rona %>%
  inner_join(get_sentiments("nrc"))

Rona_nrc_sub <- tidy_Rona %>%
  inner_join(get_sentiments("nrc")) %>%
  filter(!sentiment %in% c("positive", "negative"))

#General Sentiment
Rona_nrc %>%
  group_by(sentiment) %>%
  summarise(word_count = n()) %>%
  ungroup() %>%
  mutate(sentiment = reorder(sentiment, word_count, fill = -word_count)) %>%
  ggplot(aes(sentiment, word_count)) +
  geom_col() +
  theme_economist() + xlab(NULL) + ylab(NULL) +
  ggtitle("Sentiment Counts for #coronavirus and 'trump'", "Using the NRC Lexicon") +
  scale_y_continuous(breaks = seq(0,7000,1000)) +
  coord_flip()

#Polarity of Tweets over Time
Rona_bing$date_created <- as_date(Rona_bing$created_at)

#Polarity of the tweet as it pertains to the hour of the day.
Rona_bing_time <- Rona_bing %>%
  mutate(datetime_created = as_datetime(created_at)) %>%
  mutate(hour = hour(datetime_created))

Rona_bing_polarity_hourly <- Rona_bing_time %>%
  count(sentiment, hour) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(polarity = positive - negative,
         percent_positive = positive / (positive + negative) * 100)

ggplot(Rona_bing_polarity_hourly, aes(hour, polarity)) +
  geom_col() +
  geom_smooth(method = "loess", se = FALSE) +
  theme(plot.title = element_text(size = 11)) +
  xlab(NULL) + ylab(NULL) +
  ggtitle("Trend of Polarity over the Course of the Day")




#Polarity as it relates to the day since the tweet was made.
Rona_polarity_daily <- Rona_bing %>%
  count(sentiment, date_created) %>%
  spread(sentiment, n, fill = 0) %>%
  mutate(polarity = positive - negative,
         percent_positive = positive / (positive + negative) * 100)



ggplot(Rona_polarity_daily, aes(date_created, polarity)) +
  geom_col() +
  geom_smooth(method = "loess", se = FALSE) +
  theme(plot.title = element_text(size = 11)) +
  xlab(NULL) + ylab(NULL) +
  ggtitle("Polarity of Tweets over Time with #coronavirus and 'trump'")


ggplot(Rona_polarity_daily, aes(date_created, percent_positive)) +
  geom_col() +
  geom_smooth(method = "loess", se = FALSE) +
  theme(plot.title = element_text(size = 11)) +
  xlab(NULL) + ylab(NULL) +
  ggtitle("Percent Positive of Tweets per Day with #coronavirus and 'trump'")

#Quantity of tweets as a time series plot.
Rona %>%
  ts_plot("3 hours") +
  ggplot2::theme_minimal() +
  ggplot2::theme(plot.title = ggplot2::element_text(face = "bold")) +
  ggplot2::labs(
    x = NULL, y = NULL,
    title = "Frequency of #coronavirus and 'trump' Twitter tweets",
    subtitle = "Tweet counts aggregated using three-hour intervals"
  )


#Looking at the age of the twitter accounts. Change the binwidth to whatever you see fit as the data is grouped by months. One bin = one month.
Rona$account_created_at <- as_date(Rona$account_created_at)

# IMPORTANT
Rona %>%
  distinct() %>%
  mutate(age_of_account = (today() - account_created_at) / 30) %>%
  ggplot(aes(age_of_account)) + geom_histogram(binwidth = 3) +
  stat_bin(binwidth=3, geom="text", colour="white", size=3,
           aes(label=..count..), position=position_stack(vjust=0.5)) +
  ggtitle("Age of Twitter Accounts") + xlab(NULL) + ylab(NULL)


#Top 20 most occuring tweet sources.
Rona %>%
  filter(location != "" & location != "Canada" & location != "Australia" & location != "NYC") %>%
  count(location, sort = TRUE) %>%
  mutate(location = reorder(location, n)) %>%
  top_n(18) %>%
  ggplot(aes(x = location, y = n)) +
  geom_col() +
  coord_flip() +
  labs(x = "Count",
       y = "Location",
       title = "Where Twitter users are from - unique locations ")  

Rona <- lat_lng(Rona)

## plot state boundaries
par(mar = c(0, 0, 0, 0))
maps::map("state", lwd = .25)

## plot lat and lng points onto state map
with(Rona_sc, points(lng, lat, pch = 20, cex = .75, col = rgb(0, .3, .7, .75)))
