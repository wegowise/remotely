source 'https://rubygems.org'
gemspec

platforms :jruby do
  gem "jruby-openssl"
end

group :development, :test do
  platforms :ruby_19 do
    gem "debugger"
  end

  platforms :jruby do
    gem "ruby-debug"
  end
end
