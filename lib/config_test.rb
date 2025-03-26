require 'minitest/autorun'
require 'yaml'
require_relative './config'

class TestFancyBuff < Minitest::Test
  def setup
    @config = Config.new(YAML.load(IO.read('config.yml')))
  end

  def test_mode_cmds
    # direct, subcmd, and wildcards from 'buff' mode
    assert_equal 'autosave_enable', @config.cmd('buff', nil, 'a')
    assert_equal :b, @config.cmd('buff', nil, 'b')
    assert_equal 'ms_buff_adj', @config.cmd('buff', :b, 'a')
    assert_equal :t, @config.cmd('buff', nil, 't')
    assert_equal ['mark_set', 'a'], @config.cmd('buff', :m, 'a')
    assert_equal ['mark_set', 'b'], @config.cmd('buff', :m, 'b')
    assert_equal ['mark_set', 'c'], @config.cmd('buff', :m, 'c')

    # confirming works in other modes as well
    assert_equal 'pan_left', @config.cmd('pan', nil, 'h')
    assert_equal :c, @config.cmd('select', nil, 'c')
    assert_equal ['copy_to', 'c'], @config.cmd('select', :c, 'c')

    assert_nil @config.cmd('buff', nil, '!')             # cmd not found
    assert_nil @config.cmd('buff', :t, 'x')              # subcmd 'tx' not found
    assert_nil @config.cmd('buff', :x, 'a')              # wildcard 'x' not found
  end

  def test_exit_mode_key_found
    assert_equal :esc, @config.exit_mode_key
  end

  def test_subcmd_timeout
    assert_equal 1, @config.subcmd_timeout
  end

  def test__mode
    assert @config._mode('buff').is_a?(Hash)
    assert_equal 'autosave_enable', @config._mode('buff')['a']
  end
end
