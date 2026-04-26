# UnseenGodot
Addons for the Unseen godot project! An effort to use the screen reader support in godot to  make the Godot Editor fully blind accessible. 

For tutorials on making games and list of accessible resources, check out:
https://www.unseen-godot.com/

There are five addons in this project, examine the read me in each to learn more about that specific addon.
Listed in order of "Crucial" to "Some folks might like it"
## Usage:
Add desired addon to your "addons" folder in your project, then in project settings - plugins, activate them
OR
Import the zipped project file and save it to a new location, you will have a project with the first three addons enabled by default

## Addons:

### GMAP Hotkeys
Core addon, highly reccomended for all usage with screen readers.
Adds crucial hotkeys to quickly get to most important parts of editor
Changes how focus works so it's consistent across different parts of editor and makes more parts accessible
Add new debug accessibilty features

### Unseen Scene Tree
Modifies accessibility lables of items in trees to tell you what level it is at, and if it's exapnded or not if it has children so don't have to guess if the node you are focused on is a a child of the root node or another node.
Just trust it's miserable to interact with the scene tree at all without it.

### Unseen Grid Scene editor
Since the 2D scene editor is not accessible, creates a new window that allows editing of scenes in a spread sheet style allowing you to move them around. 
Does not allow editing of TileMap layers, but does report if a tile is detected in your space, and tells you if collision or not is enabled.
Not strictly needed, as through code and setting of control nodes as children you can make almost any game, but certain games this will be much nicer.

### Step Logger
When active, logs actions in rawlogs.txt, for reporting of issues/trouble shooting, and guide making. 
Has a tutorial mode you can toggle that will break down the steps in more tutorial human readable style

### Unseen Functions
Certain tasks in Godot are annoying to do through the UI, these are functions you can use to bypass some of them. Purely quality of life/speed.
