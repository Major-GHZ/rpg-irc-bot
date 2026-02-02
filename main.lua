local Partie = require("module")
local jeu = Partie.nouveau()

local heros = { energie = 100, energieMax = 100 }
local boss = { energie = 1000, energieMax = 1000 }

jeu:nouveauDegats(heros, 5)
print("Énergie Heros", heros.energie)

jeu:nouveauDegats(boss, 45)
print("Énergie Boss", boss.energie)

jeu:nouveauDegats(heros, 5)
print("Énergie Heros", heros.energie)

jeu:nouveauDegats(boss, 45)
print("Énergie Boss", boss.energie)

jeu:nouveauDegats(heros, 5)
print("Énergie Heros", heros.energie)

jeu:nouveauDegats(boss, 45)
print("Énergie Boss", boss.energie)

