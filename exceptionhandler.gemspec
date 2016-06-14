Gem::Specification.new do |s|
  s.name        = 'exceptionhandler'
  s.version     = '0.0.1'
  s.date        = '2016-06-13'
  s.summary     = "Log exceptions in a log friendly way."
  s.description = "Log exceptions in a log friendly way."
  s.authors     = ["Matt Knox"]
  s.email       = 'matt.knox@sphero.com'
  s.files       = ["lib/exceptionhandler.rb"]
  s.license       = 'MIT'
  s.add_runtime_dependency 'metriks' , '~> 0.9', '>= 0.9.9.7'
  s.add_runtime_dependency 'rollbar' , '~> 2.11', '>= 2.11.3'
  s.add_runtime_dependency 'unirest' , '~> 1.1', '>= 1.1.2'
end
