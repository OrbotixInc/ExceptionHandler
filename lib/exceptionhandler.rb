require 'logger'
require 'httpclient'


class ExceptionHandler

  def initialize()
    #Get the cluster name from Google metadata service
    cluster_name="unknown_cluster"
    begin
      clnt = HTTPClient.new()
      response = clnt.get "http://metadata.google.internal/computeMetadata/v1/instance/attributes/cluster-name", nil, "Metadata-Flavor" => "Google"
      if response.status == 200
        cluster_name=response.body
      end
    rescue
      p "Couldn't determine cluster name."
    end

    #Grap the rest of the details from tags
    environment = ENV['environment'] ? ENV['environment'] : "unknown_env"
    app = ENV['DEIS_APP'] ? ENV['DEIS_APP'] : "unknown_app"
    release = ENV['WORKFLOW_RELEASE'] ? ENV['WORKFLOW_RELEASE'] : "unknown_release"

    @request_body_base = {:application => app, :version => release, :environment => environment, :cluster => cluster_name, :token => ENV['EXCEPTION_TOKEN']}
  end

  def call(options)
    if !options[:exception].nil?

      trace_chain = trace_chain(options[:exception])
      puts "Exception Caught ("+options[:exception].class.name+"): " + trace_chain.to_s

      excep = options[:exception].class.name 
      backtrace = "#{ options[:exception].message } (#{ options[:exception].class })\n" <<
      (options[:exception].backtrace || []).join("\n")

      if ENV['EXCEPTION_URL']
        excep = options[:exception].class.name
        backtrace = "#{ options[:exception].message } (#{ options[:exception].class })\n" <<
        (options[:exception].backtrace || []).join("\n")

        # Create a hash id from the exception class and the stacktrace to identify unique occurences of the same exception class
        hash_id = Digest::SHA256.hexdigest "#{excep} #{backtrace}"

        request_body = @request_body_base
        request_body[:timestamp] = Time.now
        request_body[:id] = hash_id
        request_body[:exception] = excep
        request_body[:detail] = backtrace

        clnt = HTTPClient.new()
        clnt.post_async("#{ENV['EXCEPTION_URL']}/exception", request_body) 
      end

    else
      puts options
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
