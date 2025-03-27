require 'minitest/autorun'
require 'yaml'
require_relative './config'

class TestConfig < Minitest::Test
  def setup
    @config = Config.new(YAML.load(IO.read('config.yml')))
  end

  def test_mode_cmds
    # direct, subcmd, and wildcards from 'buffer' mode
    assert_equal 'autosave_enable', @config.cmd('buffer', nil, 'a')
    assert_equal :c, @config.cmd('buffer', nil, 'c')
    assert_equal 'clipboard_open', @config.cmd('buffer', :c, 'o')

    assert_equal :m, @config.cmd('buffer', nil, 'm')
    assert_equal ['mark_set', 'x'], @config.cmd('buffer', :m, 'x')

    assert_equal :"'", @config.cmd('buffer', nil, "'")
    assert_equal ['mark_goto', 'x'], @config.cmd('buffer', :"'", 'x')

    assert_equal ['paste_from', 'a'], @config.cmd('buffer', :p, 'a')
    assert_equal ['paste_from', 'b'], @config.cmd('buffer', :p, 'b')
    assert_equal ['paste_from', 'c'], @config.cmd('buffer', :p, 'c')

    assert_equal :R, @config.cmd('buffer', nil, 'R')
    assert_equal 'reload_config', @config.cmd('buffer', :R, 'C')

    # confirming works in other modes as well
    assert_equal 'pan_left', @config.cmd('pan', nil, 'h')
    assert_equal :c, @config.cmd('select', nil, 'c')
    assert_equal ['copy_to', 'c'], @config.cmd('select', :c, 'c')

    assert_nil @config.cmd('buffer', nil, '!')             # cmd not found
    assert_nil @config.cmd('buffer', :t, 'x')              # subcmd 'tx' not found
    assert_nil @config.cmd('buffer', :x, 'a')              # wildcard 'x' not found
  end

  def test_subcmd_timeout
    assert_equal 1, @config.subcmd_timeout
  end

  def test_default_mode
    assert_equal 'buffer', @config.default_mode
  end

  def test__mode
    assert @config._mode('buffer').is_a?(Hash)
    assert_equal 'autosave_enable', @config._mode('buffer')['a']
  end
end
