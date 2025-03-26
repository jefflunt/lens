##
# this class reads the config.yml file (passed in as string), and generates the lens config
class Config
  # config: a Hash containing a config, e.g. parsed from the ./config.yml file
  def initialize(config)
    @config = config
  end

  # supports three kinds of commands:
  #
  # DIRECT: command is invoked immediately from the input keystroke
  #   ex: 'd' to delete the current line from the 'home' mode
  #
  # subcmd: keystroke triggers one of several possible direct sub-commands
  #   ex: 'b', then 'a' -> 'b' finds other 'b' commands having to do with buffer
  #     management, and 'a' starts the `ms_buff_adj` command
  #
  # wildcard: keystroke readies a command, but waits for the followup
  #   keystroke to invoke the command
  #   ex: 'm', then 'c' -> 'm' readies the 'mark_set' command, but the input
  #     waits for follow-up keystroke to set the name of the mark
  def cmd(mode, subcmd, keystroke)
    if subcmd
      # handle wildcard
      wildcard = _mode(mode)["#{subcmd}*"]
      return "#{wildcard} #{keystroke}" if wildcard                           # wildcard

      _mode(mode)["#{subcmd}#{keystroke}"]                                    # subcmd
    else
      return _mode(mode)[keystroke] if _mode(mode).keys.include?(keystroke)   # direct

      subcmds = _mode(mode).keys.select{|k| k.start_with?(subcmd.to_s) }
      keystroke.to_sym if subcmds.length > 1                                  # subcmd ready
    end
  end

  def exit_mode_key
    @config['exit_mode_key']
  end

  def subcmd_timeout
    @config['subcmd_timeout']
  end

  # returns the portion of the config under the named mode
  def _mode(name)
    @config['modes'][name]
  end
end
