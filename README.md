This is a simple class that is meant to be used in conjunction with [rollbar-gem](https://github.com/rollbar/rollbar-gem) for catching exceptions. It handles logging exceptions into a single line (usefull for parsing in sumologic) and sending exception count metrics to influxdb.

Usage
=====
Simply install the rollbar-gem as you usually would and configure the before_process to use the ExceptionHandler class.
`config.before_process << ExceptionHandler.new`

For sending metrics to influxdb via the graphite protocol, this gem requires the `graphite_host` and `graphite_port` environment variables to be set.
