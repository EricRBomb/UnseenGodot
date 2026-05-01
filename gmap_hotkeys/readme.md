Gmap Hotkeys:
	
	Gmap hotkeys it the baseline accessiblity addon for the Unseen Godot project, which is to leverage the AccessKit integration to make the Godot Editor easier for devs using screen readers.
	
	It adds a variety of new hotkeys, and changes baseline functionality of focus to make interaction inside of Godot Editor more consistent.
	
	Hotkeys:
		All hotkeys at the moment need "gmap_ctrl" also held down, which is CTRL by default, but can be changed inside of plugin.gd easily.
		Can edit what keys are used as well in same place
		
		Goto Hotkeys:
			Goto Scene Tree : CTRL+1
			Goto Inspector : CTRL+2
			Goto Godot File System : CTRL+3
			Goto Bottom Panel Tabs : Ctrl+4 - (Output, Debugger,Audio, Animation, Shader Editor, and search Results are accessed from these tabs)
			Goto Signals Tab : Ctrl + 5
			Goto menu bar : Ctrl + 6 - (Scene, Project, Debug, Editor, and help are all located here)
			Goto open scene tab bar : Ctrl + 7 (lists all open scenes)
			Goto Import tab: Ctrl + 8
			Goto Method list: Ctrl + 9 (Lists all methods in currently open script in editor)
		Specific hotkeys:
			Find script: Ctrl+shift+ = (When focused on scene, go to script, or create script button if no script)
			Go up tree: Ctrl+U (Goes to first focusable control node of a UI element, if already on that node, attempts to go to first focusable UI element of the parent)
			Get focus: Ctrl+0 (Prints in output TAB information on what is focused)
			Move audio bus: Ctrl + . (Moves the focused audio bus forward one spot, or to front if already last.)
			Toggle 2D scene editor: Ctrl+F6 (It's off by default, I promise this is off for a reason, but it's good for if working with others.)
	Focus Changes:
		1. VBOX and HBOX containers get a script that makes it whenever they are focused, each item is hard focused so each item is neighbor of next sibling in list.
			1.1 registers these scripts as GmVBoxContainer and GmHBoxContainer so can be selected as items.
		2. 2D canvas editor is disabled, otherwise whenever a node is created the 2D scene editor will take focus (and tell you that it's not accessible, so why are you focusing it?)
		3. Disabled ability to focus on dragger UI elements via keyboard
		4. Disabled ability to focus on scroll bars via keyboard
		5. TextureButtons and empty-text BaseButtons automatically have their tooltip_text assigned as their accessibility_description
		6. Made the error bar be assertive live field when changing, and have an SFX that plays when a new one appears or clears.
		7. Audio bus and their children are made accessible and have tool tip set as their accessibilty text if no accessibility text, and minimum steps are changed so keyboard works to edit
		8. Scene tree no longer has a concept of "selected" and "focused", if it's focused, it's selected. You can't focus on the "tree" directly, it always kicks you to the root node if it otherwise would be focused.
		9. error_runtime_check() system that monitors the debugger's runtime error label and plays an alert SFX when a new runtime error appears. 
		
