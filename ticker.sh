#!/usr/bin/env bash

### ticker.sh [original script by Partic Stadler https://github.com/pstadler/ticker.sh]
### fork by meekser [https://github.com/meekser/ticker.sh]
### version 2.0a
ver="2.0a"
date="2020.11.17"

set -e

LANG=C
LC_NUMERIC=C

SYMBOLS=("$@")
potentialLoopInterval=("$2")
  
### config fire veriable
CONFIG=~/.ticker.conf

### functions
function singlerun {

  if [ -z "$SYMBOLS" ]; then
    echo "Usage: ./ticker.sh aapl ^DJI btc-usd eur=x"
    exit
  fi

  FIELDS=(symbol shortName currency marketState regularMarketPrice regularMarketChange regularMarketChangePercent
    preMarketPrice preMarketChange preMarketChangePercent postMarketPrice postMarketChange postMarketChangePercent)
  API_ENDPOINT="https://query1.finance.yahoo.com/v7/finance/quote?lang=en-US&region=US&corsDomain=finance.yahoo.com"

  if [ -z "$NO_COLOR" ]; then
    : "${COLOR_BOLD:=\e[1;37m}"
    : "${COLOR_GREEN:=\e[32m}"
    : "${COLOR_RED:=\e[31m}"
    : "${COLOR_RESET:=\e[00m}"
  fi

  symbols=$(
    IFS=,
    echo "${SYMBOLS[*]}"
  )
  fields=$(
    IFS=,
    echo "${FIELDS[*]}"
  )

  results=$(curl --silent "$API_ENDPOINT&fields=$fields&symbols=$symbols" | jq '.quoteResponse .result')

  query() {
    echo $results | jq -r ".[] | select(.symbol == \"$1\") | .$2"
  }
  printf "%-12s%8s%13s%12s%7s\n" "Symbol" "Price" "VAR" "%VAR" "Name"
  for symbol in $(
    IFS=' '
    echo "${SYMBOLS[*]}" | tr '[:lower:]' '[:upper:]' 
  ); do
    marketState="$(query $symbol 'marketState')"

    if [ -z $marketState ]; then
      printf 'No results for symbol "%s"\n' $symbol
      continue
    fi

    name="$(query $symbol 'shortName')"
    currency="$(query $symbol 'currency')"
    preMarketChange="$(query $symbol 'preMarketChange')"
    postMarketChange="$(query $symbol 'postMarketChange')"

    if [ $marketState == "PRE" ] &&
      [ $preMarketChange != "0" ] &&
      [ $preMarketChange != "null" ]; then
      nonRegularMarketSign='*'
      price=$(query $symbol 'preMarketPrice')
      diff=$preMarketChange
      percent=$(query $symbol 'preMarketChangePercent')
    elif [ $marketState != "REGULAR" ] &&
      [ $postMarketChange != "0" ] &&
      [ $postMarketChange != "null" ]; then
      nonRegularMarketSign='*'
      price=$(query $symbol 'postMarketPrice')
      diff=$postMarketChange
      percent=$(query $symbol 'postMarketChangePercent')
    else
      nonRegularMarketSign=' '
      price=$(query $symbol 'regularMarketPrice')
      diff=$(query $symbol 'regularMarketChange')
      percent=$(query $symbol 'regularMarketChangePercent')
    fi

    if [ "$diff" == "0" ]; then
      color=
    elif (echo "$diff" | grep -q ^-); then
      color=$COLOR_RED
    else
      color=$COLOR_GREEN
    fi

    if [ "$price" != "null" ]; then
      printf "%-12s$COLOR_BOLD%8.2f$COLOR_RESET %-s" $symbol $price $currency
      printf "$color%9.2f%12s$COLOR_RESET" $diff $(printf "(%.2f%%)" $percent)
      printf " %-s" "$nonRegularMarketSign" $(printf "%15s" $name)
      printf "\n"
    fi
  done

}

function loop {

	loopInterval=("$potentialLoopInterval")

        IFS=' ' read -r -a SYMBOLS <<< `egrep -v "^#|^refreshRate|^$" $CONFIG | tr "\n" " "`	
	
	if [ "$loopInterval" = 0 ]
	then
          singlerun
        else
          while true
          do
            singlerun
            sleep $loopInterval
            clear
          done            
        fi
        exit 0
}

function help {

	echo "
ticker.sh - is a bash script to follow stocks/forex pairs/crypto tickers using Yahoo Finance API (delayed)
based on ticker.sh created by Patric Stadler [https://github.com/pstadler].
It has two modes - single query or looped query based on config file [~/.ticker.conf]
and uses tickers as used by YF - the one in round brackets.

Fork by meekser: https://github.com/meekser
version: $ver
date: $date

	Usage:
		# For single ticker:
		./ticker.sh <ticker> 

		# For multi tickers:
		./ticker.sh <ticker> <ticker> ...

		# For looped query
		./ticker.sh --loop <interval_in_seconds>

	Config file:
		Put all tickers ect. each in new line in ~/ticker.conf:
		aapl		
		^dji
		btc-usd
		eur=x

	Examples:
		# to check google:
		./ticker.sh goog

		# to check DJ-30 and and Bitcoin in EUR and CHF/JPY every 30 sec put ^dji btc-eir chfjpy=x (each in new line) in ~/.ticker.conf and run:
	       ./ticker.sh --loop 30	
	"
}

### jq check
if ! $(type jq >/dev/null 2>&1); then
  echo "'jq' is not in the PATH. (See: https://stedolan.github.io/jq/)"
  exit 1
fi

### mode 
if [ "$1" == "--loop" ]; then
  if [ ! -f $CONFIG ]
  then 
    echo "You do not have config file: $CONFIG! Exiting ..."
    exit 1
  else
    if [ -z "$potentialLoopInterval" ]
    then
      echo "You are missing loop interval! Exiting! ..."
      exit 1
    else
      loop
    fi
  fi
fi

if [ "$1" == "--help" ]
then
  help
  exit 0


fi

singlerun


