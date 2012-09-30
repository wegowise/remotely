source :rubygems
gemspec

platforms :jruby do
  gem "jruby-openssl"
end

group :development, :test do
  platforms :mri do
    gem "debugger"
  end

  platforms :jruby do
    gem "ruby-debug"
  end
end
