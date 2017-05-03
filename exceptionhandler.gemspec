Gem::Specification.new do |s|
  s.name        = 'exceptionhandler'
  s.version     = '0.0.4'
  s.date        = '2017-05-03'
  s.summary     = "Log exceptions in a log friendly way."
  s.description = "Log exceptions in a log friendly way."
  s.authors     = ["Matt Knox"]
  s.email       = 'matt.knox@sphero.com'
  s.files       = ["lib/exceptionhandler.rb"]
  s.license       = 'MIT'
  s.add_runtime_dependency 'httpclient' ,  '~> 2.8', '>= 2.8.2.2'
end
