require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)

# 基本设置
set :domain, '192.168.185.129'                  # 设置域名
set :deploy_to, '/root/railsbench/sample_app'               # 设置在服务器上部署的路径
set :repository, 'git@github.com:smartlib/sample_app.git'   # 设置git版本库地址
set :branch, 'master'                           # 确定代码的分支

# 在以下路径手动创建指定文件，这些文件将被链接到'deploy: link_shared_paths'步骤
set :shared_paths, ['config/database.yml', 'log']

# 可选参数
set :user, 'deploy'         # 指定使用SSH连接服务器的用户
# set :port, '30000'      # 设置SSH端口号.

# 设置对于其他命令（如：mina setup 或者 mina deploy）需要预先加载的环境
task :environment do
  # 如果使用rbenv（但需要确保.rbenv-version(rbenv local 1.9.3-p374)已经存在于你的项目中）
  # invoke :'rbenv:load'

  # 如果使用rvm，可以加载一个rvm version@gemset来配置你的项目环境
  invoke :'rvm:use[ruby-2.0.0-p353@rails4]'
end

# 运行 mina setup 时将执行以下操作
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]              # 创建日志目录
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]      # 设置日志目录权限

  queue! %[mkdir -p "#{deploy_to}/shared/config"]           # 创建配置目录
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]   # 设置配置目录权限

  queue! %[touch "#{deploy_to}/shared/config/database.yml"] # 创建database.yml文件
  queue  %[echo "-----> 请确定已修改数据库配置文件 '#{deploy_to}/shared/config/database.yml'."]
end

# 运行 mina deploy 时将执行以下操作
desc "向服务器部署当前版本！"
task :deploy => :environment do
  queue %Q{# 来到部署目录
    cd "#{settings.deploy_to!}" || (
      echo "错误：尚未建立."
      echo "该路径 '#{settings.deploy_to!}' 无法访问."
      echo "你可能需要先运行 mina setup."
      false
    ) || exit 15

    # 检查发布路径
    if [ ! -d "#{settings.releases_path!}" ]; then
      echo "错误：尚未建立."
      echo "该路径 '#{settings.releases_path!}' 无法访问."
      echo "你可能需要先运行 mina setup."
      exit 16
    fi

    # 检查锁定文件
    if [ -e "#{settings.lock_file!}" ]; then
      echo "错误：部署正在进行."
      echo "发现锁定文件 '#{settings.lock_file!}'."
      echo "如果确定没有其他部署正在进行，请先删除该锁定文件."
      exit 17
    fi

    # 确定上一版本路径 $previous_path 及其他变量
    [ -h "#{settings.current_path!}" ] && [ -d "#{settings.current_path!}" ] && previous_path=$(cd "#{settings.current_path!}" >/dev/null && pwd -LP)
    build_path="./tmp/build-`date +%s`$RANDOM"
    version=$((`cat "#{settings.deploy_to!}/last_version" 2>/dev/null`+1))
    release_path="#{settings.releases_path!}/$version"

    # 智能检测
    if [ -e "$build_path" ]; then
      echo "错误：该路径已存在."
      exit 18
    fi

    # Bootstrap script (in deployer)
    (
      echo "-----> 创建一个临时生成路径"
      #{echo_cmd %[touch "#{settings.lock_file!}"]} &&
      #{echo_cmd %[mkdir -p "$build_path"]} &&
      #{echo_cmd %[cd "$build_path"]} &&
      (
  }

  invoke :'git:clone'                   # 从git拷贝项目
  invoke :'deploy:link_shared_paths'    # 编译该路径下的文件
  invoke :'bundle:install'              # bundle install
  invoke :'rails:assets_precompile'     # 预编译资源文件
  invoke :'rails:db_migrate'            # 数据库迁移

  queue %Q{
      )
    ) &&

    #
    # 重命名当前版本的生成路径并添加快捷方式文件夹(current)'
    (
      echo "-----> 生成完成"
      echo "-----> 已移至 $release_path"
      #{echo_cmd %[mv "$build_path" "$release_path"]} &&

      echo "-----> 更新 #{settings.current_path!} 路径快捷方式" &&
      #{echo_cmd %[ln -nfs "$release_path" "#{settings.current_path!}"]}
    ) &&

    # ============================
    # === 启动服务 => (in deployer)
    (
      echo "-----> 启动中..."
      touch #{deploy_to}/tmp/restart.txt
      #{echo_cmd %[cd "$release_path"]}
  }


  queue %Q{
    ) &&

    # ============================
    # === 完成并解锁
    (
      rm -f "#{settings.lock_file!}"
      echo "$version" > "./last_version"
      echo "-----> 恭喜您，已成功部署！ 已部署版本 v$version"
    ) ||

    # ============================
    # === 部署失败
    (
      echo "错误：部署失败."

  }

  queue %Q{

      echo "-----> 清理生成目录"
      [ -e "$build_path" ] && (
        #{echo_cmd %[rm -rf "$build_path"]}
      )
      [ -e "$release_path" ] && (
        echo "删除生成文件"
        #{echo_cmd %[rm -rf "$release_path"]}
      )
      (
        echo "解除current文件夹快捷方式"
        [ -n "$previous_path" ] && #{echo_cmd %[ln -nfs "$previous_path" "#{settings.current_path!}"]}
      )

      # 解锁
      #{echo_cmd %[rm -f "#{settings.lock_file!}"]}
      echo "完成"
      exit 19
    )
  }
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

