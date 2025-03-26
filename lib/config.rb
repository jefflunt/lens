require 'yaml'

##
# this class reads the config.yml file (passed in as string), and generates the lens config
class Config
  def self.parse(config_str)
    Config.new(
  end

  def initialize(config)
    @config = config
  end

  # given the specified, current mode and keystroke, return the command to
  # execute
  #
  # for example, if you're in `cmd` mode and you press the 'C' key (defaults to
  # "clear_to_eol"), then the `clear_to_eol` command is sent to the current
  # buffer to clear from teh cursor to the end of the line.
  #
  # if a given keystroke doesn't result in a command, but starts a sub-command,
  # then a timer is set for the sub-command to be selected. 
  def cmd(mode, subcmd, keystroke)
    
  end
end
