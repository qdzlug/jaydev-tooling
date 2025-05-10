#!/bin/bash

export MANTA_KEY_ID=aa:76:9c:1b:91:d1:79:bf:46:74:2c:49:99:67:2b:f4
export MANTA_URL=https://us-east.manta.joyent.com
export MANTA_USER=qdzlug

# Do the memes....
cd ~/Dropbox/Public/memes
~/bin/ghetto-gif.sh
manta-sync -d . ~~/public/memes

# Now the gifs....
cd ~/Dropbox/Public/gifs
~/bin/ghetto-gif.sh
manta-sync -d . ~~/public/gifs

