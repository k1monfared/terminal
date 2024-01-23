source_folder="/media/$USER/9C33-6BBD/DCIM/100CANON"
destination_folder="/home/$USER/Pictures/canon_m5"
mkdir -p -- "$destination_folder"
echo "copying from '$source_folder' to '$destination_folder'..."
cp -rv $source_folder/*.* "$destination_folder"

echo "copying is done. Please check the destination folder."
read -p "Shall I delete the source files? yes/{no} " delete_source
if [ "$delete_source" = yes ]; then
    echo "deleting files in '$source_folder'"
    rm -rv $source_folder/*.*
else
    echo "leaving the source files there"
fi

curr_dir=$PWD
cd "$destination_folder"
organize_photos_monthly.sh
cd "$curr_dir"
