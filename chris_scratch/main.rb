#!/usr/bin/env ruby

require 'puppet'
require './foo'

Puppet.initialize_settings(["--binder" "true"])

puts Puppet[:certname]

## TODO: this line doesn't work; don't know what the proper means of
## acquiring a reference to the injector is
injector = Puppet.lookup(:injector)

# I don't think I need the scope, so just passing nil
# TODO: need to know what config file to register this producer in
producer = injector.lookup_producer(nil, Foo)

a = 42
b = 420
# I don't think I need the scope, so just passing nil
myfoo = producer.produce(nil, a, b)

# TODO: the type of `myfoo` should be based on how I configured the producer
# in whatever config file that needs to go in
puts "MyFoo is: #{myfoo}"
