# Play a youtube video from terminal

Each youtube video has an ID which is in the link after "v=".

For example the video in this link: https://www.youtube.com/watch?v=2QTf8Yjn7Hk

has the video id: 2QTf8Yjn7Hk

The file yt can be used to download the video and the play it once, several times, or in an endless loop.

In all cases the script searches in the ~/Videos folder to see the file with that video ID (VID_ID) exist or not.

If the file VID_ID.mp4 exists then it plays it accordingly, if not, it first downloads it to the ~/Videos folder and then plays it.

USAGE:

1) to play the video only once:

yt VID_ID 

e.g. yt 2QTf8Yjn7Hk


2) to play the video N times

yt N VID_ID

e.g. yt 10 2QTf8Yjn7Hk


3) to play the video in an endless loop

yt 0 VID_ID

e.g. yt 0 2QTf8Yjn7Hk

--

TO DO:
- have an option for saving if the video is being played only once, that is,
  - yt -s VID_ID <<< saves the video and plays it once
  - yt VID_ID <<< just plays the video once, streaming it from web without saving
