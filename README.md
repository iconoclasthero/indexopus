I'm tracking some scripts I've written here.  If the code's useful to someone, feel free to use it; I don't think I'm going to provide support for any of this since it's only satisficing for my use.

# m4b2opus
Realistically, that's what this does.  there are pieces that do other things, but m4b2opus takes the disparate pieces and chops up an audio book so it can be converted in parallel to opus, and stitched back together to get an indexed audiobook out of it.  at this point indexopus is being used by the script.
Basically, you just need to go to the directory with a file that has a normalish-enough name and 
` $ m4b2opus ` and you get an indexed opus audiobook out of it.

# indexopus
This takes .opus chapter files and incorporates them into a single indexed file using ffmpeg, ffprobe,  mediainfo, and opustags.
depends: opustags, ffmpeg/ffprobe, mediainfo, mplayer

**Files need to be in the format of 'Title -- Part ##: Chapter Title.opus'** 
There is some correction for common variations I've run into, but ultimately it will be in this format.

`$ indexopus` 
You can specify the title with `$ indexopus <title>`; m4b2opus passes indexopus the title that way.

This has been reworked to include a reindex option that will take an audiobookshelf metadata.json with chapter information and remove the old index, if found, and replace it with a new one.

A config file is required at '$HOME/.config/indexopus.conf' with the following information:
```
absserver="https://web.address.com"
abssqlite="/path/to/location/of/config/absdatabase.sqlite"
```

# opus.book.4 / opusbook4ka
I use screen and opus.book.4 to manage the conversions for me.  The "4" refers to the number of cores I have and use.  
YMMV, change the code to the number of parallel conversion jobs you want.
opusbook4ka is the helper program that lets you break out of the background jobs...only need it if you need to ^C!

# mediaduration, quartero4, chaptersplit
I have included these separate utilities I've been using to split files into chapters from an embedded index.
As shown in the code, it is not mine originally and I haven't cleaned it up at all, but should you want to run a conversion step in parallel before using indexopus to stitch the constiuent parts up again, this will do that, but presently the split files are going to /dev/shm/cache/convert which may or may not be where _you_ want them to go.  Adjust outputdir="/dev/shm/cache/convert" if you like (it should work fine on Ubuntu which includes /dev/shm by default; if left here, the conversion will be done on a scratch tmpfs ram drive).

# m4b2opus-no-chap-check
Not sure what this does anymore...  If you figure it out, lemme know.

# concat
Sort of a rough script for concatenating audiofiles. It should be set up to do whatever ffmpeg can do. There may be problems with files containing `'` because ffmpeg can't handle them.
**What it does do is allow you to edit the script and change the extension it handles and thus you can concat whatever files ffmpeg can handle.**  This would be better if it took the extension as a cli flag, but I rarely use it so it's not worth the trouble.

# downconvert
Not really something that belongs in this repo, but it was untracked in `~/bin/` and that made me nervous so here we are with a file to convert flacs down to 16 bit/48 kHz.

#mklnbook.functions
These are copied from my ~/.bash_functions which are sourced from .bashrc along with .bash_aliases. I'm including them because they could be instructive and it's a place to keep them... unfortunately, that also means that they're not tracked but must be manually updated.
