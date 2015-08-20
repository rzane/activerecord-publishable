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

Rake::TestTask.new :spec do |t|
  t.libs << 'lib' << 'spec'
  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = false
end

task :default => :spec

namespace :examples do
  namespace :sse do
    task :app do
      ruby 'examples/sse/app.rb'
    end

    task :data do
      ruby 'examples/sse/change_data.rb'
    end
  end

  multitask :sse => ['sse:app', 'sse:data']
end
