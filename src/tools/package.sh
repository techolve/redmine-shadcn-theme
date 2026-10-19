#!/bin/sh
# Release 用の zip を作る（Redmine の themes/ に展開するだけで使える形）
#   npm run package → .dist/redmine-shadcn-theme-v<version>.zip（中身は shadcn/ フォルダ）
set -eu

cd "$(dirname "$0")/../.."
version=$(node -p "require('./package.json').version")
work=.dist/work
out=.dist/redmine-shadcn-theme-v$version.zip

rm -rf "$work" "$out"
mkdir -p "$work/shadcn"
cp -R stylesheets javascripts images LICENSE README.md "$work/shadcn/"
(cd "$work" && zip -qr -X "../$(basename "$out")" shadcn)
rm -rf "$work"
echo "$out"
