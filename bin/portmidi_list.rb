#!/usr/bin/env ruby
#
# This script is called from ./patchmaster. It may also be run on its own.

require 'portmidi'

devices = Portmidi.devices
inputs, outputs = devices.partition { |d| d.type == :input }

puts "Inputs"
Portmidi.input_devices.each do |dev|
  puts "#{'%3d' % dev.device_id}: #{dev.name}"
end

puts "Outputs"
Portmidi.output_devices.each do |dev|
  puts "#{'%3d' % dev.device_id}: #{dev.name}"
end
