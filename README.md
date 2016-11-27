# UpsideDownLEDs

## The backstory

It started, as one may suppose things do these days, with a seemingly innocent exchange on [Slack](http://www.slack.com/).

![alt text](https://www.evernote.com/l/AHdc-C2QJkNJMLoutZ0Unp-G9JcQ-C_7qeoB/image.png)

...which led to...

![alt text](https://www.evernote.com/l/AHc_Wx0UxlhIQrnMFoxvrv-Kt7WWdmu_EXYB/image.png)

### Wait, what?

If you're not already familiar with [Stranger Things](http://www.imdb.com/title/tt4574334/), the part that's relevant to our tale here is this. A boy goes missing, and his mother is convinced that whatever otherworldly place he's gone to, he can communicate with her by controlling electric lights. So she strings up Christmas tree lights on a wall and paints a letter of the alphabet under each one, with the hope that her son will use them to spell out messages to her.

That's all you get from me. Seriously, if you want to know more, go watch it.

### So, what you're saying is...

![alt text](https://www.evernote.com/l/AHcvX99-cCBOUYOe5N60Sp-Cjyd1YSHJOAcB/image.png)

Sort of. The reality is going to turn out to be much more interesting.

## The hardware

I already had everything I needed on hand.

* Raspberry Pi Model B+, v1.2
* A breakout board for the Pi's GPIO connector (similar to the [Sparkfun Pi Wedge](https://www.sparkfun.com/products/retired/13091), but not as nice)
* A breadboard
* 26 LEDs of assorted colors
* 26 220&ohm; resistors
* A bunch of jumper wires

Twenty-six letters in the English alphabet means twenty-six LEDs. Conveniently, the Raspberry Pi Model B+ has twenty-six GPIO pins. That should make for a relatively simple and straightforward circuit design.

(Multiplexing the GPIO pins to require fewer of them is left as an exercise for the reader, or possibly for version 2.)

![picture of the breadboard](https://www.evernote.com/l/AHdGaO3zeEZKKqKnT3avZ5fb45XkTmazFw0/image.png)

The assignment of pins to LEDs was driven by the lengths of the jumper wires I had available and the layout of GPIO pins on the breakout board. If I ever get around to making a PCB for this, I'll make it less haphazard.

## The software

I started with a fresh install of [Raspbian](https://www.raspberrypi.org/downloads/raspbian/) (Jessie with Pixel, September 2016).

### Step 1: The smoke test

Raspbian comes with a Python library for controlling the GPIO pins already installed, so that's as good a place to start as any.

```python
import RPi.GPIO as GPIO
import string
import time

pindefs = {
    'A':  4, 'B':  2, 'C': 27, 'D': 22, 'E': 26, 'F': 19, 'G': 13, 'H':  6, 'I':  5, 'J': 11, 'K':  9, 'L': 10, 'M':  3,
    'N': 14, 'O': 15, 'P':  8, 'Q': 18, 'R': 23, 'S': 21, 'T': 17, 'U': 24, 'V': 25, 'W':  7, 'X': 12, 'Y': 16, 'Z': 20,
}

def blink(pin, delay_during=0.5, delay_after=0.5):
    GPIO.output(pin, GPIO.HIGH)
    time.sleep(delay_during)
    GPIO.output(pin, GPIO.LOW)
    time.sleep(delay_after)

GPIO.setmode(GPIO.BCM)

for pin in pindefs.values():
    GPIO.setup(pin, GPIO.OUT)

for letter in list(string.ascii_uppercase):
    blink(pindefs[letter], 0.3, 0)

time.sleep(2)

blink(pindefs["H"])
blink(pindefs["E"])
blink(pindefs["L"])
blink(pindefs["L"])
blink(pindefs["O"])

GPIO.cleanup()
```

When I run this on the Raspberry Pi (via `python smoke_test.py`), each of the LEDs lights up in sequence, then it blinks out the word `HELLO`.

### Step 2: Elixir

Python's all well and good, but can I do the same thing using Elixir?

Unlike Python, Raspbian doesn't come with Elixir installed. The available APT packages for Erlang and Elixir are out of date, so I'm going to build from source.

```bash
# make sure the apt cache is up to date
$ sudo apt-get update

# install dependencies
$ sudo apt-get install unzip m4 libcurses5-dev libssl-dev

# download, compile, and install Erlang
$ curl -LO http://erlang.org/download/otp_src_19.1.tar.gz
$ tar xvfz otp_src_19.1.tar.gz
$ cd otp_src_19.1/
$ export ERL_TOP=`pwd`
$ ./configure --without-odbc --without-wx
$ make
$ make release_tests
$ cd release/tests/test_server
$ $ERL_TOP/bin/erl -s ts install -s ts smoke_test batch -s init stop
$ sudo make install

# download a precompiled elixir release
$ curl -LO https://github.com/elixir-lang/elixir/releases/download/v1.3.4/Precompiled.zip
$ unzip Precompiled.zip -d elixir
$ sudo mv elixir /usr/local
# add this to .bash_profile so it's always available
$ export PATH=/usr/local/elixir/bin:$PATH

$ iex
Erlang/OTP 19 [erts-8.1] [source] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (1.3.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> 2 + 3
5
iex(2)>
```

To access the GPIO pins, I'll employ [elixir_ale](https://github.com/fhunleth/elixir_ale). After installing it as a dependency in `mix.exs` and running `mix deps.get`, it's straightforward to use.

```elixir
iex(1)> {:ok, pid} = Gpio.start_link(4, :output)
{:ok, #PID<0.235.0>}
iex(2)> Gpio.write(pid, 1)
:ok
iex(3)> Gpio.write(pid, 0)
:ok
iex(4)>
```

You can't see it from where you're sitting (unless you're playing along at home with your own Raspberry Pi), but the "A" LED just turned on and off again.

```elixir
defmodule SmokeTest do
  defp blink(pid, delay_during \\ 500, delay_after \\ 500) do
    Gpio.write(pid, 1)
    :timer.sleep(delay_during)
    Gpio.write(pid, 0)
    :timer.sleep(delay_after)
  end

  def go do
    pin_defs = %{
      "A" => 4,
      "B" => 2,
      "C" => 27,
      "D" => 22,
      "E" => 26,
      "F" => 19,
      "G" => 13,
      "H" => 6,
      "I" => 5,
      "J" => 11,
      "K" => 9,
      "L" => 10,
      "M" => 3,
      "N" => 14,
      "O" => 15,
      "P" => 8,
      "Q" => 18,
      "R" => 23,
      "S" => 21,
      "T" => 17,
      "U" => 24,
      "V" => 25,
      "W" => 7,
      "X" => 12,
      "Y" => 16,
      "Z" => 20,
    }

    pin_map = pin_defs |> Enum.map(fn pair -> {letter, pin_no} = pair; {:ok, pid} = Gpio.start_link(pin_no, :output); {letter, pid} end) |> Enum.into(%{})

    ?A..?Z |> Enum.each(fn letter -> pid = pin_map[to_string([letter])]; blink(pid, 300, 0); end)

    :timer.sleep(2000)

    "HELLO" |> String.to_charlist |> Enum.each(fn letter -> pid = pin_map[to_string([letter])]; blink(pid); end)
  end
end

SmokeTest.go
```

Running this (via `mix run smoke_test.exs`) produces the same output as the Python script above.

### Step 3: Adding a GenServer

I'm going to want this code to eventually be persistent and long-lived, so it seems like a good idea at this point to make it into a server. I borrowed heavily from [the GenServer example on the Elixir web site](http://elixir-lang.org/getting-started/mix-otp/genserver.html); the result is in `lib/upside_down_leds/blinking_lights.ex`.

```elixir
iex(1)> {:ok, server} = UpsideDownLeds.BlinkingLights.start_link
{:ok, #PID<0.235.0>}
iex(2)> UpsideDownLeds.BlinkingLights.puts(server, "HELLO")
:ok
iex(3)> UpsideDownLeds.BlinkingLights.puts(server, "ELEVEN LOVES EGGOS")
:ok
iex(4)>
```

There's blinking lights. Trust me&mdash;they're the best blinking lights. They're yuuge.

### Step 4: The ghost in the machine

In the show, the blinking lights are used to receive messages from an unseen messenger in an otherworldly, forbidding place. I, too, wanted to receive messages from unseen messengers in an otherworldly, forbidding place.

In other words, Twitter.

I reserved the Twitter handle [@UpsideDownLEDs](https://twitter.com/UpsideDownLEDs) so that messages sent to it will be displayed on the blinking lights. To be able to receive them on the Raspberry Pi, I'm going to use the [ExTwitter](https://github.com/parroty/extwitter) library.

```elixir
def application do
  [applications: [:logger, :extwitter]]
end

defp deps do
  [
    {:elixir_ale, "~> 0.5.6"},
    {:extwitter, "~> 0.7.0"},
    {:oauth, git: "https://github.com/tim/erlang-oauth.git"}
  ]
end
```

Note that ExTwitter depends on the Erlang `oauth` library, but doesn't include it as a dependency itself, so it needs to be included explicitly.

Access to the Twitter API via OAuth requires four tokens (two of them secret) that can be generated by going to https://apps.twitter.com and creating a new app. Then add them to `config/config.exs`.

```elixir
config :extwitter, :oauth, [
   consumer_key: "U7LD5Jtnq5kwQggwWICgZKA6K",
   consumer_secret: "",
   access_token: "789505576778674176-hcvnZ1inik53KVUKfG8zQ2NcMsgYbIi",
   access_token_secret: ""
]
```

(I'm not including the secret values here or in the file in Github, and you shouldn't either.)

There are two flavors of API that can be used. I'll use the search API as a one-off to test access to the Twitter API, and the streaming API to actually listen for messages to display.

#### Search API

```elixir
Interactive Elixir (1.3.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> ExTwitter.search("upside down", [count: 3]) |>
...(1)> Enum.map(fn tweet -> tweet.text end) |>
...(1)> Enum.join("\n-----\n") |>
...(1)> IO.puts
```

will print out the most recent three tweets containing `upside down`.

#### Streaming API

```elixir
Interactive Elixir (1.3.4) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> stream = ExTwitter.stream_filter(track: "@UpsideDownLEDs") |>
...(1)> Stream.map(fn tweet -> tweet.text end) |>
...(1)> Stream.map(fn text -> IO.puts "#{text}\n-----\n" end)
#Stream<[enum: #Function<49.87278901/2 in Stream.resource/3>,
 funs: [#Function<46.87278901/1 in Stream.map/2>,
  #Function<46.87278901/1 in Stream.map/2>]]>
iex(2)> Enum.to_list(stream)
```

will print out all references to the `@UpsideDownLEDs` Twitter handle as they appear in the Twitter firehose stream.

### Step 5: Putting together the pieces

So far, I have code that takes a string and displays it on the blinking LEDs, and code that receives messages from Twitter. It's time to tie those two together.
