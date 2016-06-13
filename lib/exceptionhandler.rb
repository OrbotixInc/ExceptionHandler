class ExceptionHandler
  def call(options)
    if !options[:exception].nil?
      trace_chain = trace_chain(options[:exception])
      puts "Exception Caught ("+options[:exception].class.name+"): " + trace_chain.to_s
    end
    
    #The whole point of this handler is to replace rollbar, so raise this exception to prevent trying to send to rollbar
    raise Rollbar::Ignore
  end


  def trace_chain(exception)
    traces = [trace_data(exception)]
    visited = [exception]
    current_exception = exception

    while current_exception.respond_to?(:cause) && (cause = current_exception.cause) && cause.is_a?(Exception) && !visited.include?(cause)
      traces << trace_data(cause)
      visited << cause
      current_exception = cause
    end

    traces
  end

  def trace_data(current_exception)
    frames = reduce_frames(current_exception)
    # reverse so that the order is as rollbar expects
    frames.reverse!

    {
      :frames => frames,
      :exception => {
        :class => current_exception.class.name,
        :message => current_exception.message
      }
    }
  end

  def reduce_frames(current_exception)
    exception_backtrace(current_exception).map do |frame|
      # parse the line
      match = frame.match(/(.*):(\d+)(?::in `([^']+)')?/)

      if match
        { :filename => match[1], :lineno => match[2].to_i, :method => match[3] }
      else
        { :filename => '<unknown>', :lineno => 0, :method => frame }
      end
    end
  end

  def exception_backtrace(current_exception)
        return [] if current_exception.nil?
        return current_exception.backtrace if current_exception.backtrace.respond_to?(:map)
        return []
  end


end
