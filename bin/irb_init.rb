# Set IRB prompt
IRB.conf[:PROMPT][:CUSTOM] = {
  :PROMPT_I=>"PatchMaster:%03n:%i> ",
  :PROMPT_N=>"PatchMaster:%03n:%i> ",
  :PROMPT_S=>"PatchMaster:%03n:%i%l ",
  :PROMPT_C=>"PatchMaster:%03n:%i* ",
  :RETURN=>"=> %s\n"
}
IRB.conf[:PROMPT_MODE] = :CUSTOM

# Load ./.patchmasterrc or $HOME/.patchmasterrc
rc_file = File.join('.', '.patchmasterrc')
rc_file = File.join(ENV['HOME'], '.patchmasterrc') unless File.exist?(rc_file)
load(rc_file) if File.exist?(rc_file)

puts 'PatchMaster loaded'
puts 'Type "pm_help" for help'
