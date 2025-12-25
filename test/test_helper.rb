# frozen_string_literal: true

require 'test/unit'
require_relative '../lib/patchmaster'
require_relative 'support/mock_ports'
require_relative 'support/test_connection'

# For all tests, make sure mock I/O MIDI ports are used.
PM::PatchMaster.instance.use_midi = false
