require 'rubygems'
require 'rake/testtask'

# Test --------------------------------------------------------------------
desc 'Run the test suite'
task :test do
  Rake::TestTask.new do |t|
    t.verbose = true
    t.warning = true
    t.pattern = 'test/**/*_test.rb'
  end
end

task default: :test
