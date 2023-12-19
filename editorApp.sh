#!/bin/zsh

# Arguments:
# $1 -- the filespec of the editor app, e.g., /Applications/CoolGUInvim.app
# $2 -- the filespec(s) of the file(s) to be edited, passed by Finder

# Get the `Executable file` value, e.g., cooledit, from the app's Info.plist:
editor_name="$(defaults read "$1/Contents/Info.plist" CFBundleExecutable)"

if [[ -z $(pgrep $editor_name) ]]; then
    # editor not open; launch it.
    export FINDER_LAUNCH=1 # config code may test existence of this env variable
    open -a $1/Contents/MacOS/$editor_name
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
                        --remote-send "<C-\><C-n><cmd>e $2<CR>"
fi

open -a $1/Contents/MacOS/$editor_name # editor to front if wasn't already

# ${TMPDIR}nvim.$USER/ contains directories containing base socket file(s) names.
# Socket files names: name.process ID.count where:
#    name is $editor_name or "nvim"
#    process ID is nvim's process ID
#    count is a 0-based sequence number of this socket instance
# E.g., a socket file: tmp/nvim.username/randomletters/cooledit.1234.1
