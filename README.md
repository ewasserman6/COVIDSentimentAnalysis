COVIDSentimentAnalysis - Instructions of use in Docker container

There are two working parts to our projects. 
	1: Python Sentiment Score.
	2: R Sentiment Analysis

1. Sentiment score based on an input in the sentiment.input file.
   Our current input is coronavirus.

	Software needed: Python3. A text editor to run Python3.  

	Run/compile instructions: python3 covid.py < sentiment.input

2. This sentiment analysis gives us visualizations for sentiment based on the input
   in the R file.
	
	Software needed: RStudio. R. Must install all packages at the top of the 
			 R file.

	Run/compile instructions: Click Command-Return on each line of the R file.
