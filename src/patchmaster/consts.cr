# MIDI and PatchMaster constants.
module PM

  # Define MIDI note names C0 - B10
  (0..10).each { |oct|
    {C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11}.each { |note,val|
      base = (oct+1) * 12 + val
      eval <<EOS
#{note}#{oct} = #{base}
#{note}f#{oct} = #{base - 1}
#{note}b#{oct} = #{base - 1}
#{note}s#{oct} = #{base + 1}
EOS
    }
  }

  # Number of MIDI channels
  MIDI_CHANNELS = 16
  # Number of note per MIDI channel
  NOTES_PER_CHANNEL = 128

  #--
  # Standard MIDI File meta event defs.
  #++
  META_EVENT = 0xff
  META_SEQ_NUM = 0x00
  META_TEXT = 0x01
  META_COPYRIGHT = 0x02
  META_SEQ_NAME = 0x03
  META_INSTRUMENT = 0x04
  META_LYRIC = 0x05
  META_MARKER = 0x06
  META_CUE = 0x07
  META_MIDI_CHAN_PREFIX = 0x20
  META_TRACK_END = 0x2f
  META_SET_TEMPO = 0x51
  META_SMPTE = 0x54
  META_TIME_SIG = 0x58
  META_PATCH_SIG = 0x59
  META_SEQ_SPECIF = 0x7f

  #--
  # Channel messages
  #++
  # Note, val
  NOTE_OFF = 0x80
  # Note, val
  NOTE_ON = 0x90
  # Note, val
  POLY_PRESSURE = 0xA0
  # Controller #, val
  CONTROLLER = 0xB0
  # Program number
  PROGRAM_CHANGE = 0xC0
  # Channel pressure
  CHANNEL_PRESSURE = 0xD0
  # LSB, MSB
  PITCH_BEND = 0xE0

  #--
  # System common messages
  #++
  # System exclusive start
  SYSEX = 0xF0
  # Beats from top: LSB/MSB 6 ticks = 1 beat
  SONG_POINTER = 0xF2
  # Val = number of song
  SONG_SELECT = 0xF3
  # Tune request
  TUNE_REQUEST = 0xF6
  # End of system exclusive
  EOX = 0xF7

  #--
  # System realtime messages
  #++
  # MIDI clock (24 per quarter note)
  CLOCK = 0xF8
  # Sequence start
  START = 0xFA
  # Sequence continue
  CONTINUE = 0xFB
  # Sequence stop
  STOP = 0xFC
  # Active sensing (sent every 300 ms when nothing else being sent)
  ACTIVE_SENSE = 0xFE
  # System reset
  SYSTEM_RESET = 0xFF

  #--
  # Controller numbers
  # = 0 - 31 = continuous, MSB
  # = 32 - 63 = continuous, LSB
  # = 64 - 97 = momentary switches
  #++
  CC_BANK_SELECT           = CC_BANK_SELECT_MSB           = 0
  CC_MOD_WHEEL             = CC_MOD_WHEEL_MSB             = 1
  CC_BREATH_CONTROLLER     = CC_BREATH_CONTROLLER_MSB     = 2
  CC_FOOT_CONTROLLER       = CC_FOOT_CONTROLLER_MSB       = 4
  CC_PORTAMENTO_TIME       = CC_PORTAMENTO_TIME_MSB       = 5
  CC_DATA_ENTRY            = CC_DATA_ENTRY_MSB            = 6
  CC_VOLUME                = CC_VOLUME_MSB                = 7
  CC_BALANCE               = CC_BALANCE_MSB               = 8
  CC_PAN                   = CC_PAN_MSB                   = 10
  CC_EXPRESSION_CONTROLLER = CC_EXPRESSION_CONTROLLER_MSB = 11
  CC_GEN_PURPOSE_1         = CC_GEN_PURPOSE_1_MSB         = 16
  CC_GEN_PURPOSE_2         = CC_GEN_PURPOSE_2_MSB         = 17
  CC_GEN_PURPOSE_3         = CC_GEN_PURPOSE_3_MSB         = 18
  CC_GEN_PURPOSE_4         = CC_GEN_PURPOSE_4_MSB         = 19

  #--
  # [32 - 63] are LSB for [0 - 31]
  #++
  CC_BANK_SELECT_LSB           = CC_BANK_SELECT_MSB           + 32
  CC_MOD_WHEEL_LSB             = CC_MOD_WHEEL_MSB             + 32
  CC_BREATH_CONTROLLER_LSB     = CC_BREATH_CONTROLLER_MSB     + 32
  CC_FOOT_CONTROLLER_LSB       = CC_FOOT_CONTROLLER_MSB       + 32
  CC_PORTAMENTO_TIME_LSB       = CC_PORTAMENTO_TIME_MSB       + 32
  CC_DATA_ENTRY_LSB            = CC_DATA_ENTRY_MSB            + 32
  CC_VOLUME_LSB                = CC_VOLUME_MSB                + 32
  CC_BALANCE_LSB               = CC_BALANCE_MSB               + 32
  CC_PAN_LSB                   = CC_PAN_MSB                   + 32
  CC_EXPRESSION_CONTROLLER_LSB = CC_EXPRESSION_CONTROLLER_MSB + 32
  CC_GEN_PURPOSE_1_LSB         = CC_GEN_PURPOSE_1_MSB         + 32
  CC_GEN_PURPOSE_2_LSB         = CC_GEN_PURPOSE_2_MSB         + 32
  CC_GEN_PURPOSE_3_LSB         = CC_GEN_PURPOSE_3_MSB         + 32
  CC_GEN_PURPOSE_4_LSB         = CC_GEN_PURPOSE_4_MSB         + 32

  #--
  # Momentary switches:
  #++
  CC_SUSTAIN = 64
  CC_PORTAMENTO = 65
  CC_SUSTENUTO = 66
  CC_SOFT_PEDAL = 67
  CC_HOLD_2 = 69
  CC_GEN_PURPOSE_5 = 50
  CC_GEN_PURPOSE_6 = 51
  CC_GEN_PURPOSE_7 = 52
  CC_GEN_PURPOSE_8 = 53
  CC_EXT_EFFECTS_DEPTH = 91
  CC_TREMELO_DEPTH = 92
  CC_CHORUS_DEPTH = 93
  CC_DETUNE_DEPTH = 94
  CC_PHASER_DEPTH = 95
  CC_DATA_INCREMENT = 96
  CC_DATA_DECREMENT = 97
  CC_NREG_PARAM_LSB = 98
  CC_NREG_PARAM_MSB = 99
  CC_REG_PARAM_LSB = 100
  CC_REG_PARAM_MSB = 101

  #--
  # Channel mode message values
  #++
  # Val 0 == off, 0x7f == on
  CM_RESET_ALL_CONTROLLERS = 0x79
  CM_LOCAL_CONTROL = 0x7A
  CM_ALL_NOTES_OFF = 0x7B       # Val must be 0
  CM_OMNI_MODE_OFF = 0x7C       # Val must be 0
  CM_OMNI_MODE_ON = 0x7D        # Val must be 0
  CM_MONO_MODE_ON = 0x7E        # Val = # chans
  CM_POLY_MODE_ON = 0x7F        # Val must be 0

  CONTROLLER_NAMES = [
    "Bank Select (MSB)",
    "Modulation (MSB)",
    "Breath Control (MSB)",
    "3 (MSB)",
    "Foot Controller (MSB)",
    "Portamento Time (MSB)",
    "Data Entry (MSB)",
    "Volume (MSB)",
    "Balance (MSB)",
    "9 (MSB)",
    "Pan (MSB)",
    "Expression Control (MSB)",
    "12 (MSB)", "13 (MSB)", "14 (MSB)", "15 (MSB)",
    "General Controller 1 (MSB)",
    "General Controller 2 (MSB)",
    "General Controller 3 (MSB)",
    "General Controller 4 (MSB)",
    "20 (MSB)", "21 (MSB)", "22 (MSB)", "23 (MSB)", "24 (MSB)", "25 (MSB)",
    "26 (MSB)", "27 (MSB)", "28 (MSB)", "29 (MSB)", "30 (MSB)", "31 (MSB)",

    "Bank Select (LSB)",
    "Modulation (LSB)",
    "Breath Control (LSB)",
    "35 (LSB)",
    "Foot Controller (LSB)",
    "Portamento Time (LSB)",
    "Data Entry (LSB)",
    "Volume (LSB)",
    "Balance (LSB)",
    "41 (LSB)",
    "Pan (LSB)",
    "Expression Control (LSB)",
    "44 (LSB)", "45 (LSB)", "46 (LSB)", "47 (LSB)",
    "General Controller 1 (LSB)",
    "General Controller 2 (LSB)",
    "General Controller 3 (LSB)",
    "General Controller 4 (LSB)",
    "52 (LSB)", "53 (LSB)", "54 (LSB)", "55 (LSB)", "56 (LSB)", "57 (LSB)",
    "58 (LSB)", "59 (LSB)", "60 (LSB)", "61 (LSB)", "62 (LSB)", "63 (LSB)",

    "Sustain Pedal",
    "Portamento",
    "Sostenuto",
    "Soft Pedal",
    "68",
    "Hold 2",
    "70", "71", "72", "73", "74", "75", "76", "77", "78", "79",
    "General Controller 5",
    "Tempo Change",
    "General Controller 7",
    "General Controller 8",
    "84", "85", "86", "87", "88", "89", "90",
    "External Effects Depth",
    "Tremolo Depth",
    "Chorus Depth",
    "Detune (Celeste) Depth",
    "Phaser Depth",
    "Data Increment",
    "Data Decrement",
    "Non-Registered Param LSB",
    "Non-Registered Param MSB",
    "Registered Param LSB",
    "Registered Param MSB",
    "102", "103", "104", "105", "106", "107", "108", "109",
    "110", "111", "112", "113", "114", "115", "116", "117",
    "118", "119", "120",
    "Reset All Controllers",
    "Local Control",
    "All Notes Off",
    "Omni Mode Off",
    "Omni Mode On",
    "Mono Mode On",
    "Poly Mode On"
  ]

  # General MIDI patch names
  GM_PATCH_NAMES = [
    #--
    # Pianos
    #++
    "Acoustic Grand Piano",
    "Bright Acoustic Piano",
    "Electric Grand Piano",
    "Honky-tonk Piano",
    "Electric Piano 1",
    "Electric Piano 2",
    "Harpsichord",
    "Clavichord",
    #--
    # Tuned Idiophones
    #++
    "Celesta",
    "Glockenspiel",
    "Music Box",
    "Vibraphone",
    "Marimba",
    "Xylophone",
    "Tubular Bells",
    "Dulcimer",
    #--
    # Organs
    #++
    "Drawbar Organ",
    "Percussive Organ",
    "Rock Organ",
    "Church Organ",
    "Reed Organ",
    "Accordion",
    "Harmonica",
    "Tango Accordion",
    #--
    # Guitars
    #++
    "Acoustic Guitar (nylon)",
    "Acoustic Guitar (steel)",
    "Electric Guitar (jazz)",
    "Electric Guitar (clean)",
    "Electric Guitar (muted)",
    "Overdriven Guitar",
    "Distortion Guitar",
    "Guitar harmonics",
    #--
    # Basses
    #++
    "Acoustic Bass",
    "Electric Bass (finger)",
    "Electric Bass (pick)",
    "Fretless Bass",
    "Slap Bass 1",
    "Slap Bass 2",
    "Synth Bass 1",
    "Synth Bass 2",
    #--
    # Strings
    #++
    "Violin",
    "Viola",
    "Cello",
    "Contrabass",
    "Tremolo Strings",
    "Pizzicato Strings",
    "Orchestral Harp",
    "Timpani",
    #--
    # Ensemble strings and voices
    #++
    "String Ensemble 1",
    "String Ensemble 2",
    "SynthStrings 1",
    "SynthStrings 2",
    "Choir Aahs",
    "Voice Oohs",
    "Synth Voice",
    "Orchestra Hit",
    #--
    # Brass
    #++
    "Trumpet",
    "Trombone",
    "Tuba",
    "Muted Trumpet",
    "French Horn",
    "Brass Section",
    "SynthBrass 1",
    "SynthBrass 2",
    #--
    # Reeds
    #++
    "Soprano Sax",              # 64
    "Alto Sax",
    "Tenor Sax",
    "Baritone Sax",
    "Oboe",
    "English Horn",
    "Bassoon",
    "Clarinet",
    #--
    # Pipes
    #++
    "Piccolo",
    "Flute",
    "Recorder",
    "Pan Flute",
    "Blown Bottle",
    "Shakuhachi",
    "Whistle",
    "Ocarina",
    #--
    # Synth Leads
    #++
    "Lead 1 (square)",
    "Lead 2 (sawtooth)",
    "Lead 3 (calliope)",
    "Lead 4 (chiff)",
    "Lead 5 (charang)",
    "Lead 6 (voice)",
    "Lead 7 (fifths)",
    "Lead 8 (bass + lead)",
    #--
    # Synth Pads
    #++
    "Pad 1 (new age)",
    "Pad 2 (warm)",
    "Pad 3 (polysynth)",
    "Pad 4 (choir)",
    "Pad 5 (bowed)",
    "Pad 6 (metallic)",
    "Pad 7 (halo)",
    "Pad 8 (sweep)",
    #--
    # Effects
    #++
    "FX 1 (rain)",
    "FX 2 (soundtrack)",
    "FX 3 (crystal)",
    "FX 4 (atmosphere)",
    "FX 5 (brightness)",
    "FX 6 (goblins)",
    "FX 7 (echoes)",
    "FX 8 (sci-fi)",
    #--
    # Ethnic
    #++
    "Sitar",
    "Banjo",
    "Shamisen",
    "Koto",
    "Kalimba",
    "Bag pipe",
    "Fiddle",
    "Shanai",
    #--
    # Percussion
    #++
    "Tinkle Bell",
    "Agogo",
    "Steel Drums",
    "Woodblock",
    "Taiko Drum",
    "Melodic Tom",
    "Synth Drum",
    "Reverse Cymbal",
    #--
    # Sound Effects
    #++
    "Guitar Fret Noise",
    "Breath Noise",
    "Seashore",
    "Bird Tweet",
    "Telephone Ring",
    "Helicopter",
    "Applause",
    "Gunshot"
  ]

  # GM drum notes start at 35 (C), so subtrack GM_DRUM_NOTE_LOWEST from your
  # note number before using this array.
  GM_DRUM_NOTE_LOWEST = 35
  # General MIDI drum channel note names.
  GM_DRUM_NOTE_NAMES = [
    "Acoustic Bass Drum",       # 35, C
    "Bass Drum 1",              # 36, C#
    "Side Stick",               # 37, D
    "Acoustic Snare",           # 38, D#
    "Hand Clap",                # 39, E
    "Electric Snare",           # 40, F
    "Low Floor Tom",            # 41, F#
    "Closed Hi Hat",            # 42, G
    "High Floor Tom",           # 43, G#
    "Pedal Hi-Hat",             # 44, A
    "Low Tom",                  # 45, A#
    "Open Hi-Hat",              # 46, B
    "Low-Mid Tom",              # 47, C
    "Hi Mid Tom",               # 48, C#
    "Crash Cymbal 1",           # 49, D
    "High Tom",                 # 50, D#
    "Ride Cymbal 1",            # 51, E
    "Chinese Cymbal",           # 52, F
    "Ride Bell",                # 53, F#
    "Tambourine",               # 54, G
    "Splash Cymbal",            # 55, G#
    "Cowbell",                  # 56, A
    "Crash Cymbal 2",           # 57, A#
    "Vibraslap",                # 58, B
    "Ride Cymbal 2",            # 59, C
    "Hi Bongo",                 # 60, C#
    "Low Bongo",                # 61, D
    "Mute Hi Conga",            # 62, D#
    "Open Hi Conga",            # 63, E
    "Low Conga",                # 64, F
    "High Timbale",             # 65, F#
    "Low Timbale",              # 66, G
    "High Agogo",               # 67, G#
    "Low Agogo",                # 68, A
    "Cabasa",                   # 69, A#
    "Maracas",                  # 70, B
    "Short Whistle",            # 71, C
    "Long Whistle",             # 72, C#
    "Short Guiro",              # 73, D
    "Long Guiro",               # 74, D#
    "Claves",                   # 75, E
    "Hi Wood Block",            # 76, F
    "Low Wood Block",           # 77, F#
    "Mute Cuica",               # 78, G
    "Open Cuica",               # 79, G#
    "Mute Triangle",            # 80, A
    "Open Triangle"             # 81, A#
  ]

end # PM
