filename=$1

ls $filename

FINGERPRINT_XML=$filename.fingerprint.xml
FINGERPRINT_TXT=$filename.fingerprint.log
FINGERPRINT_CSV=$filename.fingerprint.csv


if [ ! -e "$FINGERPRINT_XML" ]; then
	ffmpeg -i $filename -vf signature=format=xml:filename="$FINGERPRINT_XML" -map 0:v -f null -
fi

ls $FINGERPRINT_XML

if [ ! -e "$FINGERPRINT_TXT" ]; then
	xmlstarlet sel -N "m=urn:mpeg:mpeg7:schema:2001" -t -m "m:Mpeg7/m:DescriptionUnit/m:Descriptor/m:VideoSignatureRegion/m:VSVideoSegment" -v m:StartFrameOfSegment -o ':' -v m:EndFrameOfSegment -o ':' -m m:BagOfWords -v "translate(.,' ','')" -o ':' -b -n "${FINGERPRINT_XML}" > "$FINGERPRINT_TXT";
fi

ls $FINGERPRINT_TXT

if [ ! -e "$FINGERPRINT_CSV" ]; then
	cat $FINGERPRINT_TXT | cut -d ':' -f3-9 | awk '{cmd="echo "$1" | md5";cmd | getline x;close(cmd);print x;}' > $filename.fingerprint.md5

	cat $FINGERPRINT_TXT | cut -d ':' -f1-2 > $filename.fingerprint.frames

	paste $filename.fingerprint.frames $filename.fingerprint.md5 | tr ':' '\t' > $FINGERPRINT_CSV

	rm $filename.fingerprint.md5
	rm $filename.fingerprint.frames
fi

ls $FINGERPRINT_CSV


if [ ! -e "$filename.ffmpeg.sh" ]; then
	grep "\t" *.fingerprint.csv | tr ':' ' ' | sort -k4 | awk '{print $2 " " $3 " " $1 ":" $4}' | uniq -c -f2 | tr ':' ' ' | uniq -c -f4 | sort -rh | tr -s ' ' | grep "^[[:space:]]2" | awk '{print "ffmpeg -ss " $3/30 " -i " substr($5,0,index($5,".fingerprint")-1) " -to " $4/30-$3/30 " -n -vcodec copy -acodec copy " $6 "_" substr($5,0,index($5,".fingerprint")-1) }' > $filename.ffmpeg.sh
fi

ls $filename.ffmpeg.sh
bash $filename.ffmpeg.sh
rm $filename.ffmpeg.sh
