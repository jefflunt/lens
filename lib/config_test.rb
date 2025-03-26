require 'minitest/autorun'
require 'yaml'
require_relative './config'

class TestConfig < Minitest::Test
  def setup
    @config = Config.new(YAML.load(IO.read('config.yml')))
  end

  def test_mode_cmds
    # direct, subcmd, and wildcards from 'buff' mode
    assert_equal 'autosave_enable', @config.cmd('buff', nil, 'a')
    assert_equal :c, @config.cmd('buff', nil, 'c')
    assert_equal 'clipboard_open', @config.cmd('buff', :c, 'o')
    assert_equal :m, @config.cmd('buff', nil, 'm')
    assert_equal ['paste_from', 'a'], @config.cmd('buff', :p, 'a')
    assert_equal ['paste_from', 'b'], @config.cmd('buff', :p, 'b')
    assert_equal ['paste_from', 'c'], @config.cmd('buff', :p, 'c')

    # confirming works in other modes as well
    assert_equal 'pan_left', @config.cmd('pan', nil, 'h')
    assert_equal :c, @config.cmd('select', nil, 'c')
    assert_equal ['copy_to', 'c'], @config.cmd('select', :c, 'c')

    assert_nil @config.cmd('buff', nil, '!')             # cmd not found
    assert_nil @config.cmd('buff', :t, 'x')              # subcmd 'tx' not found
    assert_nil @config.cmd('buff', :x, 'a')              # wildcard 'x' not found
  end

  def test_subcmd_timeout
    assert_equal 1, @config.subcmd_timeout
  end

  def test__mode
    assert @config._mode('buff').is_a?(Hash)
    assert_equal 'autosave_enable', @config._mode('buff')['a']
  end
end
