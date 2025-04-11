require 'minitest/autorun'
require 'yaml'
require_relative './config'

class TestConfig < Minitest::Test
  def setup
    @config = Config.new(YAML.load(IO.read('config.yml')))
  end

  def test_mode_cmds
    # direct, subcmd, and wildcards from 'normal' mode
    assert_equal 'autosave_enable', @config.cmd('normal', nil, 'a')
    assert_equal :c, @config.cmd('normal', nil, 'c')
    assert_equal 'clipboard_open', @config.cmd('normal', :c, 'o')

    assert_equal :m, @config.cmd('normal', nil, 'm')
    assert_equal ['mark_set', 'x'], @config.cmd('normal', :m, 'x')

    assert_equal :"'", @config.cmd('normal', nil, "'")
    assert_equal ['mark_goto', 'x'], @config.cmd('normal', :"'", 'x')

    assert_equal ['paste_from', 'a'], @config.cmd('normal', :p, 'a')
    assert_equal ['paste_from', 'b'], @config.cmd('normal', :p, 'b')
    assert_equal ['paste_from', 'c'], @config.cmd('normal', :p, 'c')

    assert_equal :R, @config.cmd('normal', nil, 'R')
    assert_equal 'reload_config', @config.cmd('normal', :R, 'C')

    # confirming works in other modes as well
    assert_equal 'rect_left!', @config.cmd('pan', nil, 'h')
    assert_equal :c, @config.cmd('select', nil, 'c')
    assert_equal ['copy_to', 'c'], @config.cmd('select', :c, 'c')

    assert_nil @config.cmd('normal', nil, '!')             # cmd not found
    assert_nil @config.cmd('normal', :t, 'x')              # subcmd 'tx' not found
    assert_nil @config.cmd('normal', :x, 'a')              # wildcard 'x' not found
  end

  def test_subcmd_timeout
    assert_equal 1, @config.subcmd_timeout
  end

  def test_default_mode
    assert_equal 'normal', @config.default_mode
  end

  def test__mode
    assert @config._mode('normal').is_a?(Hash)
    assert_equal 'autosave_enable', @config._mode('normal')['a']
  end
end
