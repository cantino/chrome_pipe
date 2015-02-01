#!/usr/bin/env ruby

[128, 48, 38, 19, 16].each do |size|
  system "convert -resize #{size}x#{size}! icon.png icon-#{size}x#{size}.png"
  system "convert -resize #{size}x#{size}! -unsharp 1.5x1+0.7+0.02 icon.png icon-#{size}x#{size}-unsharp.png"
end
