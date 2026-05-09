# KEY TASKS:

## Creating a Scene
* ctrl+1 (If not in scene tab yet)
* Ctrl+N (Go to new scene tab)
* Ctrl+A (opens node menu)
* Can now pick the "root" node of the scene, starting in a text box to do searchs, press enter to create it once proper one is picked.
* Press enter right after creating, to rename it.

## Create/attach script:
* Ctrl+1 to go to scene tab
* Down until node you want to attach script to is highlighted
* Ctrl + = (equal sign)

# Important Default Godot Hotkeys

## Main screen movement
* Open help files: F1
* Open 2D editor: Ctrl+f1
* Open Unseen Seen Scene editor: Ctrl+f2 (replaces 3D editor)
* Open script editor: ctrl+f3
* Go to search bar of file systems: Ctrl alt + p 
* Edit/stop editing Item: Most editable items (text fields, spin boxes, renaming items) you toggle ability to edit on and off with Enter.
  
## Change selected scene/file

* If multiple scenes are open, move to next one: Ctrl + tab 
* If multiple scenes are open, move to previous one: Ctrl + shift + tab 
* Open full scenes list to be picked and opened: Ctrl + O
* Quick select scene: Ctrl+shift+o
* Quick open script: ctrl+alt+o
* Search all files: ctrl+p

* Go to search bar of active module if there is one: Ctrl+f
* Open quick open menu: Shift + alt + o
* Open quick pick scene list: Ctrl + shift + o
* Open quick pick script list: Ctrl + alt + o
* Open function search for script: ctrl + alt + f

## Running project
* Run current Scene: F6
* Run project: F5
* stop running project: f8

# GMAP hotkeys:
Press GMAP_CTRL + other key to use hotkey (Can be changed easily by editing variables in script)
* Goto Scene Tree : CTRL+1
* Goto Inspector : CTRL+2
* Goto Godot File System : CTRL+3
* Goto Bottom Panel Tabs : Ctrl+4 - (Output, Debugger,Audio, Animation, Shader Editor, and search Results are accessed from these tabs)
* Goto Signals Tab : Ctrl + 5
* Goto menu bar : Ctrl + 6 - (Scene, Project, Debug, Editor, and help are all located here)
* Goto open scene tab bar : Ctrl + 7 (lists all open scenes)
* Goto Import tab: Ctrl + 8
* Goto Method list: Ctrl + 9 (Lists all methods in currently open script in editor)

# Unseen Scene Editor Hotkeys
All hotkeys require CTRL held down. Keys can be changed in grid_editor_plugin.gd.

* CTRL+F2 : Open the Unseen Grid tab
* CTRL+E  : Jump to the grid cell of the currently selected node
* ALT+T  : Focus the Cell Size input
## Grid cell hotkeys 
Used when a cell/node in scene editor is focused
* Space     : Select the node at this cell (opens a popup if multiple nodes share the cell)
* Ctrl+C    : Copy the node(s) at this cell
* Ctrl+X    : Cut the node(s) at this cell
* Ctrl+V    : Paste copied/cut node(s) to this cell's world position
# Unseen Inspector addon
* CTRL + Left: goes to first focusable parent in inspector of current node
* CTRL + Down: Goes to next item of the same type you are focused on. 
* Ctrl + up: Goes to previous item of the same type you are foucsed on.
# Step logger
Step logger is disabled by default in template project.
When enabled, it logs all key presses.
* CTRL+D enables "tutorial" mode, which logs steps taken instead of just every press
