This is a simple class that is meant to be used in conjunction with [rollbar-gem](https://github.com/rollbar/rollbar-gem) for catching exceptions and logging them to stdout. This way we can visualize exception metrics in SumoLogic.

To use this, just configure rollbar-gem as you usually would and configure the before_process to use the ExceptionHandler class `config.before_process << ExceptionHandler.new`
