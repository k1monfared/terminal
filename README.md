
# bash_scripts
A collection of projects and scripts around bash and shell


## bashrc_alisases 
Little useful commmands 


### system

#### load private info

#### solving ibus access problem


#### shortcuts
Can't remember everything

### todo.txt
Dealing with todo.txt

### apt
Update repos, upgrade packages, or remove them.

### note
Create a note quickly and keep a list of them with the ability to search full text and to retrive the last note.


### github
Instead of typing 3 commands all the time...

#### github gist
Create a gist, commit, and push it quickly.

### libarary
`libby <odm_file_path>` will download the audiobook to current working directory.

`libby_list` lists all the odm files in `~/Downloads/` and gives a number to them so that you can use it to download easily

`libby_get <n>` will download the book numbered n in the list above. The `overdrive.sh` I have here is modified in a way that it also moves the `.odm` and `.metadata` and `.licence` files into hte book folder in case it is needed in the future. Specifically the .medata file is useful for building an index.

If you define the `audiobooks_folder` here then the books will be downloaded to this folder, otherwise it will be the current working directory where it is called
