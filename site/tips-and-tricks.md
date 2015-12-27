---
layout: page
title: Tips and Tricks
---

> An invasion of armies can be resisted, but not an idea whose time has come.
>
> -- Victor Hugo

This section contains some ideas that will hopefully spur you to even more
interesting and creative uses of PatchMaster.

# Don't Panic!

Hitting ESCAPE sends all-notes-off messages to every output instrument on
all 16 MIDI channels. Hitting ESCAPE a second time sends individual note off
messages to every note on all 16 channels to every output instrument.

# What?

predicates.rb defines methods on Integer and Array that might be useful to
you when writing filters or triggers. Most of the Array methods apply
themselves to the first byte, so for example these two are equivalent:

{% highlight ruby %}
b.controller?           # true if b is controller status byte, any chan
my_array.controller?    # true if first byte is controller status byte
my_array[0].controller? # same as previous line
{% endhighlight %}

# From One, Many

You can turn one note into multiple notes either by setting up two different
connections that connect the same input to the same output, or by writing a
filter that turns one message into multiple like this:

{% highlight ruby %}
filter { |conn, bytes|
  if bytes.note?
    bytes += bytes    # duplicate note message
    bytes[-2] += 12   # raise second note up an octave
  end
  bytes
}
{% endhighlight %}

This also shows the use of the predicate method `note?` which returns true
for note on, note off, and poly pressure messages.

# This One Goes to 11

Use start bytes or messages to set initial volumes for instruments, for
example resetting all instrument's volumes to 127.

# Hands-Free

Use PatchMaster to play notes! A patch's start bytes can be used to play one
or more notes-on messages, and the stop bytes can be used to play the
corresponding note-off messages.

# And Now, a Massage from the Swedish Prime Minister

You don't have to enter message byte arrays manually. You can build up the
message using Ruby code, storing it in a variable, and then hand that
variable to the `message` method. See `examples/example.rb`.

Messages can be sent not only from the keyboard but also from a trigger or a
filter by calling

{% highlight ruby %}
send_message "Message Name"
{% endhighlight %}

To get the message's bytes, for example within a filter, use

{% highlight ruby %}
messages["My Message Name".downcase]
{% endhighlight %}

# Method to Your Madness

You can write your own methods in the PatchMaster file and call them from
triggers and filters. Your method has access to the PM::PatchMaster methods
and instance variables --- for example, @outputs is the array of all output
instruments.

{% highlight ruby %}
def output_reset
  @outputs.each { |out| out.midi_out([SYSTEM_RESET]) }
end
    
trigger :mb, [CONTROLLER, 126, 127] { output_reset }
{% endhighlight %}

# Time Lord

Use the time to modify the MIDI data. Here's an example filter that
increases or decreases volume based on the time --- essentially an LFO
that is modulating amplitude.

{% highlight ruby %}
def time_based_volume
  t = Time.now.to_f             # to_f gives sub-second accuracy
  unit_offset = Math.sin(t)     # -1 .. 1
  volume = (unit_offset * 64) + 64
  volume = 127 if volume == 128
  volume
end
  
song "s1" do
  patch "p1" do
    connection :my_in, :my_out, 2 do
      filter do |c, b|
        # Add more bytes to outgoing b array (and return b)
        # Here, + 1 means we're sending this to MIDI channel 2
        b + [CONTROLLER + 1, CC_VOLUME, time_based_volume]
      end
    end
  end
end
{% endhighlight %}

# Tuning

You might want to set up a song that helps you tune your instruments
by sending the proper program changes and entering note on and note
off commands that play the tuning note on different synths. (Yes,
you actually had to tune most older synths.) For example,

1. Patch One

   - Start message: program changes and note-ons for reference synth A and
     another synth (B).
   - Stop message: note-off for synth B.

2. Patch Two

   - Start message: program change and note-on for synth C.
   - Stop message: note-off for synth C.

3. Patch Three

   - Start message: program change and note-on for synth D.
   - Stop message: note-offs for synth D and reference synth A.

# Matching Names

When you enter the name of a song list, song, or patch on the screen, you
need not type the whole name. Just use the shortest unique prefix of the
name. Actually, you can type any regular expression. Also, you needn't worry
about matching upper and lower case; all name comparisons are
case-insensitive (the regular expression is automatically made to match
case-insensitively).
