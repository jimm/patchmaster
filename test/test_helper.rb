# frozen_string_literal: true

require 'test/unit'
require 'patchmaster'
require 'support/mock_ports'
require 'support/test_connection'

# For all tests, make sure mock I/O MIDI ports are used.
PM::PatchMaster.instance.use_midi = false
