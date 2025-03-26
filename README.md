a text editor

run editor:

```
./lens
```

run tests:

```
./lens_tests
```

TODO:
- `fancy_buff` enhancements
  - load a buffer in another process and make it available via TCP
- everything below (configuratoin) is stored in a ~/.lens/config.yml
  file. the default configs that ship with the gem should be desgiend to work
  with the tiny_log gem, but there's no reason something this flexible couldn't
  also be used for whatever kind of log file you want
- parsers
  - txt
  - JSON
  - field definitions within log lines
    - write dynamic field matchers/pluckers to be able to pull data out of a log
      line
  - splitters
    - by spaces
    - by regex
    - by Ruby lambda
- mappers
  - based on parsing, be able to map the raw value of a log into something you
    define, for example, something trimmed down to just the fields you want to
    parse out of the log file
- reader display windows
  - default window is "everything" (i.e. no window)
  - read a log file in, but ignore anything before/after a certain window
  - windows can be defined by either timestamp or PID (if you want further
    filtering from there, use a filter
- reader display filters
  - filter on any of the defined fields, parsed output, splitters, or dynamic
    field definitions
- realtime tailing
  - allow realtime tailing of a log + display updating
  - realtime tailling should respect parsing, mapping, windows, and filters
- display options / toggles:
  - basic field coloring: highligh timestamp, PID, log level, and log messages
  - tailing: follows log file output in realtime
  - windowing: apply windowing
  - filtering: apply filtering
  - parsing: apply parsing
  - mapping: apply mapping
  - full: turn everything on
  - NOTE: if all of these options are turned off then you just get the raw log
    file
