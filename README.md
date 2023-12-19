# editorOpen

## Create a MacOS application that makes neovim GUI editor applications Finder-friendly

### 1. Purpose

The created application is hereinafter called "editorOpen" and will normally be editorOpen.app in the Applications folder. It is intended to be Finder's default application for types of files to be opened in a neovim GUI editor such as Neovide or goneovim that don't otherwise always cooperate with Finder. editorOpen allows files to be opened in such a GUI editor via Finder, regardless of whether the editor was previously open.

If the default application for the file(s) to be opened is not editorOpen, it/they can still  be opened in the target editor by choosing "Open with..." from Finder's context (right-click) menu.

### 2. Building editorOpen.app

The guts of editorOpen.app is a zsh script that opens its argument file(s) in the target nvim GUI editor app. A MacOS "applet" application created by Apple's Automator utility runs the script. Herein the script's name is editorApp.sh, but the name is significant only in the Automator-built .app so you can change it if you like (step 8):

(1) Open Automator;  
(2) File::New (Cmd-N);  
(3) Select the "Application" icon;  
(4) Click "Choose";  
(5) Type "shell" into the search field at the top of the actions list;  
(6) Double-click the "Run Shell Script" action;  
(7) Choose "as arguments" from the "Pass input:" menu;  
(8) In the default code _replace_ the line containing "echo" with one in this form:  
`/bin/zsh [path to editorApp.sh]  [path to target editor .app file] "$f"`  
(9) File::Save... or type Cmd-S;  
(10) Change the "Save As:" name to editorOpen.app (or a name of your choosing);  
(11) Click Save.

In step (8) the line of zsh code has four elements:

1. /bin/zsh -- our script requires zsh
2. the filespec of our script, e.g., ~/dev/editorOpen/editorApp.sh
3. the filespec of the target editor's .app file, e.g., /Applications/CoolGUIeditor.app
4. "$f" -- will be expanded by Automator to the filespec(s) passed by Finder

If you decide to use a different GUI editor app, open Automator, open editorOpen.app, change element 3, and Save.

### 3. Call vim.fn.serverstart(...) in your nvim config

Early in your nvim config call `vim.fn.serverstart(name)` where `name` is he "command name" of the target editor,. For example:

     if vim.g.neovide then
        vim.fn.serverstart('neovide')
        -- possibly other Neovide-specific init
     end
     if vim.g.goneovim then
         vim.fn.serverstart('goneovim')
         -- possibly other goneovim-specific init
     end

-- To find the "command name" for an .app: in Finder right-click on the .app, choose "Show Package Contents", open Contents, and open MacOS; the command name is the name of the file thus reached. (The directory structure within the .app package may vary somewhat among packages.)

### 4. Setting Finder's default application for editable files

Users of editorOpen who, for Finder-opened files, prefer a neovim GUI application, such as Neovide or goneovim, to terminal-based nvim will want to make editorOpen Finder's default application for opening source code and text file types.

Only two or three file types are easily set "manually" by opening a Finder Get Info window on an instance of a file type, specifying editorOpen as the application, and clicking Change All to affect all instances. But this process is tedious for a dozen or more types. There is a utility called `duti` that can automate setting default applications for a list of UTIs (Uniiform Type Identifiers) and filename extensions (e.g., `.lua`, `.py`, etc.) by feeding them to `duti` in a shell script. See an example of such a script, `do-duti.sh`, in this repo.

`duti` can be installed by Homebrew with `brew install duti`. Its github repo is
https://github.com/moretension/duti

### The `FINDER_LAUNCH` environment variable

editorOpen sets the evironment variable `FINDER_LAUNCH`. This may be used by your nvim config code to do, or avoid doing, something if nvim is running in a GUI application that is opening (a) Finder-selected file(s). For example, I have a Lua function that opens a floating-window instance of the nvim-tree plugin's file explorer at startup if nvim was not opened with (a) file(s) argument(s). At the start of that function I have:

     if vim.env.FINDER_LAUNCH ~= nil then
        return
     end

### 5. What editorOpen.sh does

It gets the shell command that opens that target editor application. If the target editor is not open, it sets the `FINDER_LAUNCH` environment variable and opens the editor application. Then it waits until it can find an RPC server socket for that application (see (3) above). If the wait times out, it merely opens the the GUI editor application. Otherwise, it sends keystrokes for an `edit [filespec(s)]` command to the instance of nvim embedded by the GUI application. Finally, it brings the target editor's window to the front.

### 6. Last words

I set up this small system to have the convenience of occasionally using Finder to open text-editable files in Neovide. At the time this repo became public I have tested only with Neovide and goneovim, and only on my Mac mini running Ventura; the files in this repo are the ones I am using. I welcome any questions, issue reports, or suggestions you may have.
