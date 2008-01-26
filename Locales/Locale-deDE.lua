-- Cartographer_Routes
-- deDE Localization file, by Stanzilla

local L = LibStub("AceLocale-3.0"):NewLocale("Routes", "deDE")
if not L then return end

L["Routes"] = true
L["routes"] = true -- slash command

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
L["Auto show/hide"] = "Auto. Anzeigen/Verstecken"
L["Auto show and hide routes based on your professions"] = "Automatisches Anzeigen und Verstecken in Abhängigkeite ihrer Berufe"
L["Use Auto Show/Hide"] = "Auto. Anzeigen/Verstecken benutzen"
L["Auto Show/Hide per route type"] = "Auto. Anzeigen/Verstecken nach Routentyp"
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
-- M for Mining, H for Herbs, F for fishing, G for Gas, T for Treasure
L["CartographerHerbalism"] = "H"
L["CartographerMining"] = "M"
L["CartographerFishing"] = "F"
L["CartographerTreasure"] = "T"
L["CartographerExtractGas"] = "G"
L["GatherMateHerb Gathering"] = "H"
L["GatherMateMining"] = "M"
L["GatherMateFishing"] = "F"
L["GatherMateExtract Gas"] = "G"
L["GathererMINE"] = "M"
L["GathererHERB"] = "H"
L["GathererOPEN"] = "T"

-- Node types
L["Herbalism"] = "Kräuterkunde"
L["Mining"] = "Bergbau"
L["Fishing"] = "Angeln"
L["Treasure"] = "Schätze"
L["ExtractGas"] = "Gas"

-- Route Config
L["Information"] = true
L["This route has |cFFFFFFFF%d|r nodes and is |cFFFFFFFF%d|r yards long."] = "Diese Route hat |cFFFFFFFF%d|r Knotenpunkte und ist |cFFFFFFFF%d|r yards lang."
L["This route has nodes that belong to the following categories:"] = "Diese Route enthält Knotenpunkte folgender Kategorien:"
L["This route contains the following nodes:"] = "Diese Route enthält folgende Knotenpunkte:"

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
L["Skill-Fishing"] = "Angeln"
L["Skill-Herbalism"] = "Kr\195\164uterkunde"
L["Skill-Mining"] = "Bergbau"
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
Wenn ich versuche eine Route zu erstellen bekomme ich die Meldung, dass keine Daten gefunden wurden. Was mache ich falsch?
|r
Es bedeutet genau das: Es wurden keine Daten gefunden, meistens weil das Addon nicht geladen oder im Standby Modus ist. Wenn Sie eines der |cffffff78Cartographer_<Beruf>|r Module benutzen, müssen diese Module geladen und aktiviert sein um Daten verfügbar zu machen.

Bitte beachten Sie, dass alle |cffffff78Cartographer_<Beruf>|r Module nur bei Bedarf geladen werden und |cffffff78Cartographer_Professions|r vorraussetzen um aktiviert zu werden.
|cFFFFFFFF
Könnt ihr einen Fortschrittsbalken einfügen, der anzeigt wie lange die Hintergrundoptimierung einer Route noch dauert?
|r
Nein, das ist leider nicht möglich, da der Optimierungsprozess ein nicht-linearer Algorithmus ist. Er funktioniert auf einer mehrflutigen Basis dessen Optimierungen immer auf der Vorrangegangenen aufbaut, bis er einen Punkt erreicht hat an dem die Verbesserungen zu gering wären.

Das ist ein bisschen so wie das |cffffff78Windows XP Festplatten Defragmentierungs|r Programm und dessen Fortschrittsbalken, der auch sinnlos ist, da er nur die % jedes Durchgangs anzeigt, aber nicht weiß wieviele Durchgänge es benötigt. Es könnten 3 Durchgänge oder auch 10 sein. Er hört auf wenn er denkt, dass er genug getan hat. Aus diesem Grund gibt es in der |cffffff78Vista|r Version keinen Fortschrittsbalken mehr.
|cFFFFFFFF
Plant ihr auch Gatherer oder Addons mit Questnotizen zu unterstützen?
|r
Im Falle von |cffffff78Gatherer|r gibt es ein klares Ja und ein Vielleicht fürs Questen.
|cFFFFFFFF
Wie führt Routes die Routenoptimierung aus?
|r
Routes benutzt einen |cffffff78Ant Colony Optimization|r (ACO) genannten Algorithmus, der eine Methode zur heuristischen/wahrscheinlichkeitstheoretischen Berechnung für optimale Graphen, basierend auf den Beobachtungen des Verhaltens von Ameisen aus dem echten Leben, darstellt.

ACO Algorithmen wurden dazu benutzt um fast optimale Lösungen für das |cffffff78Traveling Salesman Problem|r (TSP) zu finden. Für weitere Informationen, befragen Sie bitte Google oder Wikipedia.
|cFFFFFFFF
Was macht die "Extra Optimierung" Option?
|r
Standardmäßig benutzen wir ACO nur mit dem Standard |cffffff782-opt Algorithmus|r um Routen zu optimieren. Wenn Sie "Extra Optimierung" anschalten, wird Routes auch 2.5-opt verwenden, der eine spezielle Untermenge von 3-opt ist. 2-opt ist der Prozess bei dem paarweise angeordnete Ecken ausgetauscht werden (A-B und C-D werden zu A-C und B-D) um kürzere Routen zu produzieren.
|cFFFFFFFF
Ich habe einen Fehler gefunden! Wo kann ich ihn melden?
|r
Hier können Sie Fehler melden oder Vorschläge abgeben: |cffffff78http://www.wowace.com/forums/index.php?topic=10992.0|r

Alternativ finden Sie uns auch auf |cffffff78irc://irc.freenode.org/wowace|r

Wenn Sie einen Fehler melden, fügen Sie bitte die |cffffff78nötigen Schritte an, die dazu nötig sind den Fehler zu reproduzieren|r. Geben Sie wenn möglich alle|cffffff78Fehlermeldungen|r mit Stapelspeicherverfolgungen, die |cffffff78Revisions Nummer|r von Routes, in der das Problem auftrat, sowie die |cffffff78Sprachversion ihres WoW-Spiels|r an.
|cFFFFFFFF
Wer hat dieses coole Addon geschrieben?
|r
|cffffff78Xaros|r von EU Doomhammer Allianz & |cffffff78Xinhuan|r von US Blackrock Allianz waren es.
]]

-- vim: ts=4 noexpandtab
