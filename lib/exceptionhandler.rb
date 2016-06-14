require 'metriks'
require 'logger'
require 'metriks/reporter/graphite'
require 'unirest'


class ExceptionHandler

  def initialize()
    #Get the cluster name from Google metadata service
    cluster_name="unknown_cluster"
    begin
      response = Unirest.get('http://metadata.google.internal/computeMetadata/v1/instance/attributes/cluster-name',headers:{ "Metadata-Flavor" => "Google"})
      if response.code == 200
        cluster_name=response.body
      end
    rescue
      p "Couldn't determine cluster name."
    end

    #Grap the rest of the details from tags
    environment = ENV['environment'] ? ENV['environment'] : "unknown_env"
    app = ENV['DEIS_APP'] ? ENV['DEIS_APP'] : "unknown_app"
    release = ENV['WORKFLOW_RELEASE'] ? ENV['WORKFLOW_RELEASE'] : "unknown_release"

    #Format is cluster.env.appname.release.exceptions.{exception_name}
    @metric_prefix="#{cluster_name}.#{environment}.#{app}.#{release}.exceptions"

    @g_reporter = nil

  end

  def call(options)
    if !options[:exception].nil?

      #Rails doesn't like it if this thread is started in the initializer, so lets do it here if it wasn't already done.
      if @g_reporter == nil && ENV['graphite_host']
        p "Starting graphite reporter..."
        @g_reporter = Metriks::Reporter::Graphite.new(ENV['graphite_host'], ENV['graphite_port'], :on_error => proc  { |ex| puts ex })
        @g_reporter.start
        p "Reporting metrics with prefix: " + @metric_prefix
      end

      trace_chain = trace_chain(options[:exception])
      puts "Exception Caught ("+options[:exception].class.name+"): " + trace_chain.to_s

      excep = options[:exception].class.name.gsub('::','_') 
      meter = Metriks.meter("#{@metric_prefix}.#{excep}")
      meter.mark
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
