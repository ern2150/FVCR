Mac bash epoch from custom date format
```
date -j -f '%Y-%M-%d %T' "2020-04-02 20:47:09" "+%s"
```

Log manipulation for relative time
```
sed -n "/starttime/,/endtime/p" filename > snipped-content 
sed -n "/starttime/,/endtime/p" filename | cut -f 1 -d']' | cut -f 2 -d'['  | date -f - +%s | sed 's/$/ \- epochofstarttime/' | bc > snipped-relative
paste snipped-relative snipped-content > snipped-combined
```


Testing a Google Sheets doc for dead links:
```
curl https://docs.google.com/spreadsheets/d/<spreadsheetID>/gviz/tq?tqx=out:csv -s 
  | awk -F "\",\"" '{gsub(/[ ]/,"");print $5 "#" $3}' 
  | grep "http" | awk -F "http" '{print "http" $2}' 
  | while read -r line; do streamlink -l error $line; done
```
You can attach that CSV conversion to any publicly-readable google sheets url.  This gives you text where fields are contained in double quotes and separated by commas, so you need to know the boundary string to split those fields (in case there's a comma inside the field itself).

This particular sheet has a video link in Column 5, and a video title in Column 3.  I decided to hash them together (while removing pesky whitespace) so later processes would ignore it and I could still retrieve the title when needed.

I then lazily grab the first url I see on each line and send it to `streamlink` which is a utility meant to watch various streaming video sources in VLC for example.  It also does a good job informing me of a page that _should_ have video streams, but _doesn't_ (and yet returns a 200 instead of an actual error code).  It does this in a "shallow" manner by just telling me what media streams are available, without actually trying to download them.

From this output I can further filter for "No playable streams found" to find the easy missing sources.

It's by no means perfect -- streamlink won't touch "protected" videos (which usually means there's NSFW content and you need to be signed into a streaming service before you can tell if it has any actual video), and it can't process archive.org top-level urls.


Video match
-----------
#### FUN

Based on some [adventures in perceptual hashing](https://github.com/mediamicroservices/mm/blob/master/searchfingerprint#L77-L78), generated a binary string that is a thumbprint of a clip that is common to multiple epoch timestamps of broadcasts:
```
grep -n ":000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000:000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000:000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000:" *.log | cut -d ':' -f1 | uniq -c
   4 1620176244.mp4.fingerprint.log
   2 1620609733.mp4.fingerprint.log
   7 1620781065.mp4.fingerprint.log
   5 1620954040.mp4.fingerprint.log
   4 1621385842.mp4.fingerprint.log
   4 1621560636.mp4.fingerprint.log
   5 1621819763.mp4.fingerprint.log
   4 1621990489.mp4.fingerprint.log
   2 1622163701.mp4.fingerprint.log
   4 1622424588.mp4.fingerprint.log
```   
```
ffmpeg -i ../20210501/1620003657.031052.38r2020ENDr.480p.mp4 -i 102420.1620781065-002.mkv -filter_complex signature=detectmode=full:nb_inputs=2 -f null -
ffmpeg version 4.4 Copyright (c) 2000-2021 the FFmpeg developers
  built with Apple LLVM version 10.0.0 (clang-1000.10.44.4)
  configuration: --prefix=/usr/local/Cellar/ffmpeg/4.4_1 --enable-shared --enable-pthreads --enable-version3 --cc=clang --host-cflags= --host-ldflags= --enable-ffplay --enable-gnutls --enable-gpl --enable-libaom --enable-libbluray --enable-libdav1d --enable-libmp3lame --enable-libopus --enable-librav1e --enable-librubberband --enable-libsnappy --enable-libsrt --enable-libtesseract --enable-libtheora --enable-libvidstab --enable-libvorbis --enable-libvpx --enable-libwebp --enable-libx264 --enable-libx265 --enable-libxml2 --enable-libxvid --enable-lzma --enable-libfontconfig --enable-libfreetype --enable-frei0r --enable-libass --enable-libopencore-amrnb --enable-libopencore-amrwb --enable-libopenjpeg --enable-libspeex --enable-libsoxr --enable-libzmq --enable-libzimg --disable-libjack --disable-indev=jack --enable-avresample --enable-videotoolbox
  libavutil      56. 70.100 / 56. 70.100
  libavcodec     58.134.100 / 58.134.100
  libavformat    58. 76.100 / 58. 76.100
  libavdevice    58. 13.100 / 58. 13.100
  libavfilter     7.110.100 /  7.110.100
  libavresample   4.  0.  0 /  4.  0.  0
  libswscale      5.  9.100 /  5.  9.100
  libswresample   3.  9.100 /  3.  9.100
  libpostproc    55.  9.100 / 55.  9.100
Input #0, mpegts, from '../20210501/1620003657.031052.38r2020ENDr.480p.mp4':
  Duration: 03:10:52.89, start: 65.911000, bitrate: 5329 kb/s
  Program 1 
  Stream #0:0[0x100]: Audio: aac (LC) ([15][0][0][0] / 0x000F), 48000 Hz, stereo, fltp, 162 kb/s
  Stream #0:1[0x101]: Video: h264 (High) ([27][0][0][0] / 0x001B), yuv420p(progressive), 852x480 [SAR 1:1 DAR 71:40], 30 fps, 30 tbr, 90k tbn, 60 tbc
  Stream #0:2[0x102]: Data: timed_id3 (ID3  / 0x20334449)
Input #1, matroska,webm, from '102420.1620781065-002.mkv':
  Metadata:
    encoder         : libebml v1.3.6 + libmatroska v1.4.9
    creation_time   : 2021-06-01T16:15:13.000000Z
  Duration: 00:00:08.10, start: 0.100000, bitrate: 5145 kb/s
  Stream #1:0: Audio: aac (LC), 48000 Hz, stereo, fltp (default)
    Metadata:
      BPS-eng         : 160212
      DURATION-eng    : 00:00:07.999000000
      NUMBER_OF_FRAMES-eng: 375
      NUMBER_OF_BYTES-eng: 160192
      _STATISTICS_WRITING_APP-eng: mkvmerge v24.0.0 ('Beyond The Pale') 64-bit
      _STATISTICS_WRITING_DATE_UTC-eng: 2021-06-01 16:15:13
      _STATISTICS_TAGS-eng: BPS DURATION NUMBER_OF_FRAMES NUMBER_OF_BYTES
  Stream #1:1: Video: h264 (High), yuv420p(progressive), 852x480 [SAR 1:1 DAR 71:40], 30.30 fps, 30.30 tbr, 1k tbn, 60 tbc (default)
    Metadata:
      BPS-eng         : 5038943
      DURATION-eng    : 00:00:07.999000000
      NUMBER_OF_FRAMES-eng: 240
      NUMBER_OF_BYTES-eng: 5038314
      _STATISTICS_WRITING_APP-eng: mkvmerge v24.0.0 ('Beyond The Pale') 64-bit
      _STATISTICS_WRITING_DATE_UTC-eng: 2021-06-01 16:15:13
      _STATISTICS_TAGS-eng: BPS DURATION NUMBER_OF_FRAMES NUMBER_OF_BYTES
Stream mapping:
  Stream #0:1 (h264) -> signature:in0 (graph 0)
  Stream #1:1 (h264) -> signature:in1 (graph 0)
  signature (graph 0) -> Stream #0:0 (wrapped_avframe)
  Stream #1:0 -> #0:1 (aac (native) -> pcm_s16le (native))
Press [q] to stop, [?] for help
Output #0, null, to 'pipe:':
  Metadata:
    encoder         : Lavf58.76.100
  Stream #0:0: Video: wrapped_avframe, yuv420p(progressive), 852x480 [SAR 1:1 DAR 71:40], q=2-31, 200 kb/s, 30 fps, 30 tbn (default)
    Metadata:
      encoder         : Lavc58.134.100 wrapped_avframe
  Stream #0:1: Audio: pcm_s16le, 48000 Hz, stereo, s16, 1536 kb/s (default)
    Metadata:
      BPS-eng         : 160212
      DURATION-eng    : 00:00:07.999000000
      NUMBER_OF_FRAMES-eng: 375
      NUMBER_OF_BYTES-eng: 160192
      _STATISTICS_WRITING_APP-eng: mkvmerge v24.0.0 ('Beyond The Pale') 64-bit
      _STATISTICS_WRITING_DATE_UTC-eng: 2021-06-01 16:15:13
      _STATISTICS_TAGS-eng: BPS DURATION NUMBER_OF_FRAMES NUMBER_OF_BYTES
      encoder         : Lavc58.134.100 pcm_s16le
[Parsed_signature_0 @ 0x7fc761575780] matching of video 0 at 9095.634333 and 1 at 7.501000, 1413 frames matching
frame=343557 fps=593 q=-0.0 Lsize=N/A time=03:10:51.90 bitrate=N/A speed=19.8x    
video:179831kB audio:1500kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: unknown
```
