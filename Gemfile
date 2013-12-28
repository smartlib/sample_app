# 使用taobao镜像作为下载源
source 'http://ruby.taobao.org'

# 强制使用ruby 2.0.0
ruby '2.0.0'

# 基本组件
gem "rails", "4.0.2"
gem 'turbolinks', '~> 1.2.0'
gem 'jquery-turbolinks', '2.0.0'
gem "rails-i18n","0.1.8"
gem "jquery-rails", "3.0.4"

# css及js编译相关
gem 'sass-rails', "~> 4.0.0"
gem 'coffee-rails', "~> 4.0.0"
gem 'uglifier', '2.1.1'

# 界面相关
gem 'bootstrap-sass', '2.3.2'

# 数据表格组件
gem 'roo'

# 自动化部署组件
gem "mina", github: 'nadarei/mina'

# 开发环境使用
group :development do
  gem 'sqlite3', '1.3.7'
  gem 'rspec-rails', '2.13.2'
  gem 'factory_girl_rails', '4.2.1'
  gem 'capybara', '2.1.0'
  gem 'guard-rspec', '2.5.0'
  gem 'guard-spork', '1.5.0'
  gem 'spork-rails', github: 'railstutorial/spork-rails'
end

# 生产环境使用
group :production do
  gem 'mysql2', '0.3.14'
  gem 'unicorn'
end
