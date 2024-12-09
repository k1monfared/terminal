# rip audio cd
I don't know if anyone uses audio CD's anymore, but one of the ways that I'm used to support musician's that I like is by buying their CD's directly from them, and often enough (always?) that comes in a CD format. So here is a little script that I stole from https://bash.cyberciti.biz/multimedia/linux-rip-audio-cd/ to rip Audio CD's into mp3 quickly.

It works this way:

    mkdir "Album name"
    cd !!:1
    /path/to/ripcd.sh

It would be nice to have the script to read the CD info and create the folders and name them appropriately. One little problem is that many audio CD's don't provide that info in the CD text. Anyways, here are a few commands in case they do:

`libcdio` provides some useful tools such as `cd-info`. Check out the documentation here: http://www.gnu.org/software/libcdio/libcdio.html
