-- Routes
-- frFR Localization file, by pettigrow

local L = LibStub("AceLocale-3.0"):NewLocale("Routes", "frFR")
if not L then return end

L["Routes"] = "Routes"
L["routes"] = "routes" -- slash command

-- Options Config
L["Options"] = "Options"
L["Update distance"] = "Distance de mise à jour"
L["Yards to move before triggering a minimap update"] = "Mètres à parcourir avant de déclencher une mise à jour de la minicarte."

-- Map drawing
L["Map Drawing"] = "Dessins des cartes"
L["Toggle drawing on each of the maps."] = "Dessins sur les cartes"
L["Worldmap"] = "Carte du monde"
L["Worldmap drawing"] = "Dessine ou non sur la carte du monde."
L["Minimap"] = "Minicarte"
L["Minimap drawing"] = "Dessine ou non sur la minicarte."
L["Zone Map"] = "Carte locale"
L["Zone Map drawing"] = "Dessine ou non sur la carte locale."
L["Set the width of lines on each of the maps."] = "Largeur des lignes sur les cartes"
L["Normal lines"] = "Lignes normales"
L["Width of the line in the Worldmap"] = "Détermine la largeur des lignes sur la carte du monde."
L["Width of the line in the Minimap"] = "Détermine la largeur des lignes sur la minicarte."
L["Width of the line in the Zone Map"] = "Détermine la largeur des lignes sur la carte locale."
L["Color of lines"] = "Couleurs des lignes"
L["Default route"] = "Routes par défaut"
L["Change default route color"] = "Change la couleur par défaut des routes."
L["Hidden route"] = "Routes masquées"
L["Change default hidden route color"] = "Change la couleur par défaut des routes masquées."
L["Show hidden routes"] = "Voir les routes masquées"
L["Show hidden routes?"] = "Affiche les routes masquées."
L["Line gaps"] = "Lignes découpées"
L["Shorten the lines drawn on the minimap slightly so that they do not overlap the icons and minimap tracking blips."] = "Raccourcit légèrement les dessins des lignes de la minicarte afin qu'elles ne se chevauchent pas les icônes et les spots du suivi."

-- Auto show/hide
L["Auto show/hide"] = "Afficher/masquer auto."
L["Auto show and hide routes based on your professions"] = "Affiche et masque automatiquement les routes selon vos métiers."
L["Use Auto Show/Hide"] = "Utiliser A./m. auto."
L["Auto Show/Hide per route type"] = "Afficher/masquer auto. par type de route"
L["Auto Show/Hide settings"] = "Paramètres de Afficher/masquer auto."
L["Routes with Fish"] = "Routes contenant des poissons"
L["Routes with Gas"] = "Routes contenant des gaz"
L["Routes with Herbs"] = "Routes contenant des herbes"
L["Routes with Ore"] = "Routes contenant des minerais"
L["Routes with Treasure"] = "Routes contenant des trésors"
L["Always show"] = "Toujours afficher"
L["Only with profession"] = "Si j'ai le métier"
L["Only while tracking"] = "Si le suivi est activé"
L["Never show"] = "Ne jamais afficher"

-- Waypoints
L["Waypoints (Carto)"] = "Navigation (Carto)"
L["Integrated support options for Cartographer_Waypoints"] = "Options concernant le support intégré de Cartographer_WayPoints."
L["This section implements Cartographer_Waypoints support for Routes. Click Start to find the nearest node in a visible route in the current zone.\n"] = "Cette section implémente le support de Cartographer_Waypoints pour Routes. Cliquez sur Commencer pour trouver le nœud le plus proche d'une route visible dans la zone actuelle."
L["Waypoint hit distance"] = "Distance d'atteinte du point"
L["This is the distance in yards away from a waypoint to consider as having reached it so that the next node in the route can be added as the waypoint"] = "Ceci est la distance en mètres entre vous et un point de navigation pour considérer ce dernier comme atteint, afin que le prochain nœud de la route puisse être considéré comme le nouveau point de navigation."
L["Change direction"] = "Changer de direction"
L["Change the direction of the nodes in the route being added as the next waypoint"] = "Change la direction des nœuds de la route ajoutés comme prochains points de navigation."
L["Start using Waypoints"] = "Commencer la navigation"
L["Start using Cartographer_Waypoints by finding the closest visible route/node in the current zone and using that as the waypoint"] = "Commence à utiliser Cartographer_Waypoints en trouvant le nœud/la route le/la plus proche de la zone actuelle et en l'utilisant comme point de navigation."
L["Stop using Waypoints"] = "Arrêter la navigation"
L["Stop using Cartographer_Waypoints by clearing the last queued node"] = "Arrête d'utiliser Cartographer_Waypoints en effacant le dernier nœud de la file."

-- Add Route Config
L["Add"] = "Ajouter"
L["Routes in %s"] = "Routes dans %s"
L["Name of Route"] = "Nom de la route"
L["Name of the route to add"] = "Indiquez le nom de la route à ajouter."
L["No name given for new route"] = "Aucun nom n'a été donné pour la nouvelle route."
L["Select Zone"] = "Sélection de la zone"
L["Zone to create route in"] = "Choissisez la zone où créer la route."
L["Select sources of data"] = "Sélection des sources des données"
L[" Data"] = " : Données"
L["Select data to use"] = "Sélection des données à utiliser"
L["Select data to use in the route creation"] = "Choissisez les données à utiliser pour la création de la route."
L["No data found"] = "Aucune donnée trouvée"
L["Create Route"] = "Créer la route"
L["No data selected for new route"] = "Aucune donnée n'a été sélectionnée pour la nouvelle route."
L["A route with that name already exists. Overwrite?"] = "Une route portant ce nom existe déjà. L'écraser ?"

-- DB prefix abbreviations 
-- M pour Minage, H pour Herbes, P pour Pêche/Poisson, G pour Gaa, T pour Trésor
L["CartHerbalism"] = "H"
L["CartMining"] = "M"
L["CartFishing"] = "P"
L["CartTreasure"] = "T"
L["CartExtractGas"] = "G"
L["GMHerb Gathering"] = "H"
L["GMMining"] = "M"
L["GMFishing"] = "P"
L["GMExtract Gas"] = "G"
L["GathererMINE"] = "M"
L["GathererHERB"] = "H"
L["GathererOPEN"] = "T"

-- Node types
L["Herbalism"] = "Herboristerie"
L["Mining"] = "Minage"
L["Fishing"] = "Pêche"
L["Treasure"] = "Trésor"
L["ExtractGas"] = "Gaz"

-- Route Config
L["When the following data sources add or delete node data, update my routes automatically by inserting or removing the same node in the relevant routes."] = "Quand les sources de données suivantes ajoutent ou suppriment des données d'un nœud, mettre à jour automatiquement mes routes en insérant ou en enlevant ce même nœud des routes appropriées."
L[" Gatherer currently does not support callbacks, so this is impossible for Gatherer."] = " Gatherer ne supporte pas actuellement les callbacks, c'est donc impossible avec cet addon."
L["You have |cFFFFFFFF%d|r route(s) in |cFFFFFFFF%s|r."] = "Vous avez |cFFFFFFFF%d|r route(s) à |cFFFFFFFF%s|r."
L["Information"] = "Informations"
L["This route has |cFFFFFFFF%d|r nodes and is |cFFFFFFFF%d|r yards long."] = "Cette route contient |cFFFFFFFF%d|r nœuds et est longue de |cFFFFFFFF%d|r mètres."
L["This route has nodes that belong to the following categories:\n"] = "Cette route contient des nœuds des catégories suivantes :\n"
L["This route contains the following nodes:\n"] ="Cette route contient les nœuds suivants :\n"

L["Line settings"] = "Paramètres des lignes"
L["These settings control the visibility and look of the drawn route."] = "Ces paramètres contrôlent la visibilité et le look des routes dessinées."
L["Width (Map)"] = "Largeur (Carte)"
L["Width of the line in the map"] = "Détermine la largeur des lignes sur la carte du monde."
L["Width (Minimap)"] = "Largeur (Minicarte)"
L["Width of the line in the Minimap"] = "Détermine la largeur des lignes sur la minicarte."
L["Width (Zone Map)"] = "Largeur (Carte locale)"
L["Width of the line in the Zone Map"] = "Détermine la largeur des lignes sur la carte locale."
L["Line Color"] = "Couleur des lignes"
L["Change the line color"] = "Change la couleur des lignes."
L["Hide Route"] = "Route masquée"
L["Hide the route from being shown on the maps"] = "Masque la route afin qu'elle ne soit pas affichée sur les cartes."
L["Delete"] = "Supprimer"
L["Permanently delete a route"] = "Supprime définitivement une route."
L["Are you sure you want to delete this route?"] = "Êtes-vous sûr de vouloir supprimer cette route ?"
L["You may not delete a route that is being optimized in the background."] = "Vous ne pouvez pas supprimer une route qui est en cours d'optimisation en arrière-plan."
L["Reset"] = "Réinitialiser"
L["Reset the line settings to defaults"] = "Réinitialise les paramètres des lignes à leurs valeurs  par défaut."

L["Optimize route"] = "Optimiser la route"
L["Extra optimization"] = "Extra optimisation"
L["ExtraOptDesc"] = "Activer cette option rendra le temps de génération 40% plus long, mais les routes générées seront -légèrement- meilleures. Il est recommandé de laisser ceci désactivé."
L["Foreground"] = "Avant-plan"
L["Foreground Disclaimer"] = "Génère un chemin pratiquement optimal pour l'ensemble des nœuds de cette route. Veuillez noter qu'en faisant ceci, votre client WoW restera 'bloqué' pendant quelques temps. Selon le nombre de nœuds (en ajouter cause une augmentation de durée pratiquement exponentielle) et la vitesse de votre CPU, vous risquez d'être déconnecté si cela prend trop longtemps."
L["Background"] = "Arrière-plan"
L["Background Disclaimer"] = "Ceci effectuera la génération de la route TSP en arrière-plan plus lentement, mais sans bloquer votre client WoW. Veuillez noter que votre client WoW subira tout de même une baisse de performance."
L["Path with %d nodes found with length %.2f yards after %d iterations in %.2f seconds."] = "Chemin de %d nœuds trouvé avec une longueur de %.2f mètres après %d itérations en %.2f secondes."
L["Now running TSP in the background..."] = "Exécution du TSP en arière-plan en cours..."
L["There is already a TSP running in background. Wait for it to complete first."] = "Il y a déjà un TSP en cours en arrière-plan. Veuillez attendre que ce dernier soit terminé."
L["The following error occured in the background path generation coroutine, please report to Grum or Xinhuan:"] = "L'erreur suivante est survenue dans la co-routine de génération du chemin en arrière-plan, veuillez le signaler à Grum ou Xinhuan : "

-- Profession Names in the skills tab in the character frame
-- Doing these 4 localizations specifically to avoid using Babble-Spell
L["Skill-Fishing"] = "Pêche"
L["Skill-Herbalism"] = "Herboristerie"
L["Skill-Mining"] = "Minage"
L["Skill-Engineering"] = "Ingénierie"

-- Cartographer_Waypoints support
L["Cartographer_Waypoints module is missing or disabled"] = "Le module Cartographer_Waypoints est manquant ou désactivé."
L["%s - Node %d"] = "%s - Nœud %d"
L["Direction changed"] = "Direction changée"

-- FAQ
L["FAQ"] = "FAQ"
L["Frequently Asked Questions"] = "Foire aux questions"
L["FAQ_TEXT"] = [[
|cFFFFFFFF
Quand je tente de créer une route, l'addon m'indique qu'aucune donnée n'a été trouvée. Où me suis-je trompé ?
|r
Cela signifie ce que cela dit : aucune donnée n'a été trouvée, sûrement parce que l'addon n'est pas chargé ou en mode veille. Si vous utilisez un des modules |cffffff78Cartographer_<Métier>|r, il faut alors que ces modules soient chargés et actifs pour que les données soient disponibles.

Notez que les modules |cffffff78Cartographer_<Métier>|r sont tous des addons chargeables à la demande et nécessitent |cffffff78Cartographer_Professions|r pour être chargés.
|cFFFFFFFF
Pouvez-vous ajouter un indicateur de progression afin de connaître la durée de l'optimisation de la route en arrière-plan ?
|r
Une barre de progression n'est pas possible pour le processus d'optimisation étant donné qu'il s'agit d'un algorithme non-linéaire. Il fonctionne selon le principe des "passes multiples", chaque passe améliore la passe précédente jusqu'au point où les améliorations sont tellement infimes qu'il est inutile de continuer.

C'est un peu comme l'utilitaire de |cffffff78défragmentation de disque de Windows XP|r où la barre de progression est inutile car elle n'affiche que le pourcentage de chaque passe, pas le nombre de passes qui seront effectuées. Il peut y avoir 3 passes comme 10 passes : l'utilitaire ne stoppe que quand il pense qu'il a fait assez. C'est pour cela que sur la version de |cffffff78Vista|r, il n'y a plus du tout de barre de progression.
|cFFFFFFFF
Comptez-vous ajouter le support de Gatherer ou peut-être celui des addons de quêtes ?
|r
C'est presque certain pour |cffffff78Gatherer|r, et peut-être pour les quêtes.
|cFFFFFFFF
Comment Routes effectue-t-il ses optimisations des routes ?
|r
Routes utilise un algorithme appelé |cffffff78Algorithme de colonies de fourmis|r ("Ant Colony Optimization" en anglais ou "ACO"), qui est une méthode heuristique/probabiliste de calcul des graphes optimaux basé sur le comportement observé de ces insectes dans la vie réelle.

Les algorithmes ACO ont été utilisés pour produire des solutions quasi-optimales au |cffffff78problème du voyageur de commerce|r ("Traveling Salesman Problem" en anglais ou "TSP"). Pour plus d'informations, consultez Google ou Wikipedia.
|cFFFFFFFF
Quel est l'effet de l'option "Extra optimisation" ?
|r
Par défaut, nous utilisons seulement l'ACO couplé à |cffffff78l'algorithme 2-opt|r standard pour optimiser les routes. Activer "Extra optimisation" permet de demander à Routes d'utiliser également 2.5-opt, qui est un sous-ensemble de 3-opt. 2-opt est le processus où les couples des extrémités sont échangés (A-B et C-D deviennent A-C et B-D) afin de produire des routes plus courtes.
|cFFFFFFFF
J'ai trouvé un bogue ! Où puis-je le signaler ?
|r
Vous pouvez signaler des bogues ou faire des suggestions sur |cffffff78http://www.wowace.com/forums/index.php?topic=10992.0|r

Vous pouvez également nous trouver sur |cffffff78irc://irc.freenode.org/wowace|r

Quand vous voulez signaler un bogue, essayez de fournir les |cffffff78étapes à suivre pour reproduire ce bug|r, indiquez les |cffffff78messages d'erreur|r que vous avez vus, donnez le |cffffff78numéro de révision|r de Routes où le problème a été découvert et précisez également |cffffff78la langue de votre jeu|r.
|cFFFFFFFF
Qui a écrit cet addon qui déchire ?
|r
|cffffff78Xaros|r (Alliance - EU Doomhammer) & |cffffff78Xinhuan|r (Alliance - US Blackrock) en sont les auteurs.
]]

-- vim: ts=4 noexpandtab
