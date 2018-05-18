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

desc 'Delete ext build files'
task :clean_pa do
    save = ['ext/portaudio.i', 'ext/extconf.rb', 'bin/portaudio.bundle']
    Dir['ext/*', 'lib/*.bundle'].each do |f|
        unless save.include? f
            File.delete f
        end
    end
end

desc 'Build gem file.'
task :build do
    sh 'gem build aurora-sdk.gemspec'
end

desc 'Build portaudio bindings.'
task :build_pa do
    Rake::Task["clean_pa"].invoke
    Dir.chdir("ext/") do
        sh 'swig -ruby portaudio.i'
        ruby 'extconf.rb'
        sh 'make'
    end
    if File.exist? 'ext/portaudio.bundle'
        cp 'ext/portaudio.bundle', 'lib/'
    end
    if File.exist? 'ext/portaudio.so'
        cp 'ext/portaudio.so', 'lib/'
    end
end

desc 'Install gem.'
task :install do
    Rake::Task["build"].invoke
    Rake::Task["build_pa"].invoke
    gem_files = Dir['aurora-sdk-*.*.*.gem']

    if gem_files.length == 1
        sh "gem install #{gem_files[0]}"
    elsif gem_files.length > 1 and ENV['version'].nil?
        print 'Found too many .gem files:'
        gem_files.each do |filename|
            print " #{filename}"
        end

        puts "\nPlease specify version: rake build version=x.x.x"
    else
        target_version = ENV['version']

        if gem_files.include?("aurora-sdk-#{target_version}.gem")
            sh "gem install aurora-sdk-#{target_version}.gem"
        else
            puts "Version #{target_version} not found."
        end
    end
end

task :default => ['test']
