#!/bin/bash
# nb: the swp file that editscript relies on is provided by nano
# opusbook4ka is an external dependency

trap '{ breakout; exit 1; }' INT
shopt -s extglob
scriptname="$(realpath $0)"
script="${scriptname##*\/}"
pidfile="/tmp/.opus.book.pids"
threads=4
mediaext="*.@(flac|mp3|MP3|wav|m4?|ogg|MP4|mp4|wma)"
filtercomplex="compand=attacks=0:decays=0.12:points=-70/-900|-40/-90|-35/-37|-21/-18|1/-1|20/-1:soft-knee=0.03:gain=1.00:volume=-90, firequalizer=gain_entry='entry(0,-99);entry(140,0);entry(1000,0);entry(8000,1);entry(10500,4);entry(12000,5);entry(14500,-4);entry(19000,-20)', volume=1.0"

editscript(){
  local scriptname script path swp; scriptname=$(realpath "$0" 2>/dev/null); script="${scriptname##*/}"; path="${scriptname%/*}"; swp="$path/.$script.swp"
     [[ ! -e "$swp" ]] && (/usr/bin/nano "$scriptname") && exit
     printf "\n%s is already being edited.\n%s exists; try fg or look in another window.\n" "$scriptname" "$swp"; exit ;}

pause(){ read -rp "$*" ; }

ffmpegs(){
   ffmpeg -n -nostdin -hide_banner -loglevel error -stats -i "$1" -filter_complex "$filtercomplex" -c:a libopus -b:a 17k -frame_duration:a 60 "${1%.*}.opus" ; }

ffmpeg2(){
  mediafiles=( ${mediaext} )
  for file in ${mediaext}
    do
      echo "${file%.*}" >> /tmp/mytmpfile
      readarray -t ffoutput < <(ffmpeg -n -nostdin -hide_banner -loglevel error -stats -i "$file" -filter_complex "$filtercomplex" -c:a libopus -b:a 17k -frame_duration:a 60 -ar 24k "${file%.*}.opus" 2>&1 >/dev/null)
      # hmmm with the 2>&1 >/dev/null, I'm guessing that this is not going to work as a test anymore
      erfile="${ffoutput[0]}"; erfile="${erfile%%=*}"
      if [[ "$erfile" != "size" ]] && [[ "$erfile" != *already\ exists.\ Exiting* ]]
        then
          echo "${ffoutput[@]}"; echo "Error: exiting."; exit ;
        else
#         [[ "$erfile" != *already\ exists.\ Exiting* ]] && echo "$erfile"
          y="$(sort /tmp/mytmpfile 2>/dev/null|uniq|wc -l)"
          [[ "$y" -gt "$processed" ]] && processed="$y" &&                                 		# This does not work correctly and most likely never will
            if [[ "${#mediafiles[@]}" -lt 100 ]]												# without a complete rewrite.  There are notes at the end about
              then																				# wait and parallel, but at the end of the day, this is just
                printf '%02d of %02d -- on %s\n' "$processed" "${#mediafiles[@]}" "$file"		# there to show that something is happening and progress is being
              else																				# made so it's going to stay this way for a while!
                printf '%03d of %03d -- on %s\n' "$processed" "${#mediafiles[@]}" "$file"		# Thu May  2 02:28:58 PM EDT 2024
            fi
       fi
    done ; }


stats(){
  if [[ -n "$1" ]]; then
      echo mediaduration "${1#*.}" `mediaduration "${1#*.}"`
      echo mediaduration opus `mediaduration opus`
  else
    startbitrate=$(mediainfo "$g"|grep "Overall bit rate")
    printf '\n\nConverstion statistics:\n'
    printf '\nFor %s:\n%s\n' "$g" "$startbitrate"
    printf 'mediaduration %s: %s\n' "$startext" "$(mediaduration "$startext")"
    printf 'mediaduration opus: %s\n' "$(mediaduration opus)"
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

breakout(){
  while IFS= read -r pid
   do
     [[ "$pid" = *"$script"* ]] || [[ "$pid" = *ffmpeg* ]] && echo "${pid% pts*}" >> "$pidfile"
  done< <(ps --tty $(tty) Sf)
  opusbook4ka "$pidfile" ; }   # opusbook4ka is a dependency

###START

[[ "$1" == @(edit|e|nano|-e|-E) ]] && editscript
rm /tmp/mytmpfile .opus.book.pids "$pidfile" 2>/dev/null
startext=( ${mediaext} ); startext="${startext##*.}"
filenum="$(ls ${mediaext}|wc -l)"
[[ "$filenum" -lt "$threads" ]] && threads="$filenum"

printf '%s\n\nDuration of %s %s file(s) to convert: %s\n\n\n' "$(pwd)" "$filenum" "$startext" "$(mediaduration "$startext")"

for ((i=0; i<"$threads"; i++))
 do
  if [[ -n "$1" ]]
   then
     file="$1"
     ffmpeg -n -nostdin -hide_banner -loglevel error -stats -i "$file" -filter_complex "$filtercomplex" -c:a libopus -b:a 17k -ar 24k -frame_duration:a 60 "${file%.*}.opus"
     exit
   else
    ffmpeg2&    # call function to background to convert media files to opus, counter
  fi
    \sleep 0.5s  #\jic i run from cli
 done

wait  #for the bacground operations to finish up
#stats   #not being used right now.  maybe make a cli option?  maybe not?
rm /tmp/mytmpfile .opus.book.pids "$pidfile" 2>/dev/null
exit

<!wait-n> Run up to 5 processes in parallel (bash 4.3): i=0 j=5; for elem in "${array[@]}"; do (( i++ < j )) || wait -n; my_job "$elem" & done; wait

<ano> iconoclast_hero: (( "$#" )) && nproc=$(nproc) && printf %s\\0 "$@" | xargs -0P"$nproc" -n1 bash -c 'ffmpeg -nostdin -v error -threads 1 -protocol_whitelist file -i "$0" ... "${0}.opus"'
<ano> iconoclast_hero: if want to be sure ffmpeg converts only local files and doesn't follow other protocols e.g. https in m3u files etc, if plan to handle other (nested) protos than local files then can omit
<ano> iconoclast_hero: it will use 1 thread per conversion, so many parallel conversions as threads
<ano> can change nproc=$(nproc) with nproc="n_parallel_conversions_wanted"






#ffmpeg2bak(){
#  mediafiles=( *.@(flac|mp3|MP3|wav|m4?|ogg|MP4|mp4|wma) )
#  for file in *.@(flac|mp3|MP3|wav|m4?|ogg|MP4|mp4|wma) #2022.12.23 added MP4|mp4 support #2023.09.06 added wma support
#    do
#       echo "${file%.*}" >> /tmp/mytmpfile
#       readarray -t ffoutput < <(ffmpeg -n -nostdin -hide_banner -loglevel error -stats -i "$file" -filter_complex "$filtercomplex" -c:a libopus -b:a 17k -frame_duration:a 60 -ar 24000 "${file%.*}.opus" 2>&1 >/dev/null)
#       erfile="${ffoutput[0]}}"; erfile="${erfile%\'*}"; erfile="${erfile#*\'}"
###       [[ ! "${erfile%.opus}" == "${file%.*}" ]] && echo "${ffoutput[@]}" || ((ni++)) && printf '%s out of %s\n' "$ni" "${#mediafiles[@]}"
###       echo "${erfile%.opus} == ${file%.*}"
#       if ! [[ "${erfile%.opus}" == "${file%.*}" ]]
#         then
#           echo "${ffoutput[@]}"
#         else
##          ((numinc++))
##          echo "${file%.*}" >> /tmp/mytmpfile
#          processed="$(sort /tmp/mytmpfile>/dev/null|uniq|wc -l)"
#          x="$(printf '%s of %s\n' "$processed" "${#mediafiles[@]}")"
#          y="$(cat /tmp/mytmpfile 2>/dev/null)"
#          [[ "$processed" -gt "$y" ]] &&
#          printf '%s' "$processed" |tee /tmp/mytmpfile2 && printf ' of %s\n' "${#mediafiles[@]}" #&& cat /tmp/mytmpfile2
###        printf '%s out of %s\n' "$processed" "${#mediafiles[@]}" |tee /tmp/mytmpfile2
#       fi
#
###      ffmpeg -n -nostdin -hide_banner -loglevel error -stats -i "$file" -acodec libopus -b:a 17k "${file%.*}.opus"&
#    done
#}

