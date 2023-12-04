# indexopus
This takes .opus chapter files and incorporates them into a single indexed file using ffmpeg, mediainfo, and opustags.
depends: opustag, ffmpeg/ffprobe
optional: mediainfo

Files **must** be in the format of 'Title -- Part ##: Chapter Title.opus' and presently only works for .opus; there are other tools for e.g., m4b: use them.
Presumably, however, this script could easily be changed out for another codec, however opustag would need to change to something else that can write metadata, e.g, ffmpeg which should be able to do any format.
Tthat said, the author feels that this satisfices for the purposes at hand and if/when the codec changes, that bridge will be burnt when it is arrived upon.

### Usage:
From the directory containing your opus chapter files named in the correct format (takes no options):

`$ indexopus` 

### Future improvements: 
Would like to make it so that the files do not need a chapter name and are iterated with 000, 001, 002, .... for Chapter Title
ffmpeg could presumably take over for opustag to eliminate that dependency and then all that would be required is ffmpeg
 
# chaptersplit
I have included a utility I've been using that splits .m4b, .mp3, and .opus files into chapters from an embedded index.  As shown in the code, it is not mine originally and I haven't cleaned it up at all, but should you want to run a conversion step in parallel before using indexopus to stitch the constiuent parts up again, this will do that, but presently the split files are going to /dev/shm/cache/convert which may or may not be where _you_ want them to go.  Adjust outputdir="/dev/shm/cache/convert" if you like (it should work fine on Ubuntu which includes /dev/shm by default; if left here, the conversion will be done on a scratch tmpfs ram drive).

