
# bash_scripts
A collection of projects and scripts around bash and shell


## bashrc_alisases 
Short little useful commmands 


### system

#### load private info

#### solving ibus access problem

#### shortcuts

### todo.txt

### apt

### note

### github

#### github gist

### libarary
`libby <odm_file_path>` will download the audiobook to current working directory.

`libby_list` lists all the odm files in `~/Downloads/` and gives a number to them so that you can use it to download easily

`libby_get <n>` will download the book numbered n in the list above. The `overdrive.sh` I have here is modified in a way that it also moves the `.odm` and `.metadata` and `.licence` files into hte book folder in case it is needed in the future. Specifically the .medata file is useful for building an index.

If you define the `audiobooks_folder` here then the books will be downloaded to this folder, otherwise it will be the current working directory where it is called
