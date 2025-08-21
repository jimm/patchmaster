# frozen_string_literal: true

require 'patchmaster/consts'

class Integer
  def high_nibble
    self & 0xf0
  end

  def channel
    self & 0x0f
  end

  def channel?
    self >= PM::NOTE_OFF && self < PM::SYSEX
  end
  alias chan? channel?

  def note_on?
    (self & 0xf0) == PM::NOTE_ON
  end
  alias on? note_on?

  def note_off?
    (self & 0xf0) == PM::NOTE_OFF
  end
  alias off? note_off?

  def poly_pressure?
    (self & 0xf0) == PM::POLY_PRESSURE
  end
  alias poly_press? poly_pressure?

  # Returns true if self is a status byte for a message that targets a note
  # (note on, note off, or poly pressure).
  def note?
    self >= PM::NOTE_OFF && self < PM::CONTROLLER
  end

  def controller?
    (self & 0xf0) == PM::CONTROLLER
  end
  alias ctrl? controller?

  def program_change?
    (self & 0xf0) == PM::PROGRAM_CHANGE
  end
  alias pc? program_change?

  def pitch_bend?
    (self & 0xf0) == PM::PITCH_BEND
  end
  alias pb? pitch_bend?

  def system?
    self >= PM::SYSEX && self <= PM::EOX
  end
  alias sys? system?

  def realtime?
    self >= 0xf8 && self <= 0xff
  end
  alias rt? realtime?
end

# All the methods here delegate to the first byte in the array, so for
# example the following two are equivalent:
#
#   my_array.note_on?
#   my_array[0].note_on?
class Array
  def high_nibble
    self[0].high_nibble
  end

  def channel
    self[0].channel
  end

  def channel?
    self[0].channel?
  end
  alias chan? channel?

  def note_on?
    self[0].note_on?
  end
  alias on? note_on?

  def note_off?
    self[0].note_off?
  end
  alias off? note_off?

  def poly_pressure?
    self[0].poly_pressure?
  end
  alias poly_press? poly_pressure?

  # Returns true if self is a message that targets a note (note on, note
  # off, or poly pressure).
  def note?
    self[0].note?
  end

  def controller?
    self[0].controller?
  end
  alias ctrl? controller?

  def program_change?
    self[0].program_change?
  end
  alias pc? program_change?

  def pitch_bend?
    self[0].pitch_bend?
  end
  alias pb? pitch_bend?

  def system?
    self[0].system?
  end
  alias sys? system?

  def realtime?
    self[0].realtime?
  end
  alias rt? realtime?
end
