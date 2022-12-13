#!/bin/bash
DIR="$PWD"

ls -p "$DIR/" | grep -v / > "$DIR/".templist

while IFS='' read -r line || [ -n "$line" ]; do
    CRDT=$(get_image_creation_yymm "$DIR/$line")
    if [ $CRDT != '-' ]
    then
        if [ ! -d "$DIR/$CRDT" ]
        then
            echo Created folder "$DIR/$CRDT".
            mkdir "$DIR/$CRDT"
            mv "$DIR/$line" "$DIR/$CRDT"
        else
            mv "$DIR/$line" "$DIR/$CRDT"
        fi
    else
        if [ ! -d "$DIR/0000-00" ]
        then
            echo Created folder "$DIR/0000-00".
            mkdir "$DIR/0000-00"
        fi
        mv "$DIR/$line" "$DIR/0000-00/"
    fi
done < "$DIR/".templist
echo 'All done.'

rm "$DIR/".templist
