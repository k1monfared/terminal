#!/bin/bash




DATE=$(date +"%F")
backup_folder="/home/$USER/backup/$DATE-phone"
if [ ! -d "$DIR/$CRDT" ]
then
    mkdir "$backup_folder"
fi
phone_name=$(ls /run/user/$UID/gvfs | tail -1)
phone_storage_folder=$(ls /run/user/$UID/gvfs/$phone_name | tail -1)
parent_folder="/run/user/$UID/gvfs/$phone_name/$phone_storage_folder"
# using it this way doesn't need using limited mtp/gio function, you can treat it just like normal

# ## Delete things
# temp_list=/home/$USER/.phonetempfiles
# echo "" > $temp_list
# folders_list=/home/$USER/scripts/public/terminal/bash_scripts/phone_places_copy.lst
# ### get a list of files to be deleted
# while IFS='' read -r line || [[ -n "$line" ]]; do
#     ls "$parent_folder/$line" | xargs -Ifilename echo "$parent_folder/$line/"filename >> $temp_list
#     echo "$line is read."
# done < $folders_lis
# while IFS='' read -r line || [[ -n "$line" ]]; do
#     gio list "$parent_folder/$line" | xargs -Ifilename echo "$parent_folder/$line/"filename >> $temp_list
#     echo "$line is read."
# done < $folders_list
# echo "deleting files now..."
# while IFS='' read -r line || [[ -n "$line" ]]; do
#     echo $line &&
#     rm -r "$line"
# done < $temp_list
# rm $temp_list

## Move things
temp_list=/home/$USER/.phonetempfiles
echo "" > $temp_list
folders_list=$bashscripts/phone_places_move.lst
while IFS='' read -r line || [[ -n "$line" ]]; do
    ls "$parent_folder/$line" | xargs -Ifilename echo "$parent_folder/$line/"filename >> $temp_list
    echo "$line is read."
done < $folders_list
while IFS='' read -r line || [[ -n "$line" ]]; do
    gio list "$parent_folder/$line" | xargs -Ifilename echo "$parent_folder/$line/"filename >> $temp_list
    echo "$line is read."
done < $folders_list
echo "moving files now..."
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo $line &&
    mv "$line" "$backup_folder"
done < $temp_list
rm $temp_list

# ## Copy things
# temp_list=/home/$USER/.phonetempfiles
# echo "" > $temp_list
# folders_list=/home/$USER/scripts/public/terminal/bash_scripts/phone_places_copy.lst
# while IFS='' read -r line || [[ -n "$line" ]]; do
#     ls "$parent_folder/$line" | xargs -Ifilename echo "$parent_folder/$line/"filename >> $temp_list
#     echo "$line is read."
# done < $folders_list
# while IFS='' read -r line || [[ -n "$line" ]]; do
#     gio list "$parent_folder/$line" | xargs -Ifilename echo "$parent_folder/$line/"filename >> $temp_list
#     echo "$line is read."
# done < $folders_list
# echo "copying files now..."
# while IFS='' read -r line || [[ -n "$line" ]]; do
#     echo $line &&
#     cp "$line" "$backup_folder"
# done < $temp_list
# rm $temp_list
