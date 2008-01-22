-- Cartographer_Routes
-- deDE Localization file

local L = LibStub("AceLocale-3.0"):NewLocale("Routes", "deDE")
if not L then return end

L["Routes"] "= true"
L["routes"] "= true" -- slash command


-- Profession Names in the skills tab in the character frame
-- Doing these 4 localizations specifically to avoid using Babble-Spell
L["Skill-Fishing"] = "Angeln"
L["Skill-Herbalism"] = "Kr\195\164uterkunde"
L["Skill-Mining"] = "Bergbau"
L["Skill-Engineering"] = "Ingenieurskunst"

-- Options Config
L["Options"] = "Optionen"
L["Update distance"] = "Update Distanz"
L["Yards to move before triggering a minimap update"] = "Yards die man gehen muss um ein Minimap Update auszulösen"

-- Map drawing
L["Map Drawing"] = "Karten Zeichnung"
L["Toggle drawing on each of the maps."] = "Zeichnen auf jeder der Karten an- und ausschalten"
L["Worldmap"] = "Weltkarte"
L["Worldmap drawing"] = "Auf der Weltkarte zeichnen"
L["Minimap"] = "Minimap"
L["Minimap drawing"] = "Auf der Minimap zeichnen"
L["Zone Map"] = "Zonenkarte"
L["Zone Map drawing"] = "Auf der Zonenkarte zeichnen"
L["Set the width of lines on each of the maps."] = "Setze die Breite der Linien auf jeder der Karten"
L["Normal lines"] = "Normale Linien"
L["Width of the line in the Worldmap"] = "Breite der Linien auf der Weltkarte"
L["Width of the line in the Minimap"] = "Breite der Linien auf der Minimap"
L["Width of the line in the Zone Map"] = "Breite der Linien auf der Zonenkarte"
L["Color of lines"] = "Farbe der Linien"
L["Default route"] = "Standardroute"
L["Change default route color"] = "Ändere die Standardfarbe einer Route"
L["Hidden route"] = "Versteckte Route"
L["Change default hidden route color"] = "Ändere die Standardfarbe einer versteckten Route"
L["Show hidden routes"] = "Zeige versteckte Routen"
L["Show hidden routes?"] = "Versteckte Routen anzeigen?"

-- Auto show/hide
L["Auto show/hide"] = "Automatischesn Anzeigen/Verstecken"
L["Auto show and hide routes based on your professions"] = "Automatisches Anzeigen und Verstecken in Abhängigkeite ihrer Berufe"
L["Use Auto Show/Hide"] = "Automatisches Anzeigen/Verstecken benutzen"
L["Auto Show/Hide per route type"] = "Automatisches Anzeigen/Verstecken nach Routentyp"
L["Auto Show/Hide settings"] = "Einstellungen für Automatisches Anzeigen/Verstecken"
L["Routes with Fish"] = "Routen mit Fischen"
L["Routes with Gas"] = "Routen mit Gasen"
L["Routes with Herbs"] = "Routen mit Kräutern"
L["Routes with Ore"] = "Routen mit Erzen"
L["Routes with Treasure"] = "Routen mit Schätzen"
L["Always show"] = "Immer anzeigen"
L["Only with profession"] = "Nur mit Beruf"
L["Only while tracking"] = "Nur wenn man danach sucht"
L["Never show"] = "Niemals anzeigen"

-- Waypoints
L["Waypoints (Carto)"] = "Wegpunkte (Carto)"
L["Integrated support options for Cartographer_Waypoints"] = "Integrierte Optionen für Cartographer_Waypoints"
L["This section implements Cartographer_Waypoints support for Routes. Click Start to find the nearest node in a visible route in the current zone.\n"] = "Dieser Bereich implementiert Cartographer_Waypoints Unterstützung in Routes. Klicken Sie Start um den nächsten Knotenpunkt einer sichtbaren Route in der momentanen Zone zu finden"
L["Waypoint hit distance"] = true
L["This is the distance in yards away from a waypoint to consider as having reached it so that the next node in the route can be added as the waypoint"] = "Das ist die Distanz in Yards die einen Wegpunkt als erreicht vermeldet um den nächsten Knotenpunkt als Wegpunkt hinzuzufügen."
L["Change direction"] = "Richtung ändern"
L["Change the direction of the nodes in the route being added as the next waypoint"] = "Ändert die Richtung der Knotenpunkte der Route die als nächster Wegpunkt hinzugefügt werden"
L["Start using Waypoints"] = "Wegpunkte benutzen"
L["Start using Cartographer_Waypoints by finding the closest visible route/node in the current zone and using that as the waypoint"] = "Beginne Cartographer_Waypoints zu nutzen um den/die nächsten sichtbaren Knotenpunkt/Route in der aktuellen Zone als Wegpunkt zu benutzen"
L["Stop using Waypoints"] = "Wegpunkte nicht mehr benutzen"
L["Stop using Cartographer_Waypoints by clearing the last queued node"] = "Beende die Nutzung von Cartographer_Waypoints indem der letzte Knotenpunkt in der Reihe gelöscht wird"

-- Add Route Config
L["Add"] = "Hinzufügen"
L["Routes in %s"] = "Routen in %s"
L["Name of Route"] = "Name der Route"
L["Name of the route to add"] = "Name der Route die hinzugefügt werden soll"
L["No name given for new route"] = "Kein Name für neue Route angegeben"
L["Select Zone"] = "Zone auswählen"
L["Zone to create route in"] = "Zone in der die Route erstellt werden soll"
L["Select sources of data"] = "Quelle der Daten auswählen"
L[" Data"] = " Daten"
L["Select data to use"] = "Wähle welche Daten genutzt werden sollen"
L["Select data to use in the route creation"] = "Wähle die Daten die bei der Routenerstellung benutzt werden sollen"
L["No data found"] = "Keine Daten gefunden"
L["Create Route"] = "Route erstellen"
L["No data selected for new route"] = "Keine Daten für neue Route ausgewählt"
L["A route with that name already exists. Overwrite?"] = "Eine Route mit diesem Name existiert bereits. Überschreiben?"

-- DB prefix abbreviations 
L["CartographerHerbalism"] = "H"
L["CartographerMining"] = "M"
L["CartographerFishing"] = "F"
L["CartographerTreasure"] = "T"
L["CartographerExtractGas"] = "G"
L["GatherMateHerb Gathering"] = "H"
L["GatherMateMining"] = "M"
L["GatherMateFishing"] = "F"
L["GatherMateExtract Gas"] = "G"

-- Node types
L["Herbalism"] = "Kräuterkunde"
L["Mining"] = "Bergbau"
L["Fishing"] = "Angeln"
L["Treasure"] = "Schätze"
L["ExtractGas"] = "Gas"

-- Route Config
L["Information"] = true
L["This route has |cFFFFFFFF%d|r nodes and is |cFFFFFFFF%d|r yards long."] = "Diese Route hat |cFFFFFFFF%d|r Knotenpunkte und ist |cFFFFFFFF%d|r yards lang."
L["This route has nodes that belong to the following categories:\n"] = "Diese Route enthält Knotenpunkte folgender Kategorien:\n"
L["This route contains the following nodes:\n"] = "Diese Route enthält folgende Knotenpunkte:\n"

L["Line settings"] = "Linieneinstellungen"
L["These settings control the visibility and look of the drawn route."] = "Diese Einstellungen kontrollieren die Sichtbarkeit und das Aussehen der gezeichneten Route"
L["Width (Map)"] = "Breite (Karte)"
L["Width of the line in the map"] = "Breite der Linie auf der Karte"
L["Width (Minimap)"] = "Breite (Minimap)"
L["Width of the line in the Minimap"] = "Breite der Linie auf der Minimap"
L["Width (Zone Map)"] = "Breite (Gebietskarte"
L["Width of the line in the Zone Map"] = "Breite der Linie auf der Gebietskarte"
L["Line Color"] = "Linienfarbe"
L["Change the line color"] = "Linienfarbe ändern"
L["Hide Route"] = "Route verstecken"
L["Hide the route from being shown on the maps"] = "Verstecke die Route auf den Karten"
L["Delete"] = "Löschen"
L["Permanently delete a route"] = "Eine Route gänzlich löschen"
L["Are you sure you want to delete this route?"] = "Sind Sie sicher, dass Sie diese Route löschen möchten?"
L["You may not delete a route that is being optimized in the background."] = "Sie können keine Route löschen, die gerade im Hintergrund optimiert wird"
L["Reset"] = "Zurücksetzen"
L["Reset the line settings to defaults"] = "Setzt die Linieneinstellungen auf ihre Ursprungswerte zurück"

L["Optimize route"] = "Route optimieren"
L["Extra optimization"] = "Extra Optimierung"
L["ExtraOptDesc"] = "Wenn Sie diese Option aktivieren, dauert das Optimieren der Route ungefähr 40% länger, aber es wird eine -leicht- bessere Route generiert. Empfohlene Einstellung ist AUS."
L["Foreground"] = "Vordergrund"
L["Foreground Disclaimer"] = "Generiert fast optimalen Weg für alle Knotenpunkte der Route. Bitte beachten Sie, dass dieser Prozess ihr Spiel für kurze Zeit zum hängen bringt, je nachdem wieviele Knotenpunkte (mehrere sorgen für eine fast exponentiale Erhöhung)und wie schnell ihre CPU ist, könnte es sogar sein, dass ihre Verbindung unterbrochen wird, wenn es zulange dauert."
L["Background"] = "Hintergrund"
L["Background Disclaimer"] = "Diese Option wird die TSP Routengenerierung im Hintergrund ausführen ohne ihr Spiel zum hängen zu bringen, ist dafür aber wesentlich langsamer. Bitte seien Sie sich bewusst, dass ihr WoW in dieser Zeit an Geschwindigkeitsverlust leiden wird."
L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."] = "Pfad mit %d Knotenpunkten gefunden mit der Länge von %.2f yards nach %d Durchgängen in %.2f Sekunden"
L["Now running TSP in the background..."] = "Führt TSP jetzt im Hintergrund aus..."
L["There is already a TSP running in background. Wait for it to complete first."] = "Es läuft schon eine TSP im Hintergrund. Bitte warten Sie, bis die erste abgeschlossen ist."
L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"] = "Der folgende Fehler trat bei der Berechnung des Pfades auf, bitte melden Sie ihn bei Grum oder Xinhuan:"

-- Profession Names in the skills tab in the character frame
-- Doing these 4 localizations specifically to avoid using Babble-Spell
L["Skill-Fishing"] = "Angeln""
L["Skill-Herbalism"] = "Kräuterkunde""
L["Skill-Mining"] = "Bergbau""
L["Skill-Engineering"] = "Ingenieurskunst"

-- Cartographer_Waypoints support
L["Cartographer_Waypoints module is missing or disabled"] = "Das Cartographer_Waypoints Modul fehlt oder ist deaktiviert"
L["%s - Node %d"] = "%s - Knotenpunkt %d"
L["Direction changed"] = "Richtung geändert"

-- FAQ
L["FAQ"] = true
L["Frequently Asked Questions"] = true
L["FAQ_TEXT"] = [[
|cFFFFFFFF
When I try to create a route, it says no data is found. What am I doing wrong?
|r
It means exactly that: No data is found, mostly because the addon is not loaded or in standby mode. If you are using any of the |cffffff78Cartographer_<Profession>|r modules, then these modules must be loaded and active for data to be available.

Note that |cffffff78Cartographer_<Profession>|r modules are all Load on Demand addons and require |cffffff78Cartographer_Professions|r to be enabled as it is the loading stub.
|cFFFFFFFF
Can you make a progress indicator on how long a background route optimization would take?
|r
A progress bar is not possible for the optimization process as it is a non-linear algorithm. It works on a "multiple pass" basis, each pass improving on the previous pass until it reaches a point where the improvement made is too minimal and then it will stop.

This is somewhat like the |cffffff78Windows XP Disk Defragmentation|r utility, and its progress bar is worthless because its only showing you the % of each pass, but it doesn't know how many passes it will take, it could be 3 passes, it could be 10 passes, it stops only when it thinks it has done enough. This is why in the |cffffff78Vista|r version, it no longer shows you a progress bar at all.
|cFFFFFFFF
Do you plan on adding Gatherer support or perhaps questing addons node support?
|r
This is most likely a yes for |cffffff78Gatherer|r, and a maybe for questing.
|cFFFFFFFF
How does Routes perform its route optimization?
|r
Routes uses an algorithm called |cffffff78Ant Colony Optimization|r (ACO) which is a heuristic/probabilistic method of calculating optimal graphs based on observed real life ant behavior.

ACO algorithms have been used to produce near-optimal solutions to the |cffffff78Traveling Salesman Problem|r (TSP). For more information, consult Google or Wikipedia.
|cFFFFFFFF
What does the "Extra Optimization" option do?
|r
By default, we only used ACO along with the standard |cffffff782-opt algorithm|r to optimize routes. Turning on "extra optimization" tells Routes to also use 2.5-opt, which is a specific subset of 3-opt. 2-opt is the process where pairs of edges are exchanged (A-B and C-D becomes A-C and B-D) in order to produce shorter routes.
|cFFFFFFFF
I've found a bug! Where do I report it?
|r
You can report bugs or give suggestions at |cffffff78http://www.wowace.com/forums/index.php?topic=10992.0|r

Alternatively, you can also find us on |cffffff78irc://irc.freenode.org/wowace|r

When reporting a bug, make sure you include the |cffffff78steps on how to reproduce the bug|r, supply any |cffffff78error messages|r with stack traces if possible, give the |cffffff78revision number|r of Routes the problem occured in and state whether you are using an |cffffff78English client or otherwise|r.
|cFFFFFFFF
Who wrote this cool addon?
|r
|cffffff78Xaros|r on EU Doomhammer Alliance & |cffffff78Xinhuan|r on US Blackrock Alliance did.
]]

-- vim: ts=4 noexpandtab
