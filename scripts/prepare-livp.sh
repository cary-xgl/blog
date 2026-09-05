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

  image_file=$(find "$work_dir" -type f \( \
    -iname "*.heic" -o -iname "*.jpg" -o -iname "*.jpeg" \
  \) -print -quit)
  video_file=$(find "$work_dir" -type f -iname "*.mov" -print -quit)

  if [[ -z "$image_file" || -z "$video_file" ]]; then
    print -u2 "LIVP 中未找到 HEIC/JPG 图片或 MOV 视频: $livp_file"
    rm -rf -- "$work_dir"
    exit 1
  fi

  image_type=$(file -b --mime-type "$image_file")
  case "$image_type" in
    image/jpeg)
      cp "$image_file" "$output_dir/$output_name.jpg"
      ;;
    image/heic|image/heif)
      qlmanage -t -s 2400 -o "$preview_dir" "$image_file" >/dev/null
      sips -s format jpeg -s formatOptions high \
        "$preview_dir/${image_file:t}.png" \
        --out "$output_dir/$output_name.jpg" >/dev/null
      ;;
    *)
      print -u2 "LIVP 中的图片格式不受支持 ($image_type): $livp_file"
      rm -rf -- "$work_dir"
      exit 1
      ;;
  esac

  /usr/bin/avconvert \
    --source "$video_file" \
    --preset PresetAppleM4V720pHD \
    --output "$work_dir/livephoto_temp.m4v" \
    --replace >/dev/null
  mv "$work_dir/livephoto_temp.m4v" "$output_dir/$output_name.mp4"

  rm -rf -- "$work_dir"
  print "已生成: $output_dir/$output_name.jpg"
  print "已生成: $output_dir/$output_name.mp4"
done
