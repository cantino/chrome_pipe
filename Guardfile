# A Guardfile
# More info at https://github.com/guard/guard#readme

require 'uglifier'
require 'yui/compressor'
require 'fileutils'

# Make the directory structure

%w[combined js css targets].each do |path|
  FileUtils.mkdir_p File.join(File.dirname(__FILE__), 'compiled', path)
end

FileUtils.mkdir_p File.join(File.dirname(__FILE__), 'spec', 'compiled')

# Specs

guard 'coffeescript', :input => 'spec', :output => 'spec/compiled', :all_on_start => true

# Core Code

guard 'coffeescript', :input => 'source/js', :output => 'compiled/js', :all_on_start => true
guard 'sass', :input => 'source/css', :output => 'compiled/css', :all_on_start => true, :line_numbers => true

# Chrome Extension

guard 'concat',
    :all_on_start => true,
    :type => "js",
    :files => %w(utils chrome-pipe chrome),
    :input_dir => "compiled/js",
    :output => "compiled/combined/chrome"

guard 'concat',
    :all_on_start => true,
    :type => "js",
    :files => %w(utils background-page),
    :input_dir => "compiled/js",
    :output => "compiled/combined/background-page"

guard 'concat',
      :all_on_start => true,
      :type => "js",
      :files => %w(stream terminal command-parser commands/terminal/*),
      :input_dir => "compiled/js",
      :output => "compiled/combined/terminal"

guard 'concat',
      :all_on_start => true,
      :type => "css",
      :files => %w(chrome),
      :input_dir => "compiled/css",
      :output => "compiled/combined/chrome"

# Specs

guard 'concat',
      :all_on_start => true,
      :type => "js",
      :files => %w(utils chrome-pipe stream terminal command-parser commands/always/* commands/terminal/*),
      :input_dir => "compiled/js",
      :output => "compiled/combined/specs"

guard 'concat',
      :all_on_start => true,
      :type => "css",
      :files => %w(chrome),
      :input_dir => "compiled/css",
      :output => "compiled/combined/specs"

guard :shell, :all_on_start => true do
  watch %r{compiled/combined/(.+?)\.js$} do |m|
    puts "Compressing #{m[1]}"
    File.open("compiled/targets/#{m[1]}.js", 'w') do |file|
      file.print Uglifier.compile(File.read(m[0]))
    end
  end
end

last_compile = nil
Thread.abort_on_exception = true

guard :shell, :all_on_start => true do
  watch %r{compiled/targets/(chrome|background-page|terminal)\.(css|js)$} do |m|
    if last_compile.nil? || last_compile < Time.now - 8
      last_compile = Time.now
      puts "Building Chrome (#{m[0]})"
      Thread.new do
        sleep 3
        puts "Chrome extension building..."
        FileUtils.mkdir_p "compiled/chrome-extension"
        system "rm -rf compiled/chrome-extension/*"

        FileUtils.cp "compiled/combined/chrome.css", "compiled/chrome-extension/chrome.css"
        FileUtils.cp "compiled/targets/chrome.js", "compiled/chrome-extension/chrome.js"
        FileUtils.cp "compiled/targets/terminal.js", "compiled/chrome-extension/terminal.js"
        FileUtils.cp "compiled/targets/background-page.js", "compiled/chrome-extension/background-page.js"

        FileUtils.cp_r %w[chrome/manifest.json], "compiled/chrome-extension"

        FileUtils.cp_r %w[shared/app-icons shared/vendor], "compiled/chrome-extension"

        FileUtils.rm_f "compiled/chrome-extension.zip"
        system "zip -r compiled/chrome-extension.zip compiled/chrome-extension"
        puts "Chrome extension built!"
      end
    end
  end
end
