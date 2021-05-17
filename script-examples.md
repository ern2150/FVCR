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
