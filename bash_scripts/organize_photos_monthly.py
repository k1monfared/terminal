import os
import time
import shutil
from PIL import Image
import argparse

def get_image_creation_datetime(path):
    with Image.open(f.path) as image:
        cdt = time.strptime(image.getexif().get(306), "%Y:%m:%d %H:%M:%S")
    return(cdt)

def create_folder_if_not_exists(path, verbose = True):
    if not os.path.exists(path):
        if verbose:
            print("creating folder '{}'...".format(path))
        os.mkdir(path)
    return

def move_all(f, directory, associated_exts = [], verbose = True):
    cdt = get_image_creation_datetime(f.path)
    month_folder = time.strftime("%Y-%m", cdt)
    create_folder_if_not_exists(os.path.join(directory, month_folder), verbose = verbose)
    shutil.move(
        f.path,
        os.path.join(directory, month_folder, f.name)
    )
    if len(associated_exts):
        for ext in associated_exts:
            ass_filename = "{}.{}".format(
                f.name.split('.')[0],
                ext
            )
            npath = os.path.join(
                directory,
                ass_filename
            )
            if os.path.exists(npath):
                shutil.move(
                    npath,
                    os.path.join(directory, month_folder, ass_filename)
                )
    if verbose:
        print("moving '{}' to '{}'...        \r".format(f.name, month_folder), end = "")
    return

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Organize photos in this folder by their creation year-month.')
    parser.add_argument(
        'directory',
        metavar = 'd',
        type=str, nargs = '?',
        default = '',
        help='the address of the folder with photos in it'
    )

    args = parser.parse_args()
    if len(args.directory):
        directory = args.directory
    else:
        directory = os.getcwd()

    photo_exts = ['jpg', 'jpeg'] # case insensitive
    associated_exts = ['CR3.xmp', 'CR3'] # CASE SENSITIVE

    print("Organizing the photos in '{}' into folders YYYY-mm".format(directory))
    print("Photo extensions: {} (case insensitive)".format(', '.join(photo_exts)))
    if len(associated_exts):
        print("Associated extensions: {} (Case seSitivE)".format(', '.join(associated_exts)))

    for f in os.scandir(directory):
        if f.is_file:
            ext = f.name.split('.')[-1].lower()
            if len(ext):
                if ext in photo_exts:
                    move_all(f, directory, associated_exts = associated_exts, verbose = True)
    print('Done.                                      ')
