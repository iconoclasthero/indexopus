I'm tracking some scripts I've written here.  If the code's useful to someone, feel free to use it; I don't think I'm going to provide support for any of this since it's only satisficing for my use.

# m4b2opus
Realistically, that's what this does.  there are pices that do other things, but m4b2opus takes the disparate pieces and chops up an audio book so it can be converted in parallel to opus, and stitched back together to get an indexed audiobook out of it.  at this point indexopus is being used by the script and index-opus will be removed.
Basically, you just need to go to the directory with a file that has a normalish-enough name and 
` $ m4b2opus ` and you get an indexed opus audiobook out of it.

# indexopus
This takes .opus chapter files and incorporates them into a single indexed file using ffmpeg, mediainfo, and opustags.
depends: opustag, ffmpeg/ffprobe
optional: mediainfo

**Files need to be in the format of 'Title -- Part ##: Chapter Title.opus'** 
`$ indexopus` 
You can specify the title with `$ indexopus <title>`; m4b2opus passes indexopus the title that way.

This has been reworked to include a reindex option that will take an audiobookshelf metadata.json with chapter information and remove the old index, if found, and replace it with a new one.

A config file is required at '$HOME/.config/indexopus.conf' with the following information:
  absserver="https://web.address.com"
  abssqlite="/path/to/location/of/config/absdatabase.sqlite"

# opus.book.4
I use screen and opus.book.4 to manage the conversions for me.  The "4" refers to the number of cores I have and use.  
YMMV, change the code to the number of parallel conversion jobs you want.

# mediaduration, quartero4, chaptersplit
I have included these separate utilities I've been using to split files into chapters from an embedded index.  
As shown in the code, it is not mine originally and I haven't cleaned it up at all, but should you want to run a conversion step in parallel before using indexopus to stitch the constiuent parts up again, this will do that, but presently the split files are going to /dev/shm/cache/convert which may or may not be where _you_ want them to go.  Adjust outputdir="/dev/shm/cache/convert" if you like (it should work fine on Ubuntu which includes /dev/shm by default; if left here, the conversion will be done on a scratch tmpfs ram drive).

# reindex
This is depricated.  indexopus reindex should be used.
~it's most of the above with portions clipped out so it can be used separately.  it's not up to date with indexopus and will eventually be dropeed unless I can find an easy way to clip the portions of indexopus.
it was mainly for demonstration/sharing purposes~

