Smoove V0.92

Pixel, Tile and Spriteeditor for PSPLua.
(c) 2006 Martin Wisniowski (020200 aka Nodepond)
http://digitaltools.node3000.com/downloads/smoove/


///////////////////////////////////////WHAT IS SMOOVE?/////////

Smoove is a pixel, tile and sprite-editor for the Sony PSP equipped with Lua.
You can read, write and edit .PNG-Files.

~Features
- Pixeleditor
- Zoomedit
- Animation-Editor
- Copy buffer
- Open Files (.PNG)
- Save Files (.PNG)
- Create tiles, sprites and pixelartworks
- Creates grafic files compatible to classic 2d games. Instantly ready to use as sprite and tile maps in any gameproject.

~Requirements
- Sony PSP (with firmware hack)
- Luaplayer V0.16 (tested) or higher (untested yet)

~Credits
made by
Martin Wisniowski (020200) build upon HSV by e-ma.


///////////////////////////////////////DOCUMENTATION/////////

~Install
To run smoove you will need a Sony PSP with Luaplayer installed.
Get more infos about PSPLua at PSPLua.com or fanjita.org.

To install smoove do the following:
- unzip the contents of the smoove-package
- connect to your PSP via USB
- go to the ./GAME/Luaplayer/Applications/ folder
- copy the contents of the smoove-package into it.
That's all

To start smoove on your PSP go to the luaplayer and start smoove.lua from the luaplayer-browser.


~Usage
Basic concept - Less is more

Button driven - smoove has just very few menues, but makes intense usage of the controller keys on the PSP. Once masted the keys, you can work very quickly in a great short-cut driven style.

Work on canvas - You will work directly on the canvas, or the .PNG-file, that will be used in your future game project (read: this will be the grafic file, where you will read the sprite- oder tile-data from).

~Controls
Draw mode and animation menu
There are two modes: draw mode and animation menu. To toggle between them, press the select button.

~Control Reference
Draw mode
analog stick - move cursor
digital pad - move cursor

circle - draw pixel
cross - erase pixel
triangel (hold) - open color selection
triangel (release) - chooses color
square (hold) - select zoom area
square (release) - go to zoom selection
square (press again) - go back to unzoomed view (fills the zoomed content into copybuffer)

select - go to animation menue

R - pick current color
L (in zoom mode) - pastes copy buffer

R (hold) + L - saves image
If no filename is given yet it opens the save as dialog.
start - Quits application and writes picture under te current name (or opens save as dialog).
digital pad up (hold) + start - quits application without saving the picture


~Animation menue
digital pad up and down - select option
circle - select option, if the cursor changes color: move left/right to select value
The battery loading state (in percent) is shown at the top-right corner.

framesize - Press circle and then use the digital pad to select the framesize. Press circle again to return to menu.
open - Note, that you can open images with a size smaller than 480 x 272, but they will be saved in 480 x 272 size.
save - Press circle to save the recent image under recent name.
save as... - Select a new name to save. Up-/down selects char. Left-/right moves cursor. Triangle to add a char, square to delete char. Cross cancels operation. Circle will save the image.
clear screen - Circle clears the canvas.
set tiles - Press circle to get into set tiles mode. Press and hold square to select the frames to animate. Press cross or circle to apply.
framerate - Press circle and then use left-/right to select the framerate. Press circle again to return to menu.
Note: Using zoomed view does slow the animation down. The framerates are only accurate if no zoom is selected.
show tilesize - This will write the actual framesize into the graficfile on buttom left. Useful if you want to export yout pictures into a gameproject. Press circle to toggle option.
show zoom - Press circle to toggle zoom view. Unfortunately really slows the application down. Use this to debug your animations.

///////////////////////////////////////Version History/////////
V0.92 Martin Wisniowski(020200):
- usb connect
- changes at settiles
- added info urls

V0.91 Martin Wisniowski(020200)
Changes:
- quick load was replaced by quick save (keys L+R)
- battery loading state at animation menu
- enhanced datastructure (folder structure)
- changed icon.png
- minor bugfixes

V0.9 Initial release by Martin Wisniowski (020200)
known bugs:
Bug at settiles-selection

