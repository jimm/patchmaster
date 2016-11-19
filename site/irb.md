---
layout: page
title: IRB
---

> She sells sea shells by the sea shore.

*Warning*: this feature of PatchMaster is brand new. The commands or their
syntax may change as I play with IRB mode. So, please give me your
[feedback](mailto:jim@jimmenard.com).

PatchMaster's IRB mode lets you interactively define connections, send patch
changes, and transpose and otherwise filter your MIDI setup. It's intended
more for experimentation and jamming, where you don't know ahead of time
exactly how you want your setup configured.

Because of this, there are no songs or patches and no jumping from one to
the other. Another way to think about it is that you're in one live patch
that is constantly being redefined as you add connections.

## Starting IRB Mode

Use the `-i` flag to start PatchMaster within an IRB console.

On startup IRB mode looks for the file .patchmasterrc in the current
directory and loads that file. If it does not exist, IRB mode looks for the
file `$HOME/.patchmasterrc`.

# Commands

Type `pm_help` to get a list of all the PatchMaster commands available.
There are a few new commands, and a few that behave slightly differently
then when they're in a PatchMaster file.

## Familiar Commands

All of the commands that are avilable in PatchMaster files are available to
you here, but a few work slightly differently, and a few more just don't
make sense.

### Changed

Though you can give a block to a `connection` command just like you do in a
PatchMaster file, the commands that are normally in such blocks (`prog_chg`,
`zone`, `transpose`, and `filter`) also work outside of the block and affect
the most recently defined connection. So for example, these two are
equivalent:

{% highlight ruby %}
# From a PatchMaster file
connection :mb, :kz, 1 do
  transpose 12
  zone C4, B5
end

# IRB mode equivalent
connection :mb, :kz, 1
transpose 12
zone C4, B5
{% endhighlight %}

### Don't make any sense

- `song`
- `patch`
- `song_list`
- `start_messages`
- `stop_messages`

## New Commands

### `clear`

`clear` deletes all connections.

### `panic` and `panic!`

`panic` sends an all-notes-off message. `panic!` does the same thing and
then sends individual note-off messages for all notes on all channels.

# Tips & Tricks

## Initial Setup

Store your setup (input, output, alias_output, etc.) in `~/.patchmasterrc`.

## Loading Files

To load a file from within IRB:

{% highlight bash %}
$ bin/patchmaster -i
PatchMaster loaded
Type "pm_help" for help
PatchMaster:001:0> require "myfile"
{% endhighlight %}

If `myfile.rb` isn't on your Ruby load path you'll see an error like
"LoadError: cannot load such file -- myfile". In that case, there are three
different solutions:

### Command line

Start PatchMaster using the `ruby` command and add the proper directory
using the `-I` command line argument:

{% highlight bash %}
$ ruby -I path/to/dir-containing-myfile bin/patchmaster -i
$ bin/patchmaster -i
PatchMaster loaded
Type "pm_help" for help
PatchMaster:002:0> require "myfile"
{% endhighlight %}

### Specify Full Path to File

{% highlight bash %}
$ bin/patchmaster -i
PatchMaster loaded
Type "pm_help" for help
PatchMaster:002:0> require "path/to/dir-containing-myfile/myfile"
{% endhighlight %}

### Modify Load Path

{% highlight bash %}
$ bin/patchmaster -i
PatchMaster loaded
Type "pm_help" for help
PatchMaster:001:0> $LOAD_PATH << "path/to/dir-containing-myfile"
PatchMaster:002:0> require "myfile"
{% endhighlight %}

## Common Configurations

Have a few favorite connection configurations? Shove them into a file,
either one configuration in each file or all in one file in different
methods. For example, say you've created the file `myfile.rb` that contains
the following:

{% highlight ruby %}
input 0, :kbd, 'Cool Controller'
input 1, :kbd2, 'Kool Kontroller'
output 0, :module1, 'Moddy the Module'
output 1, :module2, 'YAMM'

def vanilla
  clear
  connection :kbd, :module1, 1
  connection :kbd, :module2, 2
end

def chocolate
  clear
  connection :kbd,  :module1, 1
  connection :kbd2, :module1, 3
end
{% endhighlight %}

Then you can `require "myfile"` (or `require "/path/to/myfile"` if it's not
in your load path) and type `vanilla` or `chocolate` to switch between the
two setups you've defined.
