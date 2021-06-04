vfile=$1

ls $vfile

FINGERPRINT_XML=$vfile.fingerprint.xml
FINGERPRINT_TXT=$vfile.fingerprint.log
FINGERPRINT_CSV=$vfile.fingerprint.csv



if [ ! -e "$FINGERPRINT_CSV" ]; then
 if [ ! -e "$FINGERPRINT_TXT" ]; then
  if [ ! -e "$FINGERPRINT_XML" ]; then
	echo "obtaining XML signature by segment for video file"
	ffmpeg -i $vfile -vf signature=format=xml:filename="$FINGERPRINT_XML" -map 0:v -f null -
  fi

  echo "XML signature for video file:"
  ls -l $FINGERPRINT_XML

	echo "flattening XML signature"
	xmlstarlet sel -N "m=urn:mpeg:mpeg7:schema:2001" -t -m "m:Mpeg7/m:DescriptionUnit/m:Descriptor/m:VideoSignatureRegion/m:VSVideoSegment" -v m:StartFrameOfSegment -o ':' -v m:EndFrameOfSegment -o ':' -m m:BagOfWords -v "translate(.,' ','')" -o ':' -b -n "${FINGERPRINT_XML}" > "$FINGERPRINT_TXT";
 fi

 echo "flattened XML signature:"
 ls -l $FINGERPRINT_TXT

	#cat $FINGERPRINT_TXT | cut -d ':' -f3-9 | awk '{cmd="echo "$1" | md5";cmd | getline x;close(cmd);print x;}' > $vfile.fingerprint.md5

	#cat $FINGERPRINT_TXT | cut -d ':' -f1-2 > $vfile.fingerprint.frames

	#paste $vfile.fingerprint.frames $vfile.fingerprint.md5 | tr ':' '\t' > $FINGERPRINT_CSV

	#rm $vfile.fingerprint.md5
	#rm $vfile.fingerprint.frames

	echo "compressing flat signature to spreadsheet"
	cat $FINGERPRINT_TXT | awk -F':' '{cmd="echo "$1" | md5";cmd | getline x;close(cmd);print $1 "\t" $2 "\t" x;}' > $FINGERPRINT_CSV
fi

echo "compressed signature spreadsheet:"
ls -l$FINGERPRINT_CSV


if [ ! -e "$vfile.ffmpeg.sh" ]; then
	echo "matching newest spreadsheet to the rest to build clip-generator script"	
	grep "\t" *.fingerprint.csv | tr ':' ' ' | awk -v fpfx="$vfile" '{print $2 " " $3 " " index($1,fpfx) "_" $1 " " $4}' | sort -r -k4 -k3 | uniq -c -f2 | tr ':' ' ' | uniq -c -f4 | sort -rh | tr -s ' ' | grep "^[[:space:]]2.*1_" | awk '{print "ffmpeg -ss " $3/30 " -i " substr($5,3,index($5,".fingerprint")-3) " -to " $4/30-$3/30 " -n -vcodec copy -acodec copy " $6 "_" substr($5,3,index($5,".fingerprint")-3) }' > $vfile.ffmpeg.sh 
#grep "\t" *.fingerprint.csv | tr ':' ' ' | sort -k4 | awk '{print $2 " " $3 " " $1 ":" $4}' | uniq -c -f2 | tr ':' ' ' | uniq -c -f4 | sort -rh | tr -s ' ' | grep "^[[:space:]]2" | awk '{print "ffmpeg -ss " $3/30 " -i " substr($5,0,index($5,".fingerprint")-1) " -to " $4/30-$3/30 " -n -vcodec copy -acodec copy " $6 "_" substr($5,0,index($5,".fingerprint")-1) }' > $filename.ffmpeg.sh
fi

echo "clip generator script:"
ls $vfile.ffmpeg.sh

echo "generating clips"
bash $vfile.ffmpeg.sh

echo "cleaning up"
rm $vfile.ffmpeg.sh
