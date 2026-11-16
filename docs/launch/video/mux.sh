#!/bin/sh
# ./mux.sh out.mp4   (needs ffmpeg, frames/f%05d.png, assets/vo.mp3, assets/music.mp3)
# Same mix as mux.swift: narration at full level, music bed at 0.16, lifted to 0.30 after the last line, faded out.
set -e
ffmpeg -v error -y -framerate 30 -i frames/f%05d.png -i assets/vo.mp3 -i assets/music.mp3 -filter_complex \
"[2:a]atrim=0:53.5,volume=eval=frame:volume='if(lt(t,1.2),0.16*t/1.2,if(lt(t,50.44),0.16,if(lt(t,51.04),0.16+0.14*(t-50.44)/0.6,if(lt(t,51.2),0.30,max(0,0.30*(53.5-t)/2.3)))))'[m];[1:a]aresample=48000,apad[v];[m]aresample=48000[m2];[v][m2]amix=inputs=2:duration=shortest:normalize=0,aformat=channel_layouts=stereo[a]" \
-map 0:v -map "[a]" -c:v libx264 -preset slow -crf 17 -pix_fmt yuv420p -profile:v high -r 30 -movflags +faststart -c:a aac -b:a 192k -t 53.5 "${1:-out.mp4}"
