#!/bin/bash
app_install_dir="$(dirname $(readlink -f $0))"
current_date=$(date +"%Y-%m-%d")

git_repos_dir="$app_install_dir/flutter_linux_desktop_version"
app_file="flutter_linux_desktop"

echo "git_repos_dir: $git_repos_dir"
echo "app_file: $app_file"

cd $git_repos_dir
./$app_file 