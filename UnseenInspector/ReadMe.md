# unseen inspector
Changes how focus works in the inspector and adds navigation hot keys.

## Changes
All items in inspector can now be reached by pressing down, essentially being reorganized as a tree. 
Elements that can folded/unfolded will have their current status in their accessibility description
A "hotkey blocker" is added so ctrl+ (left/right/up/down) does not get picked up by other parts of software

## New shortcuts
Ctrl-Left will take you to the next focusable parent of currently focused node in inspector
Ctrl-Down will take you to the next item of the same type that has focus. If you are focused on a category, next category, etc.
Ctrl-up will take you to the previous item of the same type that has focus