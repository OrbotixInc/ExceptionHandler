This is a simple class that is meant to be used in conjunction with [rollbar-gem](https://github.com/rollbar/rollbar-gem) for catching exceptions. It handles logging exceptions into a single line (usefull for parsing in sumologic) and sending exception count metrics to influxdb.

Usage
=====
To utilize this gem, ensure that you have both the rollbar and exceptionhandler gems in your Gemfile:

```
gem 'rollbar'
gem 'exceptionhandler', github: 'OrbotixInc/ExceptionHandler', branch: 'master'
```

Then you can simple configure the rollbar gem to use the ExceptionHandler class as for it's before_process. For a rails app this can be done in an initalizer, for other frameworks reference the [rollbar-gem documentation](https://github.com/rollbar/rollbar-gem).
```
require 'exceptionhandler'

Rollbar.configure do |config|
  config.before_process << ExceptionHandler.new
end
```

For sending metrics to influxdb via the graphite protocol, this gem requires the `graphite_host` and `graphite_port` environment variables to be set.
