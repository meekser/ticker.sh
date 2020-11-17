#!/usr/bin/env bash

set -e

LANG=C
LC_NUMERIC=C

SYMBOLS=("$@")

CONFIG=~/.config/ticker.conf

if ! $(type jq >/dev/null 2>&1); then
  echo "'jq' is not in the PATH. (See: https://stedolan.github.io/jq/)"
  exit 1
fi

if [ "$1" == "--make-config" ]; then
  if [ ! -f $CONFIG ]; then
    if [ ! -d "$(dirname $CONFIG)" ]; then
      mkdir -p "$(dirname $CONFIG)"
    fi
    echo "making default config ($CONFIG)"
    printf "NVDA\nTSM\nAMD\nINTC\nMSFT\nGOOG\nGOOGL\nAMZN\nTSLA\nIBM\nAAPL\nBTC-USD\nETH-USD\nXRP-USD\nXLM-USD\nEOS-USD" >$CONFIG
    exit 1
  else
    echo "Error: config already exists ($CONFIG)"
    exit 1
  fi
fi

if [ -z "$SYMBOLS" ] && [ ! -f $CONFIG ]; then
  echo "Usage: ./ticker.sh AAPL MSFT GOOG BTC-USD"
  exit
fi

if [ -z "$SYMBOLS" ] && [ -f $CONFIG ]; then
  SYMBOLS=($(cat $CONFIG))
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

results=$(curl --silent "$API_ENDPOINT&fields=$fields&symbols=$symbols" |
  jq '.quoteResponse .result')

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
