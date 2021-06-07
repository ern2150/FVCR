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

 echo "compressing flat signature to spreadsheet"
 cat $FINGERPRINT_TXT | awk -F':' '{cmd="echo "$1" | md5";cmd | getline x;close(cmd);print $1 "\t" $2 "\t" x;}' > $FINGERPRINT_CSV
fi

echo "compressed signature spreadsheet:"
ls -l$FINGERPRINT_CSV


#fingerprints generating clips has been removed, should kinda be its own thing

#code that will know how this new video file affected the existing data might end up here
