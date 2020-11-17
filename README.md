# ticker.sh

> Real-time stock tickers from the command-line.

`ticker.sh` is a simple shell script using the Yahoo Finance API as a data source (delayed). It features:
- colored output 
- is able to display pre- and post-market prices
- has loop mode

![ticker.sh](https://raw.githubusercontent.com/meekser/ticker.sh/master/screenshot.png)


## Install

```sh
$ curl -o ticker.sh https://raw.githubusercontent.com/meekser/ticker.sh/ver2/ticker.sh
```

Make sure to install [jq](https://stedolan.github.io/jq/), a versatile command-line JSON processor.

## Usage

```sh
# Single symbol:
$ ./ticker.sh aapl

# Multiple symbols (as per finance.yahoo.com):
```
![ticker.sh](https://raw.githubusercontent.com/meekser/ticker.sh/master/ticker.png)
```sh
$ ./ticker.sh aapl ^dji btc-eur cadjpy=x

# Loop mode uses ~/.ticker.conf config file and interval in seconds
$ ./ticker.sh --loop 5

# Use different colors:
$ COLOR_BOLD="\e[38;5;248m" \
  COLOR_GREEN="\e[38;5;154m" \
  COLOR_RED="\e[38;5;202m" \
  ./ticker.sh AAPL

# Disable colors:
$ NO_COLOR=1 ./ticker.sh AAPL

```

This script works well with [GeekTool](https://www.tynsoe.org/v2/geektool/) and similar software:

```sh
PATH=/usr/local/bin:$PATH # make sure to include the path where jq is located
~/GitHub/ticker.sh/ticker.sh AAPL MSFT GOOG BTC-USD
```
