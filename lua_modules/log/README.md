# Log

Logger.

It offers :

- debug, info, error and audit logging methods
- configurable logging level
- various logging backends i.e. to:
  - logstdout i.e. console
  - rsyslog server
  - logfile

logstdout supports color, handy if one is running terminal over serial console.

logfile supports writing to a file and log rotation.
this is rather "slow" logger as it opens a file for append for each message, use with caution.

rsyslog sends log messages to given destination using UDP.
