---
layout: page
title: Changes
---

> In programming, do, or undo. There is always try.
>
> -- Yoda (via Ron Jeffries)

# 3.0.0

- Use [RtMidi](https://www.music.mcgill.ca/~gary/rtmidi/) and the
  [rtmidi](https://github.com/adamjmurray/ruby-rtmidi/) gem.

# 2.0.0

- Supports Ruby 2.4.x and the latest versions of the MIDI libs on which it
  depends such as [Unimidi](https://github.com/arirusso/unimidi]) and
  [MIDIEye](https://github.com/arirusso/midi-eye) by Ari Russo.

# 1.2.1

- Fixed `channel?` predicate method.

- Fixed `Connection.accept_from_input?`.

# 1.2.0

- New `code_key` command.

- `message_key` argument orders have been reversed, to match `code_key`. The
  old order will be accepted for a while.

- Switch to [Jekyll](http://jekyllrb.com/) version of the site.

- New `-l` (`--list`) argument to `bin/patchmaster` lists all MIDI inputs
  and outputs. This is the same as running `unimidi list` in your shell.

# 1.1.2

- Fixed triggers.

- When a trigger runs, the curses GUI is updated. Unfortunately, the web app
  still isn't updated. See the To Do list.

# 1.1.1

- Heeded a few runtime warnings.

# 1.1.0

- Removed `-t` command line switch from bin/patchmaster.

# 1.0.0

- Start of IRB interface.

# 0.0.7

- Added -p PORT option to bin/patchmaster.

- Handle display and reading of missing block text for triggers and filters
  more gracefully. (Blocks are always loaded properly but the text
  representation sometimes isn't. See the "Editing PatchMaster File" section
  of the "PatchMaster Files" help file.)

- Added a Gemfile, thanks to shaiguitar (https://github.com/shaiguitar).

- The beginnings of a browser-based GUI.

- Colors scheme selections in the browser GUI.

# 0.0.6

- Added missing note const definitions.

- Made message lookup case-insensitive.

# 0.0.5

- Program change command can now take optional bank number.

- More MIDI constants defined in consts.rb. Removed erroneous note constant
  definitions that used '#'.

- Obtained http://www.patchmaster.org and moved docs to org files in
  www/org.

# 0.0.4

- Added user-defined messages and the ability to bind them to keys.

- Fixed no-file edit bug.

- Fixed gem dependency in Rakefile.

- Added a way to run the app without windows.

- Get default instrument name from UNIMidi, instead of using symbol defined
  in input file.

- Instrument symbols must be unique within type (input or output).

- Internal changes that shouldn't matter to anybody:

  - Store instrument symbol in instrument.

  - In Rakefile, current date is used when publishing gem.

- More documentation.

# 0.0.3

- Added missing DSL stop_bytes method so PatchMaster files can now specify
  stop_bytes in a patch.

# 0.0.1

- Initial release.
