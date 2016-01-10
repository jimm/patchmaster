---
layout: page
title: File Format
---

> Source code in files. How quaint.
> 
> -- Attributed to Kent Beck

PatchMaster files describe your MIDI setup and define named messages,
triggers, songs with their patches, and song lists. They are written in Ruby
using a few special keywords (Ruby method names).

When your PatchMaster file is loaded, it has available all the constants and
classes defined in the PM module. That means you can refer to things like
the constants defined in `patchmaster/consts.rb` without having to prefix
them with "PM::".

For a sample PatchMaster file, see
[examples/example.rb](https://github.com/jimm/patchmaster/blob/master/examples/example.rb).

For a more detailed discussion of the things that can be in a PatchMaster
file (how they work and what they're for), see
[Components](/components.html) and [Running Patches](/patches.html).

# Loading and Saving PatchMaster Files

When you start PatchMaster you can specify a file to load on the command
line. While it's running, you can (re)load a file with the 'l' key.

You can save what's been loaded with the 's' key. To be honest, the
PatchMaster save feature isn't all that useful since you can't change
anything from within PatchMaster anyway --- yet.

# Editing PatchMaster Files

> Most editors are failed writers - but so are most writers.\\
> \\
> -- T. S. Eliot

You can create and edit PatchMaster files using any text editor you like.

## Editing From Within Patchmaster

While running PatchMaster, the 'e' key lets you edit the file you loaded or
most recently saved. If you have not yet loaded a file or you save the file
to a different location, PatchMaster will ask you for a file name.

The edit command suspends PatchMaster and starts the editor defined by the
environment variables `VISUAL` or `EDITOR`. If neither of those are defined
it tries 'vim', 'vi', and finally 'notepad.exe'.

After editing a file, PatchMaster attempts to reload that file and continue
with the same song list, song, and patch that was current when you edited
the file.

When you edit a file from within PatchMaster, it has no way of knowing if
you saved that file to a different location. If you do so and want to load
that file you'll have to use the 'l' command to do so.

## Trigger and Filter Blocks

Triggers and filters have blocks of code that they run. Saving them out to a
PatchMaster file requires those blocks be saved. However, there is no
practical way to obtain the text of a code block across all versions of Ruby
at runtime. To get around this, when loading the file PatchMaster re-reads
the file, looking for the trigger and filter definitions and saving their
blocks as text. When the trigger or filter is saved, the block text that was
read is written back out.

This simplistic solution can lead to three potential problems.

1. The algorithm used to find the code block text is dumb. It assumes that
   the end of the block is indented to the same level as the begnning, and
   that all intervening lines are indented more than the beginning and end
   lines. (One-line blocks on the same as the `trigger` or `filter` keyword
   are fine.)

2. If your PatchMaster file creates triggers or filters in a loop (more
   precisely, if there isn't a one-to-one in-order correspondence between
   trigger and filter instances and their apperance in the file) then the
   block's text can't be read properly and it won't be saved or displayed
   properly. The trigger or filter will run just fine --- it's just that the
   text representing the block on save will be wrong.

3. If your filter or trigger does anything tricky like changing its own code
   (replacing its block with another) there is no way that PatchMaster can
   know the text of the new code. When the trigger or filter is saved, the
   old block text will be written out.

As a workaround, you'll have to avoid using PatchMaster's save feature. Make
all your edits to triggers and filters from outside of PatchMaster, using
your editor.

To be honest, the PatchMaster save feature isn't all that useful since you
can't change anything from within PatchMaster anyway --- yet. Once editing
capabilities are added to PatchMaster this might become more bothersome.

# Anatomy of a PatchMaster File

## MIDI Instruments

  input/output port, symbol, optional_name

Describes MIDI inputs and outputs.

Symbols must be unique within instrument type (input or output). For
example, you can have an input instrument with the symbol :ws and an output
instrument with the same symbol :ws, but you can't have two inputs or two
outputs with the same symbol.

Example:

{% highlight ruby %}
input  0, :mb, 'midiboard'
input  1, :ws, 'WaveStation'
output 1, :ws, 'WaveStation'
output 2, :kz, 'K2000R'
output 4, :sj                   # Name will come from UNIMidi
{% endhighlight %}

### Aliases

Sometimes you have two different instruments using the same MIDI port and
you'd like to refer to them by two different names. In that case, you can
use `alias_input` or `alias_output`.

Both commands have the same format: `alias_input :new_sym, :old_sym`. For
example, if you have a MIDI output going into a keyboard and the "thru" MIDI
port from that keyboard goes out to a drum machine, you could define them
like this:

{% highlight ruby %}
output 1, :kbd, 'My Keyboard and Drum Machine'
alias_output :drums, :kbd
{% endhighlight %}

## Named Messages

{% highlight ruby %}
message name, bytes
{% endhighlight %}

Stores a named MIDI message. These messages can be sent at any time using
message keys or triggers, and can be sent from filters.

Example:

{% highlight ruby %}
message "Tune Request", [TUNE_REQUEST]
{% endhighlight %}

The `TUNE_REQUEST` constant is defined in `patchmaster/consts.rb`.

See also [Named Messages in Filters](#named-messages-in-filters) below.

## Message Keys

{% highlight ruby %}
message_key key, name
{% endhighlight %}

Maps the named message to a key. Message keys are ignored if PatchMaster was
started without the curses GUI.

`key` may be any one-character string (for example '8' or "p") or a function
key symbol of the form `:f1`, `:f2`, etc.

### Note

Older versions of PatchMaster (before 1.2.0) reversed the order of the two
arguments to `message_key`. The reversed order is still accepted but a
deprecation warning is output.

## Code Keys

{% highlight ruby %}
code_key(key) { block of code }
# or, the same thing
code_key key do
  block of code
end
{% endhighlight %}

Maps the block of code to a key. Code keys are ignored if PatchMaster was
started without the curses GUI. When the key is pressed, the block of code
is executed.

`key` may be any one-character string (for example '8' or "p") or a function
key symbol of the form `:f1`, `:f2`, etc.

Note that if you use the `{ ... }` syntax for the block, then `key` must be
surrounded by parentheses.

## Triggers

{% highlight ruby %}
trigger input_instrument_symbol, bytes, block
{% endhighlight %}

Input MIDI messages can trigger blocks of code to run. When `bytes` are sent
from the given input instrument then `block` is executed. All of the methods
of PM::PatchMaster are made available to the trigger, so for example the
block can call methods such as `#next_patch`, `#prev_song`, or
`#send_message`.

Example:

{% highlight ruby %}
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_5, 127] { next_patch }
trigger :mb, [CONTROLLER, CC_GEN_PURPOSE_6, 127] { prev_patch }
trigger :mb, [CONTROLLER, 126, 127] { send_message "Tune Request" }
{% endhighlight %}

## Songs

{% highlight ruby %}
song name block
{% endhighlight %}

A song is a list of patches.

Example:

{% highlight ruby %}
song "My First Song" do
  # ...
end
{% endhighlight %}

### Patches

{% highlight ruby %}
patch name block
{% endhighlight %}

A patch contains connections and optional start and stop byte arrays.

- start_bytes
- stop_bytes
- connection

Example:

{% highlight ruby %}
song "My First Song" do
  patch "First Song, First Patch" do
    start_bytes [TUNE_REQUEST]
    connection :mb, :kz, 2 do  # all chans from :mb, out to ch 2 on :kz
      # ...
    end
    connection :ws, 6, :sj, 4 do  # only ch 6 from :ws_kbd, out to ch 4 on :sj
      # ...
    end
    conn :ws, 6, :d4, 10
  end
end
{% endhighlight %}

#### Connections

{% highlight ruby %}
connection in_sym, in_chan, out_sym, out_chan, block
connection in_sym, nil, out_sym, out_chan, block
connection in_sym, out_sym, out_chan, block
{% endhighlight %}

Connects an input instrument to an output instrument. If `in_chan` is `nil`
or is skipped then any message coming from that instrument will be
processed, else only messages coming from the specified channel will be
processed.

A connection can optionally take a block that specifies a program change or
bank MSB/LSB plus program change (sent to the output instrument on
`out_chan`), a zone, a transposition, and a filter (see below).

- prog_chg
- zone
- transpose
- filter

All those values are optional; you don't have to specify them.

Example:

{% highlight ruby %}
song "My First Song" do
  patch "First Song, First Patch" do
    connection :ws, 6, :sj, 4 do  # only chan 6 from :ws, out to ch 4 on :sj
      prog_chg 100    # no bank, prog chg 100
      zone C4, B5
      transpose -12
      filter { |connection, bytes|
        # ...
      }
    end
  end
end
{% endhighlight %}

##### Program Changes

{% highlight ruby %}
prog_chg prog_number
prog_chg bank_lsb, prog_number
prog_chg bank_msb, bank_lsb, prog_number
{% endhighlight %}

Sends `prog_number` to the output instrument's channel. If `bank_lsb` or
`bank_msb, bank_lsb` are specified, sends bank change commands first, then
the program change.

Only one program change per connection is allowed. If there is more than one
in a connection the last one is used.

Examples:

{% highlight ruby %}
prog_chg 42         # program change only
prog_chg 2, 100     # bank LSB change then program change
prog_chg 1, 2, 100  # bank LSB change then program change
{% endhighlight %}

##### Zones

{% highlight ruby %}
zone low, high
zone (low..high)   # or (low...high) to exclude high
{% endhighlight %}

By default a connection accepts and processes notes (and poly pressure
messages) for all MIDI note numbers 0-127. You can use the zone command to
limit which notes are passed through. Notes outside the defined range are
ignored.

The `zone` command can take either two notes or a range. Notes can be
numbers, or you can use the constants defined in consts.rb such as `C2`,
`Ab3`, or `Df7` ("s" for sharp, "f" or "b" for "flat").

If you specify a single number, it's the bottom of the zone and the zone
extends all the way up to note 127. If you specify no numbers, that's the
same as not specifying a zone at all; all notes will get through.

Only one zone per connection is allowed. If there is more than one in a
connection the last one is used.

Example:

{% highlight ruby %}
zone C2         # filters out all notes below C2
zone C2, B4     # only allows notes from C2 to B4
zone (C2..B4)   # same as previous
zone (C2...C5)  # same as previous ("..." excludes top)
{% endhighlight %}

##### Transpose

{% highlight ruby %}
transpose num
{% endhighlight %}

Specifies a note transposition that will be applied to all incoming note on,
note off, and polyphonic pressure messages.

Note that transposition occurs after a connection's zone has filtered out
incoming data, not before.

##### Filters

{% highlight ruby %}
filter block_with_two_args
{% endhighlight %}

Filters are applied as the last step in a connection's modification of the
MIDI data. This means that the status byte's channel is already changed to
the output instrument's channel for this connection (assuming the message is
a channel message).

The filter's block must return the array of bytes you want sent to the
output. Don't use the "return" keyword; simply make sure the byte array is
the last thing in the block.

Only one filter per connection is allowed. If there is more than one in a
connection the last one is used.

Example:

{% highlight ruby %}
song "My First Song" do
  patch "First Song, First Patch" do
    connection :ws, 6, :sj, 4 do  # only chan 6 from :ws, out to ch 4 on :sj
      prog_chg 100
      zone C4, B5
      filter { |connection, bytes|
        if bytes.note_off?
          bytes[2] -= 1 unless bytes[2] == 0 # decrease velocity by 1
        end
        bytes
      }
    end
  end
end
{% endhighlight %}

###### Named Messages in Filters

Named messages sent from filters are sent before the filtered bytes are
sent. Make sure the filter returns the filtered bytes after sending your
message. If you send the mesasge last in your filter then no other bytes
will be sent.

{% highlight ruby %}
# WRONG
filter do |conn, bytes|
  bytes
  send_message "Interesting Bytes"
end

# RIGHT
filter do |conn, bytes|
  send_message "Interesting Bytes"
  bytes     # pass through original bytes unchanged
end
{% endhighlight %}

Note that named messages sent from filters are sent every time any MIDI
bytes are run through the filter --- practically speaking, every time a note
or controller is sent through the filter.

Instead of using `send_message` to send the message directly, you can copy
the bytes into the byte array. This way, you can send the message after the
bytes are sent, not before. Here's how:

{% highlight ruby %}
filter do |conn, bytes|
  msg_bytes = messages["My Message Name".downcase]
  bytes + msg_bytes             # return original bytes plus message bytes
end
{% endhighlight %}

## Song Lists

{% highlight ruby %}
song_list name, [song_name, song_name...]
{% endhighlight %}

Optional.

Example:

{% highlight ruby %}
song_list "Tonight's Song List", [
  "First Song",
  "Second Song"
]
{% endhighlight %}

# Aliases

Many of the keywords in PatchMaster files have short versions.

| Full Name  | Aliases   | Notes                           |
|------------+-----------+---------------------------------|
| input      | inp       | "in" is a reserved word in Ruby |
| output     | outp, out |                                 |
| connection | conn, c   |                                 |
| prog_chg   | pc        |                                 |
| zone       | z         |                                 |
| transpose  | xpose, x  |                                 |
| filter     | f         |                                 |
