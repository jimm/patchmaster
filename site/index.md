---
layout: page
title: PatchMaster
permalink: /
---

# PatchMaster

> Welcome. Welcome. Welcome.\\
> 
> -- The entire Ig Nobel awards ceremony welcoming speech

PatchMaster is a MIDI processing and patching system. It allows a musician
to reconfigure a MIDI setup instantaneously and modify the MIDI data in real
time.

With PatchMaster a performer can split controlling keyboards, layer MIDI
channels, transpose them, send program changes and System Exclusive
messages, limit controller and velocity values, and much more. At the stomp
of a foot switch (or any other MIDI event), an entire MIDI system can be
totally reconfigured.

PatchMaster lets you describe /songs/, which are lists of /patches/ that
connect /instruments/. Those /connections/ can send program changes, set
keyboard splits, transpose, send volume or other controller changes, and let
you apply any Ruby code you want to the MIDI stream in real time.

/Song lists/ let you organize songs into set lists for live performance or
in the studio.

Any incoming MIDI message can /trigger/ an action such as moving to the next
or previous patch or song. For example, you can tell PatchMaster to move
forward or backward based on controller values coming from foot switches or
an instrument's buttons.

Any array of MIDI bytes can be stored as a named /message/ which can be sent
via a trigger, a key press, or from any filter.

A software panic button turns off any stuck notes.

PatchMaster is cross-platform: it should run on Mac OS X, Linux, JRuby, and
Windows. It requires Ruby 1.9 or above, and has been tested with Ruby 2.0.

PatchMaster is by [Jim Menard](mailto:jim@jimmenard.com). It is a rewrite of
[KeyMaster](http://jimmenard.com/projects/keymaster/). The Github repo is
[here](https://github.com/jimm/patchmaster).

# Requirements

- The [midi-eye](https://github.com/arirusso/midi-eye) gem, which will be
  installed automatically if you install PatchMaster as a gem. midi-eye in
  turn requires (and will install automatically):
  - [midi-message](https://github.com/arirusso/midi-message)
  - [nibbler](https://github.com/arirusso/nibbler)
  - [unimidi](https://github.com/arirusso/unimidi)
- The [sinatra](http://www.sinatrarb.com/) gem, if you want to use
  PatchMaster's browser GUI
- Ruby 1.9 (because UniMIDI requires it) or higher (including Ruby 2.0)
- Curses (comes with Ruby, but I'm not sure about JRuby)

# Installation

To install as a gem, type

{% highlight bash %}
gem install patchmaster
{% endhighlight %}

# Running PatchMaster

{% highlight bash %}
patchmaster [-v] [-n] [-i] [-w] [-p port] [-d] [patchmaster_file]
{% endhighlight %}

Starts PatchMaster and optionally loads `patchmaster_file`.

`-v` outputs the version number and exits.

The `-n` flag tells PatchMaster to not use MIDI. All MIDI errors such as not
being able to connect to the MIDI instruments specified in pm_file are
ignored, and no MIDI data is sent/received. That is useful if you want to
run PatchMaster without actually talking to any MIDI instruments.

To run PatchMaster from within an IRB session use `-i`. Reads
./.patchmasterrc if it exists, $HOME/.patchmasterrc if not. See the
documentation for details on the commands that are available.

To run PatchMaster using a Web browser GUI use `-w` and point your browser at
<http://localhost:4567>. To change the port, use `-p`.

The `-d` flag turns on debug mode. The app becomes slightly more verbose and
logs everything to /tmp/pm_debug.txt.

# More Information

- Descriptions of all the [components](/components): songs, patches, connections, filters,
  and more
- All about [patches and connections](/patches) --- what happens when they run
- The [PatchMaster file format](/file-format)
- [IRB mode](/irb)
- [Tips and tricks](/tips-and-tricks)
- [Screen Shots](/screenshots)
- [Changes](/changes) between PatchMaster versions
- [To Do](/todo) list, including bugs and new features
