#!/bin/zsh

set -euo pipefail

if (( $# == 0 )); then
  print -u2 "用法: scripts/prepare-livp.sh <photo.livp> [...]"
  exit 1
fi

for livp_file in "$@"; do
  if [[ ! -f "$livp_file" || "${livp_file:e:l}" != "livp" ]]; then
    print -u2 "不是有效的 LIVP 文件: $livp_file"
    exit 1
  fi

  output_dir="${livp_file:h}"
  output_name="${livp_file:t:r}"
  work_dir=$(mktemp -d /private/tmp/blog-livp.XXXXXX)
  preview_dir="$work_dir/preview"
  mkdir -p "$preview_dir"

  unzip -q "$livp_file" -d "$work_dir"

  if [[ ! -f "$work_dir/livephoto_temp.heic" || ! -f "$work_dir/livephoto_temp.mov" ]]; then
    print -u2 "LIVP 中未找到 livephoto_temp.heic 和 livephoto_temp.mov: $livp_file"
    rm -rf -- "$work_dir"
    exit 1
  fi

  qlmanage -t -s 2400 -o "$preview_dir" "$work_dir/livephoto_temp.heic" >/dev/null
  sips -s format jpeg -s formatOptions high \
    "$preview_dir/livephoto_temp.heic.png" \
    --out "$output_dir/$output_name.jpg" >/dev/null

  /usr/bin/avconvert \
    --source "$work_dir/livephoto_temp.mov" \
    --preset PresetAppleM4V720pHD \
    --output "$work_dir/livephoto_temp.m4v" \
    --replace >/dev/null
  mv "$work_dir/livephoto_temp.m4v" "$output_dir/$output_name.mp4"

  rm -rf -- "$work_dir"
  print "已生成: $output_dir/$output_name.jpg"
  print "已生成: $output_dir/$output_name.mp4"
done
