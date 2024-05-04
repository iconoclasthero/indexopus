#!/bin/bash
# nb: the swp file that editscript relies on is provided by nano
# opusbook4ka is an external dependency

trap '{ breakout; exit 1; }' INT
shopt -s extglob nullglob
scriptpath="$(realpath $0)"
script="${scriptpath##*\/}"
pidfile="/tmp/.opus.book.pids"
threads=4
mediaext="*.@(flac|mp3|MP3|wav|m4?|ogg|MP4|mp4|wma)"
filtercomplex="compand=attacks=0:decays=0.12:points=-70/-900|-40/-90|-35/-37|-21/-18|1/-1|20/-1:soft-knee=0.03:gain=1.00:volume=-90, firequalizer=gain_entry='entry(0,-99);entry(140,0);entry(1000,0);entry(8000,1);entry(10500,4);entry(12000,5);entry(14500,-4);entry(19000,-20)', volume=1.0"
stamp="$(date +%s)"
bold="$(tput bold)"
red="$(tput setaf 9)"
relipsis="$red..."
tput0="$(tput sgr0)"
tmp="/tmp/opus.book.4-$stamp"

editscript(){
  local scriptpath script path swp; scriptpath=$(realpath "$0" 2>/dev/null); script="${scriptpath##*/}"; path="${scriptpath%/*}"; swp="$path/.$script.swp"
     [[ ! -e "$swp" ]] && (/usr/bin/nano "$scriptpath") && exit
     printf "\n%s is already being edited.\n%s exists; try fg or look in another window.\n" "$scriptpath" "$swp"; exit ;}

pause(){ read -rp "$*" ; }

ffmpegs(){
   ffmpeg -n -nostdin -hide_banner -loglevel error -stats -i "$1" -filter_complex "$filtercomplex" -c:a libopus -b:a 17k -frame_duration:a 60 "${1%.*}.opus" ; }

ffmpeg2(){
 local startfile
  touch "$tmp"
  for startfile in ${mediaext}
    do
      file="${startfile%.*}"
      opusfile="$file.opus"
     [[ "${outputarray[@]}" != *"$file"* ]] && outputarray+=("$file") #&& echo "$file"
     outputfiles="$(<"$tmp")"
     [[ "$outputfiles" != *"$file"* ]] && echo "${relipsis}Converting $file$tput0" |tee -a "$tmp"

      readarray -t ffoutput < <(ffmpeg -n -nostdin -hide_banner -loglevel error -stats -i "$startfile" -filter_complex "$filtercomplex" -c:a libopus -b:a 17k -frame_duration:a 60 -ar 24k "$opusfile" 2>&1 >/dev/null)

# hmmm with the 2>&1 >/dev/null, I'm guessing that this is not going to work as a test anymore
      erfile="${ffoutput[0]}"; erfile="${erfile%%=*}"
      if [[ "$erfile" != "size" ]] && [[ "$erfile" != *already\ exists.\ Exiting* ]]
        then
          printf '%s\n%s\n' "${ffoutput[@]}" "Error: exiting."
          exit 1
       fi
    done ; }


checkdur(){
  local m4as m4bs opuss mp3s checkdurexts
  checkdurexts='@(m4a|m4b|mp3|opus)'
  m4as=(*m4a)
  m4bs=(*m4b)
  opuss=(*opus)
  mp3s=(*mp3)

if [[ "$1" = $checkdurexts ]]
  then
  find -type f -iname "*.$1" -print0 | xargs -0 mplayer -vo dummy -ao dummy -identify 2>/dev/null |
    perl -nle '/ID_LENGTH=([0-9\.]+)/ && ($t +=$1) && printf "%02d:%02d:%02d\n",$t/3600,$t/60%60,$t%60' |
    tail -n 1
elif [[ "$1" = *.$checkdurexts ]]
  then
  printf '%s%s  %s\n%s' "$red" "$(mplayer -vo dummy -ao dummy -identify "$1" 2>/dev/null | perl -nle '/ID_LENGTH=([0-9\.]+)/ && ($t +=$1) && printf "%02d:%02d:%02d\n",$t/3600,$t/60%60,$t%60' | tail -n 1)" "$1" "$tput0"
else
    printf '\n%sDuration(s):%s\n' "$bold" "$tput0"
    [[ "${#m4as[@]}" -gt 0 ]] &&
      printf '%s %s%s%s %s%s\n' "$bold" "$red" "$(    find -type f -iname "*.m4a" -print0 | xargs -0 mplayer -vo dummy -ao dummy -identify 2>/dev/null | perl -nle '/ID_LENGTH=([0-9\.]+)/ && ($t +=$1) && printf "%02d:%02d:%02d\n",$t/3600,$t/60%60,$t%60' | tail -n 1)" "$white"  "${m4as[@]}" "$tput0"
    [[ "${#m4bs[@]}" -gt 0 ]] &&
      printf '%s %s%s%s %s%s\n' "$bold" "$red" "$(    find -type f -iname "*.m4b" -print0 | xargs -0 mplayer -vo dummy -ao dummy -identify 2>/dev/null | perl -nle '/ID_LENGTH=([0-9\.]+)/ && ($t +=$1) && printf "%02d:%02d:%02d\n",$t/3600,$t/60%60,$t%60' | tail -n 1)" "$white" "${m4bs[@]}" "$tput0"
    [[ "${#mp3s[@]}" -gt 0 ]] &&
      printf '%s %s%s%s %s%s\n' "$bold" "$red" "$(    find -type f -iname "*.mp3" -print0 | xargs -0 mplayer -vo dummy -ao dummy -identify 2>/dev/null | perl -nle '/ID_LENGTH=([0-9\.]+)/ && ($t +=$1) && printf "%02d:%02d:%02d\n",$t/3600,$t/60%60,$t%60' | tail -n 1)" "$white" "${mp3s[@]}" "$tput0"
    [[ "${#opuss[@]}" -gt 0 ]] &&
      printf '%s %s%s%s %s%s\n' "$bold" "$red" "$(    find -type f -iname "*.opus" -print0 | xargs -0 mplayer -vo dummy -ao dummy -identify 2>/dev/null | perl -nle '/ID_LENGTH=([0-9\.]+)/ && ($t +=$1) && printf "%02d:%02d:%02d\n",$t/3600,$t/60%60,$t%60' | tail -n 1)" "$white" "${opuss[@]}" "$tput0"
 fi
}
##--> checkdur() <--###########################################################################

stats(){
  if [[ "$file" ]]; then
      printf 'mediaduration %s\n %s' "$file" "$(mediaduration "$file")"
      printf 'mediaduration %s\n %s' "$opusfile" "$(mediaduration "$opusfile")"
  else
    startbitrate="${mediafiles[0]}"
    startbitrate="$(ffprobe -v error -i "$startbitrate" -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1)"
    startbitrate="$(( startbitrate / 1000 )) kB/s"
    opusbitrate="${mediafiles[0]%.*}.opus"
    opusbitrate="$(ffprobe -v error -i "$opusbitrate" -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1)"
    opusbitrate="$(( opusbitrate / 1000 )) kB/s"
    printf '\n\nConverstion statistics:\n'
    printf 'Bit rate for %s: %s\n' "${mediafiles[0]}" "$startbitrate"
    printf 'Bit rate for %s: %s\n' "${mediafiles[0]%.*}.opus" "$opusbitrate"
  fi

  elapsed="$SECONDS"
  elmin="$((elapsed/60))"
  elsec="$((elapsed-elmin*60))"
  printf 'Script runtime: %ss / %s:%s mm:ss\n' "$SECONDS" "$elmin" "$elsec"

  #printf 'Elapsed time: %s m:%s s\n' "$elmin" "$elsec"
  startsize="$(\du -bcs ${mediaext} |tail -1)"
  startsize="${startsize%$'\t'*}"
  startsizehr="$(\du -hcs ${mediaext} |tail -1)"
  startsizehr="${startsizehr%$'\t'*}"
  opussize="$(\du -bcs *opus|tail -1)"
  opussize="${opussize%$'\t'*}"
  opussizehr="$(\du -hcs *opus|tail -1)"
  opussizehr="${opussizehr%$'\t'*}"
  d=$((startsize-opussize))
  r="$((d*100 / startsize))"
  printf 'Initial size (%s) = %s bytes/ %s\n' "$startext" "$startsize" "$startsizehr"
  printf 'Final size (opus) = %s bytes / %s\n' "$opussize" "$opussizehr"
  printf '%s%% file size reduction\n' "$r"
}
##--> stats() <--##############################################################################

breakout(){
  while IFS= read -r pid
   do
     [[ "$pid" = *"$script"* ]] || [[ "$pid" = *ffmpeg* ]] && echo "${pid% pts*}" >> "$pidfile"
  done< <(ps --tty $(tty) Sf)
  opusbook4ka "$pidfile" ; }   # opusbook4ka is a dependency
##--> braekout() <--###########################################################################


###--> Main Code <--###########################################################################
###--> opus.book.4 <--#########################################################################

line="$(printf '%s%*s\n' "$red" "$(tput cols)"|tr ' ' "-")$tput0"
printf '%s%s%s%s%s\n' "$line" "$tput0" "$bold" "$script" "$tput0"

[[ "$1" == @(edit|e|nano|-e|-E) ]] && editscript

mediafiles=( ${mediaext} )


#test for more than one accptable media extension and fail if it finds more than one.
for exts in "${mediafiles[@]}"
  do
    extensions+=( "${exts##*.}" )
  done
(( $(printf '%s\n' "${extensions[@]}"|sort -u|wc -l) > 1 )) &&
  printf '\n%sMore than one type of media file found!\nopus.book.4 cannot be launched from a folder where more than one type of media file is located.\nCorrect and try again.\n%sexit 1\n\n' "$bold" "$tput0" && exit 1

while (( $# > 0 ))
  do
    [[ "$1" = "-h" || "$1" = "--help" ]] && help=true && shift
    [[ "$1" = "-s" || "$1" = "--stats" ]] && statson=true && shift
    [[ "$1" = "-f" || "$1" = "--force" ]] && overwrite=true && shift 	#this doesn't actually change what ffmpeg does yet!
    startfile="$1" && file="$startfile" && opusfile="${file%.*}.opus"								#it's just letting me into the program atm
    shift
  done

if [[ "$startfile" && ! -f "$startfile" && "$startfile" != $mediaext ]] || (( "${#mediafiles[@]}" == 0 ))
  then
  echo "Usage: $0 [-s|--stats] [-f|--force] [-h|--help] <optional filename>"
  echo "Files must be of $mediaext format."
  exit 1
fi

rm /tmp/mytmpfile .opus.book.pids "$pidfile" 2>/dev/null  	# clean any old files that will be in the way
startext=( ${mediaext} ); startext="${startext##*.}"		# define what the starting extension is in dir
filenum="$(ls ${mediaext}|wc -l)"							# how many of those files are there?

[[ "$filenum" -lt "$threads" ]] && threads="$filenum"

if  [[ "$startfile" ]] && [[ -f "$opusfile" ]] && [[ "$overwrite" != true ]]
  then
  printf '\n%s%s%s exists!%s\n   %sexit 1\n\n%s' "$relipsis" "$bold" "$opusfile" "$white" "$tput0"
  echo "$line"
  exit 1
elif [[ "$startfile" ]]
  then
  printf '\n%sConverting %s.\n   Duration: %s%s%s%s\n\n' "$relipsis" "$file" "$tput0" "$bold" "$(ffprobe -i "$file" -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal|  awk -F: '{printf "%d:%d:%.2f\n", $1, $2, $3}')" "$tput0"
  ffmpeg -y -nostdin -hide_banner -loglevel error -stats -i "$file" -filter_complex "$filtercomplex" -c:a libopus -b:a 17k -ar 24k -frame_duration:a 60 "${file%.*}.opus" 
  printf '\n%sDurations:\n%s' "$bold" "$tput0"
  checkdur "$startfile"
  checkdur "$opusfile"
elif (( filenum > 0 ))
  then
#need to add a formal confirm here at some point, but really, who's going to be doing this?
#ffmpeg cannot overwrite here so probably have to exit if the files aren't deleted... further, we could actully compare the opus files that exist to the ones that are going to be converted...but since im not using find here, that probably donesnt matter.
  if [[ "$overwrite" = true ]]
    then
    printf '\n%s%s invoked with --force|-f flag to overwrite existing .opus files.\n' "$red" "$script"
    printf '\n%sConfirm deletion of existing *.opus files prior to starting conversion!%s\n' "$bold" "$tput0"
    printf '\nIt'\''d be great if there was actually a confirm here... your shit'\''s deleted sucker!\n'
    printf 'FWIW, ffmpeg cannot be invoked with -y here because of the way multipe instances race.\n\n'
    rm -i *opus
  fi
  printf '%sDuration of %s %s file(s) to convert: %s%s%s%s%s\n   in: %s%s\n\n' "$relipsis" "$filenum" "$startext" "$tput0" "$bold" "$(mediaduration "$startext")" "$tput0" "$red" "$PWD" "$tput0"
  printf '%sConversion progress:\n%s'  "$relipsis" "$tput0"
  for ((i=0; i<"$threads"; i++))
    do
      ffmpeg2&    # call function to background to convert media files to opus, counter
      sleep 0.5s
    done
  wait  #for the bacground operations to finish up
  echo
  mediaduration #external dependency
else
  # Check if filename is provided
    echo "Usage: $0 [-s|--stats] [-f|--force] <optional filename>"
    exit 1
fi

[[ "$statson" = true ]] && stats

rm /tmp/mytmpfile "$tmp" .opus.book.pids "$pidfile" 2>/dev/null
echo "$line"
exit


#some fun thoughts on parallel:
#<!wait-n> Run up to 5 processes in parallel (bash 4.3): i=0 j=5; for elem in "${array[@]}"; do (( i++ < j )) || wait -n; my_job "$elem" & done; wait
#<ano> iconoclast_hero: (( "$#" )) && nproc=$(nproc) && printf %s\\0 "$@" | xargs -0P"$nproc" -n1 bash -c 'ffmpeg -nostdin -v error -threads 1 -protocol_whitelist file -i "$0" ... "${0}.opus"'
#<ano> iconoclast_hero: if want to be sure ffmpeg converts only local files and doesn't follow other protocols e.g. https in m3u files etc, if plan to handle other (nested) protos than local files then can omit
#<ano> iconoclast_hero: it will use 1 thread per conversion, so many parallel conversions as threads
#<ano> can change nproc=$(nproc) with nproc="n_parallel_conversions_wanted"


