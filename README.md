Routes allow you to draw lines on the map(s) linking nodes together into an efficient farming route from existing databases.
Go to our Discord or GitHub page for support and contribution! We'll take push requests.
Quickstart

Video about configuring this addon.

Download and install these dependency AddOns:

Routes
GatherMate2
GatherMate2_Data
Enable the addon in "Escape > AddOns" with "Load out of date AddOns" enabled.
Use "/routes" to begin!
Import "GatherMate2" and data.
Create Routes or import them from other users.
Importing into GatherMate2:
Type "/gathermate2".
Go to "Import Data" and then to "GatherMate2Data" on the left.
If you already have gathering node data, select "Merge" from the "Import Style" dropdown, otherwise "Overwrite" works.
Select which sources you want to import (Mining, Herbalism, Fishing, ect.) and tick their respective boxes.
Hit the "Import GatherMate2Data" button on the bottom.
Creating your first route:
Type "/routes".
Go to "Add" on the left side.
Type the name of your route and press "Okay".
Select the zone you want to create a route in from the "Select Zone" dropdown.
Make sure the "GatherMate2" source has it's checkbox ticked.
Select which type of nodes should be used to create your route.
Hit the "Create Route" button.
You can now go to the zone and follow the generated route on your minimap.

Note: You can change line color in the "Line Settings" tab, hide routes, and adjust sizing and positioning, alongside other settings. Open your worldmap on the zone you just created a route in, and you will see a massive whirling of lines in red.

Changing & Optimizing Routes

Note: If you see spiky and star-shaped routes that are impossible to follow, you haven't optimized the route yet. Go into the route you created and optimize it using the instructions below.

Type "/routes".
Go to "Routes", the zone you made your route in, and your route name.
Click on the "Optimize Route" tab for your route.
Hit the "Cluster" button. This is advisable as most zones contain large amounts of nodes. Clustering will group nearby nodes and the default distance is easily viewable on the minimap.
Hit the "Foreground" button, this will try an optimization of the length of your route (you can see it being updated after it finishes if you use a map addon like Mapster).

Keep hitting the "Foreground" button to make the route more efficient.

Note: "Backdround" instead of "Foreground" is alternatively reccomended when you don't want your performance dipping while optimizing a route.


Features
Select node types to build a line upon, such as "GatherMate2".
Optimize your route using the "traveling salesmen problem" (TSP) and "ant colony optimization" (ACO) algorithm.
"Background" (non-blocking) and "Foreground" (blocking) optimization.
Select color, thickness, transparency, and visibility for each route.
For any route, new nodes will be added as optimally as possible.
Quick clustering algorithm to merge nearby nodes into a single traveling point.
Mark entire areas or regions as "out of bounds" or "Taboo" to routes, meaning your routes will ignore nodes in those areas and avoid cross them
Fubar plugin available to quickly access your routes.
Full in-game help file and FAQ.
Compatability
Cartographer_Waypoints
Chinchilla's Expander minimap
Gatherer
GatherMate2 (Author's preference!)
HandyNotes
SexyMap
TomTom
Download

The latest version of Routes is always available on these sites.
Curseforge - GitHub - WoWInterface - Discord

Contact

If you have any bugs or suggestions, please contact us on:

IRC: Grum or Xinhuan on [[irc://irc.freenode.org/wowace|irc://irc.freenode.org/wowace]]
Email: Grum (routes@grum.nl)
Email: Xinhuan (xinhuan@gmail.com)

PayPal donations are welcome!
