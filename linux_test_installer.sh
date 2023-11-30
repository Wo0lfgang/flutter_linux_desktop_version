#!/bin/bash


current_user_id=$(id -u)
shell_file_name=$(basename $0)
shell_file_path=$(readlink -f $0)


install_dir="$(echo ~)/user"
test_dir="$install_dir/test"
current_dir="$(dirname $shell_file_path)"
program_dir="$test_dir/flutter_linux_desktop_version"
caching_dir="$(echo ~)/Documents/train_assist"

startup_bin="$install_dir/flutter_linux_desktop"
startup_app="$test_dir/flutter_linux_desktop.sh"
startup_src="$program_dir/flutter_linux_desktop.sh"

install_bin="$install_dir/linux_test_installer"
install_app="$test_dir/linux_test_installer.sh"
install_src="$program_dir/linux_test_installer.sh"

install_bin

log_dir="$install_dir/log"
date=$(date +%Y%m%d)
log_src="$log_dir/$date.log"

channel_name="main"
latest_version="unset"
current_version="unset"

VERSION_REGEX="^[0-9]+\.[0-9]+\.[0-9]+$"
VERSION_REGEX_RELEASE="^[0-9]+\.[0-9]+\.[0-9]+-[0-9]{8}$"

DESKTOP_FILE_PATH="/usr/share/applications/test_client.desktop"
DESKTOP_FILE="\
[Desktop Entry]\n\
Type=Application\n\
Name=test\n\
GenericName=test\n\
Exec="$startup_app" %f\n\
Terminal=true\n\
Catagories=X-Application;\n\
"

## 函数
## print_help_message 打印帮助信息
## log_command 输入日志
## get_current_version 开始获取当前版本信息
## get-latest-version 获取最新版本
## _assert_repos_exit 库是否存在
## _clean_installed 卸载
## install 全新安装
## restart 重启程序
## upgrade 更新





# 打印帮助信息
print_help_message()
{
    echo "
    OPTIONS: \n \
    [ --get-current-version]\t : 获取当前版本信息
    [ --get-latest-version]\t : 获取最新版本信息
    [ --install]\t : 安装
    [ --restart]\t : 重新启动
    [ --upgrade]\t : 更新
    [ --create-desktop]\t : 创建桌面快捷
    "
}


# 输入日志
log_command()
{
    echo "$@"
    if ! [ -d "$log_dir"]; then
        mkdir -p $log_dir
    fi
    date=$(date "+%Y-%m-%d %H:%M%S.%3N")
    echo "$date : $@" >> "$log_scr" 
}

# 仓库是否存在
_assert_repos_exit()
{
    log_command "开始判断仓库是否存在"
    if ! [ -d "$program_dir" ] || ! [ -d "$program_dir/.git" ]; then
    log_command "应用程序未安装，请先使用 --install 安装!"
    exit 1
  fi
}

# 卸载
_clean_installed()
{
    log_command "开始卸载"

    log_command "正在清理旧的安装文件: $test_dir"
    if [ -d "$test_dir" ]; then
    rm -rf $test_dir
    fi
}

# 开始获取当前版本信息
get_current_version()
{
    log_command "开始获取当前版本信息"

    _assert_repos_exit
    
    current_version="unset"

    cd $program_dir

    current_version=$(git describe --tags | awk -F/ '{print $3}' | awk -F'-' '{print $1}')
    log_command "git describe 当前版本号： $current_version"
    if echo $current_version | grep -qE $VERSION_REGEX; then
        return
    fi

    current_version=$(git tag --no-contains | sort -t "-" -k 1,1V -k 2,2n | awk 'END{print}')
    log_command "git tag 当前版本号： $current_version"
    if echo $current_version | grep -qE $VERSION_REGEX; then
      return
    fi

}

# 获取最新版本
get-latest-version()
{
    log_command "开始获取最新版本"

    _assert_repos_exit

    latest_version="unset"

    cd $program_dir

    latest_version=$(git ls-remote --tags --refs origin | awk -F/ '{print $3}' | sort -t "-" -k 1,1V -k 2,2n | awk 'END{print}')
    log_command "远端最新版本1：$latest_version"
    if echo $latest_version | grep -qE $VERSION_REGEX; then
      return
    fi
    if echo $latest_version | grep -qE $VERSION_REGEX_RELEASE; then
    log_command "远端最新版本2：$latest_version"
      return
    fi
    
    log_command "未能找到最新版本号"
    latest_version="unset"
}

# 全新安装
install()
{
    log_command "开始安装"

    log_command "安装程序已启动, 安装目录为: $test_dir, 请稍后..."

    _clean_installed

    log_command "正在创建程序安装目录: $test_dir"
    if ! [ -d "$test_dir" ]; then
        mkdir -p $test_dir
    fi

    cd $test_dir

    git clone https://github.com/Wo0lfgang/flutter_linux_desktop_version.git
    git config --global --add safe.directory $program_dir

    log_command "校验下载内容: $program_dir"

    get_current_version

    if [ "$current_version" != "unset" ]; then
        log_command "版本下载完成: $current_version!"
    else
        log_command "校验失败!"
    exit 1
    fi

    log_command "正在切换版本: $current_version!"
    git reset --hard $current_version
  
    log_command "正在复制脚本: $install_src"
    cp -f $install_src $install_app
  
    log_command "正在复制脚本: $startup_src"
    cp -f $startup_src $startup_app
  
    log_command "创建快捷方式: $install_bin"
    ln -s -f $install_app $install_bin
    chmod +x $install_app
  
    log_command "创建快捷方式: $startup_bin"
    ln -s -f $startup_app $startup_bin
    chmod +x $startup_app
  
    hash -r

    log_command "正在校验结果: $test_dir"

    if [ "$current_version" != "unset" ]; then
        log_command "成功安装版本: $current_version!"
        log_command "安装完成!"
    else
        log_command "安装失败!"
        exit 1
    fi
}

# 重启程序
restart()
{
    log_command "开始重启程序"

    _assert_repos_exit

    pkill -f "$startup_app"

    sleep 3

    log_command "正在启动 ..."
    nohup "$startup_app"&
}

# 更新
upgrade()
{

  log_command "开始升级安装"

  _assert_repos_exist

    get_latest_version 
  get_current_version 


if [ "$current_version" != "unset" ]; then
    log_command "当前已安装版本: $current_version!"
  else
    log_command "读取当前已安装版本失败!"
    exit 1
  fi

  if [ "$latest_version" != "unset" ]; then
    log_command "服务器最新版本: $latest_version!"
  else
    log_command "读取服务器最新版本失败!"
    exit 1
  fi

  if [ "$current_version" = "$latest_version" ]; then
    log_command "已经是最新版本!"
  else
    cd $program_dir

    log_command "正在清理程序: $channel_name/$current_version!"
    local current_branch=$(git branch | grep \* | cut -d ' ' -f2)
    git checkout $current_branch -f
    git clean -xfd

    log_command "正在下载程序: $channel_name/$latest_version!"

    git pull

    log_command "正在切换版本: $latest_version!"
    git reset --hard $latest_version

    log_command "正在复制脚本: $install_src"
    cp -f $install_src $install_app

    log_command "正在复制脚本: $startup_src"
    cp -f $startup_src $startup_app

    log_command "正在校验结果: $ntsport_dir"

    get_current_version $channel_name

    if [ "$current_version" != "unset" ]; then
      log_command "已成功安装版本: $current_version!"
      log_command "升级完成!"
    else
      log_command "升级失败!"
      exit 1
    fi
  fi
}


# 分析启动参数
ARGS=$(getopt -a -o b:k:rhv -l get-current-version,current-version,get-latest-version,restart,latest-version,get-current-channel,current-channel,create-desktop,remove-desktop,uninstall,install,upgrade,version,help -- "$@")
if [ "$?" != "0" ]; then
  print_help_messages
  exit 1
fi
eval set -- "$ARGS"

channel_name="unset"        # 分支名字
intent_name="unset"         # 用户意图
process_id="unset"          # 杀死进程
launch="unset"              # 启动程序

while :
do
  case "$1" in
    --get-current-channel)
      intent_name='get-current-channel'
      ;;
      
    --current-channel)
      intent_name='get-current-channel'
      ;;

    --get-current-version)
      intent_name='get-current-version'
      ;;
      
    --current-version)
      intent_name='get-current-version'
      ;;

    --get-latest-version)
      intent_name='get-latest-version'
      ;;

    --latest-version)
      intent_name='get-latest-version'
      ;;

    --create-desktop)
      intent_name='create-desktop'
      ;;

    --remove-desktop)
      intent_name='remove-desktop'
      ;;

    --uninstall)
      intent_name='uninstall'
      ;;

    --install)
      intent_name='install'
      ;;

    --upgrade)
      intent_name='upgrade'
      ;;

    --restart)
      intent_name='restart'
      ;;

    --version|-v)
      intent_name='version'
      ;;

    --help|-h)
      intent_name='help'
      ;;

    -b)
      channel_name=$2
      shift
      ;;

    -k)
      process_id=$2
      shift
      ;;

    -r)
      launch='true'
      ;;

    --)
      shift
      break
      ;;
  esac
shift
done


 [ --get-current-version]\t : 获取当前版本信息
    [ --get-latest-version]\t : 获取最新版本信息
    [ --install]\t : 安装
    [ --restart]\t : 重新启动
    [ --upgrade]\t : 更新
    [ --create-desktop]\t : 创建桌面快捷


if [ "$intent_name" = "help" ]; then
    print_help_messages
    exit 0
fi

if [ "$intent_name" = "create-desktop" ] || [ "$intent_name" = "remove-desktop" ]; then
  if [ "$current_user_id" != "0" ] || ! echo ~ | grep -qE "^/home/*"; then
    log_command "创建或删除快捷启动图标时, 请使用: sudo -E 执行脚本!"
    exit 1
  fi

  if [ "$intent_name" = "create-desktop" ]; then
    log_command "创建快捷启动图标: $DESKTOP_FILE_PATH"
    if [ -f $DESKTOP_FILE_PATH ]; then
      rm $DESKTOP_FILE_PATH
    fi

    log_command $DESKTOP_FILE > $DESKTOP_FILE_PATH
    log_command "创建成功!"
    exit 0
  fi

  if [ "$intent_name" = "remove-desktop" ]; then
    log_command "删除快捷启动图标: $DESKTOP_FILE_PATH"
    if [ -f $DESKTOP_FILE_PATH ]; then
      rm $DESKTOP_FILE_PATH
    fi
    log_command "删除成功!"
    exit 0
  fi
elif [ "$current_user_id" = "0" ]; then
  log_command "请不要使用: sudo 执行!"
  exit 1
fi



if [ "$intent_name" = "get-current-version" ]; then
    get_current_version 
  if [ "$current_version" != "unset" ]; then
    log_command "当前版本号为：$current_version"
    exit 0
  else
    log_command "读取当前已安装版本失败!"
    exit 1
  fi
fi

if [ "$intent_name" = "get-latest-version" ]; then
    get_latest_version 
  if [ "$latest_version" != "unset" ]; then
    log_command $latest_version
    exit 0
  else
    log_command "读取服务端最新版本失败!"
    exit 1
  fi
fi

if [ "$intent_name" = "install" ]; then

    install $channel_name


    exit 0
fi

if [ "$intent_name" = "upgrade" ]; then
   
    upgrade $channel_name

    exit 0
fi

if [ "$intent_name" = "restart" ]; then
    
    restart $channel_name

    exit 0
fi

print_help_messages
exit 1
