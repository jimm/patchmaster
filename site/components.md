---
layout: page
title: Components
---

> "The time has come," the Walrus said,\\
> "To talk of many things:\\
> Of shoes - and ships - and sealing wax -\\
> Of cabbages - and kings -\\
> And why the sea is boiling hot -\\
> And whether pigs have wings."\\
> \\
> -- Lewis Carroll, _Through the Looking-Glass_

This section describes the things that make up a PatchMaster document:
instruments, songs, patches, connections, triggers, messages, and filters.
The [file format](/file-format.html) page tells you how to put them all
together into a PatchMaster file.

# Instruments

An intstrument represents either a MIDI input to a synth, drum machine, or
other device or a MIDI output from a controller. Each instrument needs a
symbol (a usually short name starting with ":"), specifies which UNIMidi
port number it uses, and has a name.

Input instrument symbols must be unique, as must output instruments. The
same symbol can be used for an input and an output, however. You'd usually
do that if you have an instrument such as a keyboard that can act as both a
controller (an output instrument) and a sound module (an input instrument).

If you don't give an instrument a name, PatchMaster will display the name
that UNIMidi uses. This isn't always what you want, because if you're using
a MIDI interface such as the Unitor amt8, UNIMidi will use the names of the
ports themselves, not the instruments plugged in to them (for example,
"Unitor Port 0", "Unitor Port 1", ...).

## Example

Let's say you have a keyboard controller that doesn't generate any sound on
port 0 of your MIDI interface, a typical keyboard synth (both controller and
sound generator) on port 1, and a rack-mount sound generator on port 2.
Here's what that might look like in your PatchMaster file:

{% highlight ruby %}
input  0, :con, 'My Controller'
input  1, :kbd, 'The Keyboard'
output 1, :kbd, 'The Keyboard'
output 2, :rack                 # Will use UNIMidi name
{% endhighlight %}

# Songs

A song is a named list of patches that allow you to control your MIDI setup.
A song can have any number of patches. You can step forward and backward
through the patches in a song using the GUI movement keys or
[triggers](/triggers.html).

When a song becomes the current song, its first patch is made the current
patch.

# Patches

A patch is a named collection of connections that can modify the MIDI data.
The simplest connection connects one MIDI input device directly to another
on a single channel.

## Start and Stop Bytes

A patch also has optional _start bytes_ and _stop bytes_. These are arrays
of MIDI bytes that can contain any MIDI data such as patch changes, volume
controller settings, note on or off messages (for those looong drones), and
System Exclusive messages.

# Connections

A connection connects an input instrument (all incoming channels or just
one) to a single output channel of an output instrument. All messages coming
from the input instruments are changed to be on the output instrument
channel.

When talking about the "notes" that a connection modifies, this means all
MIDI messages that have note values: note on, note off, and polyphonic
pressure.

## Program Changes

A connection can optionally send bank chang MSB/LSB and program change to
its output instrument's channel. If bank MSB/LSB values are specified, first
they are sent then the program change.

## Zones

A connection can optionally specify a zone: a range of keys outside of which
all MIDI data will be ignored. Since a patch can contain multiple
connections, this lets you split and layer your controllers, sending some
notes to some synths but not others.

## Transposes

A connection can transpose all notes by a fixed value. If a transposition
would cause a note number to be out of range (lower than 0 or higher than
127), then the value is wrapped around --- a note transposed up to 128
becomes 0, for example.

## Filters

Filters let you do anything you want to the data, including filter out
notes, transpose, modify controller values --- anything. That's because a
filter has a block of Ruby code that gets executed for every message that
goes through the connection.

Filters are applied as the last step in a connection's modification of the
MIDI data. This means that the status byte's channel is already changed to
the output instrument's channel for this connection (assuming the message is
a channel message).

The filter's block must return the array of bytes you want sent to the
output. Don't use the "return" keyword; simply add the bytes as the last
thing in the block.

# Song Lists

A song list is a list of songs. A song can appear in more than one song
list. One special song list called "All Songs" contains the list of all
songs.

# Named Messages

A named message is an array of MIDI bytes with a name. Named messages can be
sent using message keys, via triggers, or even from filters.

Named messages are sent to all output instruments. The MIDI bytes are sent
from PatchMaster with channels unchanged. If a named message contains
channel messages then the receiver will of course ignore all except those on
the channels it's configured to receive.

Note: the word "message" as used in the previous sections on this page refer
to the MIDI bytes coming from your instruments or being sent to the output
instruments. The phrase "named message" refers to one of these things we're
talking about here.

## Message Keys

You can assign named messages to keys when using the PatchMaster GUI.
Whenever the assigned key is pressed, the corresponding message is sent. See
the [file format](/file-format.html) page for how to assign a named message
to a key.

# Code Keys

You can assign a blocks of code to be executed when keys are pressed when
using the PatchMaster GUI. Whenver the assigned key is pressed, the
corresponding block of code is run. See the [file format](/file-format.html)
page for how to assign a code block to a key.

# Triggers

A trigger looks for a particular incoming MIDI message from a paticular
input instrument and runs a block of code when it is seen. The blocks can
contain any Ruby code. Typically triggers are used for navigation or sending
named messages.

All triggers are executed by the `PM::PatchMaster` instance. Practially
speaking this means you can call any of the methods of that object or its
`PM::Cursor` object, including but not limited to

- `next_song`, `prev_song`, `next_patch`, `prev_patch`
- `goto_song`
- `send_message`
- `panic`
