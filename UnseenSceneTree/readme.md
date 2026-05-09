# Unseen Scene Tree:

Unseen Scene Treer is an accessibility addon for the Unseen Godot project, which annotates every Tree control in the editor with depth and expand/collapse state so screen readers have more context when navigating.

# Features:
1. Any Tree that gains focus has all its items updated with an accessibility description, it refreshs as needed.
2. Each item's description includes its nesting depth (e.g. "Level:2").
3. Items with children also report whether they are "Expanded" or "Collapsed".
4. On Windows, the description is just the tag (e.g. "Collapsed Level:1"), since Windows screen readers read the item name separately. On other platforms, the name is prepended to the description.
