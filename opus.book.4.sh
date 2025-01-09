#!/bin/bash
# nb: the swp file that editscript relies on is provided by nano
# opusbook4ka is an external dependency
#set -x
#trap read DEBUG

. ~/.config/indexopus.conf

# Invokes breakout function upon INT/^C
trap '{ breakout -B; exit 1; }' INT
pidfile="/tmp/.opus.book.pids"

# global shopt settings.  nullglob causes unwanted things with ls, so it needs to be reconsidered
shopt -s extglob nullglob   # as a global option

#Who am I?
scriptpath="$(realpath $0)"
script="${scriptpath##*\/}"

[[ ! "$threads" ]] && threads=4 # number of parallel threads
bfreq=12 # flashing frequency (( $(date +%s) % bfreq == 0 )) && ...
rfreq=45 # tput reset frequency...  ca. period...
sexpattern='^([0-9]|[0-9][0-9]|[0-9][0-9][0-9]):([0-5]?[0-9]):([0-5]?[0-9])$'   # RegEx pattern to match a sexagesimal:
mediaext="*.@(flac|mp3|MP3|wav|m4?|ogg|MP4|mp4|wma)"   #DO NOT INCLUDE OPUS FILES IN THIS
filtercomplex="compand=attacks=0:decays=0.12:points=-70/-900|-40/-90|-35/-37|-21/-18|1/-1|20/-1:soft-knee=0.03:gain=1.00:volume=-90, firequalizer=gain_entry='entry(0,-99);entry(140,0);entry(1000,0);entry(8000,1);entry(10500,4);entry(12000,5);entry(14500,-4);entry(19000,-20)', volume=1.0"

bold="$(tput bold)"
red="$(tput setaf 1)"
relipsis="$red..."
tput0="$(tput sgr0)"


stamp="$(date +%s)"
tmp="/tmp/opus.book.4-$stamp"

## load functions #############################################################################
## editscript()
## printline()  <title for line>... probably shouldn't say calling external dependency?
## pause()      [prompt required]
## checkdur()   <optional extension>
## sex2sec()    "##:##:##"

. $HOME/bin/gits/indexopus/indexopus.lib

editscript(){
  local scriptpath script path swp; scriptpath=$(realpath "$0" 2>/dev/null); script="${scriptpath##*/}"; path="${scriptpath%/*}"; swp="$path/.$script.swp"
     [[ ! -e "$swp" ]] && (/usr/bin/nano "$scriptpath") && exit
     printf "\n%s is already being edited.\n%s exists; try fg or look in another window.\n" "$scriptpath" "$swp"; exit ;}

pause(){ read -rp "$*" ; }

ffmpegs(){
   ffmpeg -n \
          -nostdin \
          -hide_banner \
          -loglevel error \
          -stats -i "$1" \
          -filter_complex "$filtercomplex" \
          -c:a libopus \
          -b:a 17k \
          -frame_duration:a 60 \
          -ar 24k \
          "${1%.*}.opus" ; }

ffmpeg2(){
 local startfile
  touch "$tmp"
  for startfile in ${mediaext}; do #do not quote; contains wildcard!
      file="${startfile%.*}"
      opusfile="$file.opus"
      [[ "${outputarray[@]}" != *"$file"* ]] && outputarray+=("$file") #&& echo "$file"
      outputfiles="$(<"$tmp")"
      [[ "$outputfiles" != *"$file"* ]] && echo "${relipsis}Converting $file$tput0" >> "$tmp"
      readarray -d $'\r' -t ffoutput < <(ffmpeg -n \
                                       -nostdin \
                                       -hide_banner \
                                       -loglevel error \
                                       -stats \
                                       -i "$startfile" \
                                       -c:a libopus \
                                       -b:a 17k \
                                       -frame_duration:a 60 \
                                       -ar 24k \
                                       "$opusfile" 2>&1 >/dev/null)

# hmmm with the 2>&1 >/dev/null, I'm guessing that this is not going to work as a test anymore
      erfile="${ffoutput[0]}"; erfile="${erfile%%=*}"

#
# Going to change the logic of this test to say if the erfile is not equal to "size", whatever the fuck that was/is doing...
#
#      if [[ "$erfile" != "size" ]] && [[ "$erfile" != *already\ exists.\ Exiting* ]]
#
# So instead of using the first line of the output from ffmpeg, it looks like i should use the last because if there's a
# recoverable error, e.g., this bullshit:
#$ printf %s\\n "${ffoutput[0]}"
#Incorrect BOM value
#Error reading comment frame, skipped
#File 'Book-Part04.opus' already exists. Exiting.
#Error opening output file Book-Part04.opus
#$ declare -p ffoutput
#declare -a ffoutput=([0]=$'Incorrect BOM value\nError reading comment frame, skipped\nFile \'Book-Part04.opus\' already exists. Exiting.\nError opening output file Book-Part04.opus.\n')
#
#it will still pass if it can convert...
#
#

      if [[ "${ffoutput[-1]}" != size\=\ * ]] && [[ "$erfile" != *already\ exists.\ Exiting* ]]
        then
          printf '%s\n%s\n' "${ffoutput[@]}" "Error: exiting."
          exit 1
       fi
    done ; }


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
  local breakout
  while (( $# > 0 )); do
    [[ "$1" = -a ]] && array=true && unset pidarray && shift
    [[ "$1" = -B ]] && breakout=true && shift
    [[ "$1" = -b ]] && breakother=true && other="$2" && shift && shift
    shift
  done

  while IFS= read -r pid
   do
#     [[ "$pid" = *"$script"* ]] || [[ "$pid" = *ffmpeg* ]] &&
#       pidarray+=( "$(echo "${pid% pts*}" |tee -a "$pidfile")" )
      [[ "$other" && "$pid" = *"$other"* ]] || [[ "$pid" = *"$script"* ]] || [[ "$pid" = *ffmpeg* ]] && echo "${pid% pts*}" >> "$pidfile"
      [[ "$array" && "$pid" = *ffmpeg* ]] && pidarray+=( "${pid% pts*}" )
  done< <(ps --tty $(tty) Sf)

  [[ "$breakout" ]] && [[ ! "$array" ]] &&
     opusbook4ka "$pidfile" ; }   # opusbook4ka is a dependency

##--> braekout() <--###########################################################################

progress() {
  local opusdur="00:00:00" indur="$1"
  local opuspresent ck4files
  opuspresent=( *.opus )  #this is used for just run of the mill conversions and there's no
                          #filename check before it gets here so using the *\ --\ Part\ ???.opus
                          #glob will fail for random mp3s that haven't been run through indexopus

  [[ "$opuspresent" ]] && opusdur="$(checkdur opus)"
  [[ ! "$bfreq" =~ [[:digit:]]+ ]] && bfreq=12 # flashing frequency (( $(date +%s) % bfreq == 0 )) && .
  [[ ! "$rfreq" =~ [[:digit:]]+ ]] && bfreq=6 # flashing frequency (( $(date +%s) % bfreq == 0 )) && .

  pidarray=true  # this shouldn't get set until breakout -a is run below...

  progress_bar_sexagesimal(){  #this will probably get moved out at some point...
    local elapsed_time="$1"
    local target_time="$2"
    local width=$(( $(tput cols) -6 ))
    local elapsed_seconds="$(sex2sec "$elapsed_time")"
    local target_seconds="$(sex2sec "$target_time")"
    local percent=$(( (elapsed_seconds * 100) / target_seconds ))
    local progress=$(( (width * percent) / 100 ))
    local remainder=$(( width - progress ))
    printf '\r%s[%s' "$bold" "$tput0"
    for ((i=0; i<progress; i++)); do printf '%s—%s' "$red" "$tput0"; done
    printf '%s>%s' "$red" "$tput0"
    for ((i=0; i<remainder-1; i++)); do printf " "; done
    printf '%s] %d%%%s' "$bold" "$percent" "$tput0"

  }

# figuring out a condition to end this loop is going to be an issue:
# there are time discrepancies.  sometimes more than a minute now that i think about it...
# though usually the opus files go over.  i need to come up with another boundary condition...
# look for the pids?

  lines="$(tput lines)"

  while [[ "${indur%:*}" != "${opusdur%:*}" ]] &&
    (( $(( "$(sex2sec "$opusdur")" + 20 )) < $(sex2sec "$indur") )) &&
    [[ "$pidarray" ]]; do
      tput cup "$(( $(tput lines) - 3 ))" 0
      for ((i=0; i<4; i++)); do
        tput cuu1 # Move cursor up one more line
        tput el   # Clear the current line
      done
      (( "$(date +%s)" % bfreq == 0 )) && echo "( • )( • )----ԅ(‾⌣‾ԅ)" || echo
      [[ "$startext" != "flac" ]] && notflac=' '
      printf '%sDuration of %s.%s files: %s\n%s' "$bold" "$notflac" "$startext" "$indur" "$tput0"
      printf '%sDuration of .opus files: %s\n%s' "$bold" "$opusdur" "$tput0"
      [[ "$opusdur" =~ $sexpattern && "$indur" =~ $sexpattern ]] &&
         progress_bar_sexagesimal "$opusdur" "$indur"
      breakout -a
      tput cup 0 0
#      printf '%s\n' "${bannerarray[@]}"
      printf %s\\n\\n "$updatebanner"
      outputfiles="$(<"$tmp")"
      echo "$outputfiles"|tail -n $(( "$(tput lines)" - 15 ))
      sleep 12
      opusdur="$(mediaduration opus)"
#      (( "$(date +%s)" % "$rfreq" == 0 )) && $(tput reset); clear -x
      [[ "$lines" != "$(tput lines)" ]] && lines="$(tput lines)" && tput reset
      clear -x
  done
}


#while [[ "${indur%:*}" != "${opusdur%:*}" ]] &&
#  (( $(sex2sec "$opusdur") + 20 < $(sex2sec "$indur") ));
#  if [[ "$first_call" != false ]]; then
#    printf 'Duration of %s files : %s\n' "$startext" "$indur"
#    first_call=false
#  else
#    if [[ "$opuspresent" != true ]]; then
#      ck4files=( *opus )
#      [[ "$ck4files" ]] && opusdur="$(mediaduration opus)" && opuspresent="true"
#    else
#      opusdur="$(mediaduration opus)"
#    fi
#    tput cuu1 # Move cursor up one more line
#    tput el   # Clear the current line
#    tput cuu1 # Move cursor up one more line
#    tput el   # Clear the current line
#  fi
#  printf 'Duration of .opus files: %s\n' "$opusdur"
#  [[ "$opusdur" ]] &&
#  progress_bar_sexagesimal "$opusdur" "$indur"
#  echo
#  \sleep 10s
#done ; }
#


###--> progress() <--#########################################################################





###--> Main Code <--###########################################################################
###--> opus.book.4 <--#########################################################################

[[ "$1" = @(-ys|-yes) ]] && shift && rmmatch=true && screened=true

#[[ "$1" ]] && clifile "$1"

[[ ! "$files" ]] && files=( *.mp3 )
[[ ! "$files" ]] && files=( *.m4? )

if "${screened:=false}"; then
  printline "$bold Calling opus.book.4 in GNU screen $tput0"
  printf \\n\\n
  allm4s=(*.m4[ab])
  screenname="o.b.4-${files[0]}"
  screen -dmS "${screenname:0:16}" opus.book.4
  screen -ls
  printf \\n\\n
  exit
fi

printf \\n
bannerarray=( "$(printline "${bold}  Welcome to ${white}${script} ${tput0}")" )
printf %s\\n\\n "${bannerarray[@]}"

mediafiles=( ${mediaext} )

#(( ${#mediafiles[@]} != 1 )) && printf '\n%sThere is no single appropriatly-named media file in %s.  Please check and try again.\nexit 1\n\n%s' "$bold" "$(pwd)" "$tput0" && exit 1

#test for more than one accptable media extension and fail if it finds more than one.
for exts in "${mediafiles[@]}"; do
    extensions+=( "${exts##*.}" )
done

(( $(printf '%s\n' "${extensions[@]}"|sort -u|wc -l) > 1 )) &&
  printf '\n%sMore than one type of media file found!\nopus.book.4 cannot be launched from a folder where more than one type of media file is located.\nCorrect and try again.\n\n%s\n\n%sexit 1\n\n' "$bold" "$PWD" "$tput0" &&
  exit 1

while (( $# > 0 )); do
  [[ "$1" = @(edit|e|-e) ]] && editscript
  [[ "$1" = @(-s|--stats) ]] && shift && statson=true
  [[ "$1" = "-d" ]] && inputdur="$2" && shift 2
  [[ "$1" = @(-h|--help) ]]  && shift && help=true
  [[ "$1" = @(-f|--force) ]] && shift && overwrite=true   #this doesn't actually change what ffmpeg does yet!
  [[ "$1" = @(-b|--break) ]] && shift && break-m4b2opus=true && trap '{ breakout -B -b m4b2opus; exit 1; }' INT
  startfile="$1" && file="$startfile" && opusfile="${file%.*}.opus"	 #it's just letting me into the program atm
  shift
done

if [[ "$startfile" && ! -f "$startfile" && "$startfile" != $mediaext ]] || (( "${#mediafiles[@]}" == 0 ))  #Do not quote $mediaext as it contains a wildcard
  then
  echo "Usage: $0 [edit|e|-e] [-d] "##:##:##" [-s|--stats] [-f|--force] [-h|--help] <optional filename>"
  echo "Files must be of $mediaext format."
  exit 1
fi

rm /tmp/mytmpfile .opus.book.pids "$pidfile" 2>/dev/null  	# clean any old files that will be in the way
startext=( ${mediaext} ); startext="${startext##*.}"		# define what the starting extension is in dir
#mediafiles=                                                 # why the fuck is this here?  there should be no reason to unset mediafiles AND this isn't the way to do it anyway...
filenum="$(ls ${mediaext}|wc -l)"							# how many of those files are there?

(( filenum < threads )) && threads="$filenum"

if  [[ "$startfile" ]] && [[ -f "$opusfile" ]] && [[ "$overwrite" != true ]]; then
  printf '\n%s%s%s exists!%s\n   %sexit 1\n\n%s' "$relipsis" "$bold" "$opusfile" "$white" "$tput0"
  echo "$line"
  exit 1
elif [[ "$startfile" ]]; then
  printf '\n%sConverting: %s.\n     Duration: %s%s%s%s\n\n' "$relipsis" "$file" "$tput0" "$bold" "$(ffprobe -i "$file" -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal |
    awk -F: '{printf "%02d:%02d:%02.2f\n", $1, $2, $3}')" "$tput0"
  ffmpeg -y \
         -nostdin \
         -hide_banner \
         -loglevel error \
         -stats \
         -i "$file" \
         -filter_complex "$filtercomplex" \
         -c:a libopus \
         -b:a 17k \
         -ar 24k \
         -frame_duration:a 60 \
         "${file%.*}.opus"
  printf '\n%sDurations:\n%s' "$bold" "$tput0"
  checkdur "$startfile"
  checkdur "$opusfile"
elif (( filenum > 0 )); then
#need to add a formal confirm here at some point, but really, who's going to be doing this?
#ffmpeg cannot overwrite here so probably have to exit if the files aren't deleted... further, we could actully compare the opus files that exist to the ones that are going to be converted...but since im not using find here, that probably donesnt matter.

  if [[ "$overwrite" = true ]]; then
    printf '\n%s%s invoked with --force|-f flag to overwrite existing .opus files.\n' "$red" "$script"
    printf '\n%sConfirm deletion of existing *.opus files prior to starting conversion!%s\n' "$bold" "$tput0"
    printf '\nIt'\''d be great if there was actually a confirm here... your shit'\''s deleted sucker!\n'
    eza --color=always
    if confirm "rm *opus? (y/n) "; then
      rm *opus 2>/dev/null || exit 1
    else
      printf 'FWIW, ffmpeg cannot be invoked with -y here because of the way multipe instances race.\n%s will exit now' "$script"
      exit 1
    fi
  fi

  [[ ! "$inputdur" ]] && inputdur="$(mediaduration "$startext")"; echo "$inputdur"
#  bannerarray=( "$(printf '%sDuration of %s %s file(s) to convert: %s%s%s%s%s\n...in: %s%s\n\n' \
#"$relipsis" "$filenum" "$startext" "$tput0" "$bold" "$inputdur" "$tput0" "$red" "$PWD" "$tput0")" )
#  bannerarray+=( "$(printf '%sConversion progress:\n%s'  "$relipsis" "$tput0")" )
#  printf '%s\n%sGathering files...\n%s' "${bannerarray[${#bannerarray[@]}-2]}" "$relipsis" "$tput0"

  printf '%sDuration of %s%s %s%s file(s) to convert: %s%s%s%s%s\n...in: %s%s%s\n\n' \
    "$relipsis" \
    "$white" \
    "$filenum" \
    "$startext" \
    "$red" \
    "$tput0" \
    "$bold" \
    "$inputdur" \
    "$tput0" \
    "$red" \
    "$white" \
    "$PWD" \
    "$tput0"

  if [[ ! -w . || $(find "${mediafiles[0]}" ! -writable -print -quit) ]]; then
    sudo chmod -R g+w .
    sudo chown -R "$USER:media" .
  fi

  for ((i=0; i<"$threads"; i++)); do
    ffmpeg2&    # call function to background to convert media files to opus, counter
    sleep 0.5s
  done

  updatebanner="$(printline "$bold Converting $filenum $startext files of duration $inputdur$tput0 ")"
  clear -x
  progress "$inputdur"
  wait  #for the bacground operations to finish up
  clear -x
###  printf '%s\n' "${bannerarray[@]}"
  printf %s\\n "$updatebanner"
  outputfiles="$(<"$tmp")"
  printf '%s\n\n%s' "$outputfiles"
  mediaduration #external dependency
  echo
  lsopus=( *opus )
  printf '%s\n' "${lsopus[@]}"
else
  # Check if filename is provided
    echo "Usage: $0 [-s|--stats] [-f|--force] <optional filename>"
    exit 1
fi

[[ "$statson" = true ]] && stats

rm /tmp/mytmpfile "$tmp" .opus.book.pids "$pidfile" 2>/dev/null
echo
printline "$bold  Exiting (0) $white $script  $tput0"
echo
exit 0

exit

#some fun thoughts on parallel:
#<!wait-n> Run up to 5 processes in parallel (bash 4.3): i=0 j=5; for elem in "${array[@]}"; do (( i++ < j )) || wait -n; my_job "$elem" & done; wait
#<ano> iconoclast_hero: (( "$#" )) && nproc=$(nproc) && printf %s\\0 "$@" | xargs -0P"$nproc" -n1 bash -c 'ffmpeg -nostdin -v error -threads 1 -protocol_whitelist file -i "$0" ... "${0}.opus"'
#<ano> iconoclast_hero: if want to be sure ffmpeg converts only local files and doesn't follow other protocols e.g. https in m3u files etc, if plan to handle other (nested) protos than local files then can omit
#<ano> iconoclast_hero: it will use 1 thread per conversion, so many parallel conversions as threads
#<ano> can change nproc=$(nproc) with nproc="n_parallel_conversions_wanted"



## Function to send data to file descriptor 3
#send_to_fd3() {
#    local data="$1"
#    echo "$data" >&3
#}
#
## Function to retrieve data from file descriptor 3
#retrieve_from_fd3() {
#    local data
#    read -r data <&3
#    echo "$data"
#}


