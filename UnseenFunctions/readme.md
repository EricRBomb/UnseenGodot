# UnseenFunctions
	Adds singleton with scripts designed to make tasks that are tedious to be done by screenreader automatic.
	Call Scripts with GM.(function name)
	* Function: create_collide_rect(x :int,y: int, targ: Node,box: bool = false,col: Color = Color.BLACK):
		Used to create a collision rectangle via code
		Arguments:
			X/Y = Used to declare size of rectangle
			Targ = What node to attach it to, use SELF if running self
			box = If want a visual of the box to appear
			Color = What color to appear. Useful for sharing debug information or simple accessible graphics.
	* Function: add_event(event_name:String,new_key)
		Events allow more prescise checking if keys are pressed/released/etc. 
		This function allows for a simple  event to be added, as UI in project - project settings - Input map can be difficult
		Arguments:
			Name of the event, "Jump","Close", etc. What you will type in whenever you are calling the check.
			Key to check, look at key objects for more details.
		
	
	
