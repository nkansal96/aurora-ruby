require 'rake/testtask'

desc 'Run all tests.'
Rake::TestTask.new do |t|
  t.pattern = './test/aurora/*_test.rb'
end

desc 'Delete gem build files.'
task :clean do
    Dir['*.gem'].each do |f|
        File.delete f
    end
end

task :default => ['test']
