#!/bin/zsh

# Open the argument file in the most recent instance of the current nvim-based
# GUI editor such as Neovide or goneovim.
#
# This script is the guts of a MacOS "applet" application created by Apple's
# Automator utility. Open Automator, File::New (Cmd-N), select the "Application"
# icon, click "Choose", type "shell" into the search field at the top of the
# actions list, drag the "Run Shell Script" action onto the "Drag actions ..."
# destination to the right. Choose "as arguments" from the "Pass input:" menu,
# in the default code replace the line containing "echo" with one like this:
#   /bin/zsh /Users/your_username/dev/editorOpen/editorApp.sh "$f"
# i.e., code to run the script containing this comment. Then File::Save...
# (Cmd-S), change the "Save As:" name (mine is editorOpen.app), click Save.
#
# The application just created can be used as the Finder default or "Open with"
# application to open source files, text files, makefiles, etc., in the target
# GUI editor, e.g., Neovide, goneovim, etc. There are two more steps needed to
# accomplish that:
#
# (1) Early in your nvim config call vim.fn.serverstart(name) where name is
# the "command name" of the target editor, e.g., "neovide" or "goneovim". For
# example:
# if vim.g.neovide then
#    vim.fn.serverstart('neovide')
#    -- possibly other Neovide-specific init
# end
# if vim.g.goneovim then
#    vim.fn.serverstart('goneovim')
# end
# To find the "command name" for other nvim GUI apps: in Finder right-click on
# the editor .app, choose "Show Package Contents", and open Contents/MacOS.
#
# (2) create a file whose first line specifies the editor application, e.g.:
# /Applications/Neovide.app
# Then you can easily change which editor the Finder will open when you double-
# click a source or text file's icon, provided that editorOpen.app has been set
# as the application that Finder will use to open for the file to be edited. Use
# Finder "Get Info" for that. If necessary, change the following `app_path=`line
# to reflect the path and filename for your editor spec file:
app_path="$(head -n 1 ~/dev/editorOpen/editorApp.txt)"
# Get the `Executable file` value, e.g., myeditor, from the app's Info.plist:
editor_name="$(defaults read "$app_path/Contents/Info.plist" CFBundleExecutable)"

if [[ -z $(pgrep $editor_name) ]]; then
    # editor not open; launch it.
    # --arch for lazy-nvim or nvim-treesitter plugins on M1/M2 Macs on which 
    #        "Open using Rosetta" is not checked in Get Info for editor's .app
    export FINDER_LAUNCH=1 # config code may test existence of this env variable
    open -a $app_path/Contents/MacOS/$editor_name --arch=x86_64
--    sleep 1     # give editor time to open before we remote-send to it
fi

# Construct the path and filename of the server socket for the remote-send; for
# some details on nvim's server path/filename construction see `:h serverstart`
nvim_instances_dir=${TMPDIR}nvim.$USER  # see comments at end of this file
(( TIMEOUT = SECONDS + 3 ))
while [[ $SECONDS -lt $TIMEOUT ]]; do
    for instance_dir in $(ls -t $nvim_instances_dir/); do  # -t: most recent first
        for server in $(ls -t $nvim_instances_dir/$instance_dir/); do 
            if [[ $server == *"$editor_name"* ]]; then   # editor_name is substring?
                server_filespec=$nvim_instances_dir/$instance_dir/$server
                break 3     # we searched in recency order, so we're done
            fi
        done
    done
done

if [[ -v server_filespec ]]; then # if didn't time out waiting for server filespec
    # Send keys to nvim instance to effect `:e[dit]` for the file to be opened:
    /usr/local/bin/nvim --server $server_filespec \
                        --remote-send "<C-\><C-n><cmd>e $1<CR>"
fi

open -a $app_path/Contents/MacOS/$editor_name # editor to front if wasn't already

# ${TMPDIR}nvim.$USER/ contains directories containing base socket file(s) names.
# Socket files names: name.process ID.count where:
#    name is $editor_name or "nvim"
#    process ID is nvim's process ID
#    count is a 0-based sequence number of this socket instance
# E.g., a socket file: tmp/nvim.username/randomletters/neovide.1234.1
