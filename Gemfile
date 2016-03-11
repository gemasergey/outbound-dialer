source 'https://rubygems.org'

gem 'adhearsion', '~> 2.5'
#gem 'adhearsion-activerecord'

# Exercise care when updating the Punchblock major version, since Adhearsion
# apps sometimes make use of underlying features from the Punchblock API.
# Occasionally an update of Adhearsion will necessitate an update to
# Punchblock; in those cases update this line and test your app thoroughly.
gem 'punchblock', '~> 2.5'

# This is here by default due to deprecation of #ask and #menu.
# See http://adhearsion.com/docs/common_problems#toc_3 for details
#gem 'adhearsion-asr'

#
# Check http://ahnhub.com for a list of plugins you can use in your app.
# To use them, simply add them here and run `bundle install`.
#

group :development, :test do
  gem 'rspec'
end

gem 'dialer_plugin', path: 'dialer_plugin'
gem 'mysql2'
gem 'sequella'
#gem 'paperclip'
#gem 'bcrypt'
