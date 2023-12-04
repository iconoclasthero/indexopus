# indexopus
This takes .opus chapter files and incorporates them into a single indexed file using ffmpeg, mediainfo, and opustags.
depends: opustag, ffmpeg/ffprobe
optional: mediainfo

Files **must** be in the format of 'Title -- Part ##: Chapter Title.opus' and presently only works for .opus; there are other tools for e.g., m4b: use them.
Presumably, however, this script could easily be changed out for another codec, however opustag would need to change to something else that can write metadata, e.g, ffmpeg which should be able to do any format.
Tthat said, the author feels that this satisfices for the purposes at hand and if/when the codec changes, that bridge will be burnt when it is arrived upon.

Future improvements: 
Would like to make it so that the files do not need a chapter name and are iterated with 000, 001, 002, .... for Chapter Title
ffmpeg could presumably take over for opustag to eliminate that dependency and then all that would be required is ffmpeg

