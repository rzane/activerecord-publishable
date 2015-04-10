begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rdoc/task'

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'PublicActivityAggregate'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

require "bundler/gem_tasks"

Bundler::GemHelper.install_tasks

require "rake/testtask"

spec_files        = FileList['spec/**/*_spec.rb']
integration_files = FileList['spec/integration_spec.rb']
unit_files        = spec_files - integration_files

def define_task name, files
  Rake::TestTask.new name do |t|
    t.libs << 'lib' << 'spec'
    t.test_files = files
    t.verbose = false
  end
end

namespace :spec do
  define_task :unit, unit_files
  define_task :integration, integration_files
end

define_task :spec, spec_files
task :default => :spec

namespace :example do
  puts "Running example/change_data.rb in a separate thread."
  Thread.new { ruby 'example/change_data.rb' }

  puts "Starting example/app.rb"
  ruby 'example/app.rb'
end
