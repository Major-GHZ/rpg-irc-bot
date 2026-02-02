local ModuleJeu = {}
local Jeu = {}
local Jeu_mt = { __index = Jeu }

function ModuleJeu.nouveau()
    print("Début de la Partie !")
    return setmetatable({}, Jeu_mt)
end

function Jeu:nouveauDegats(personnage, degats)
    personnage.energie = personnage.energie - degats
end

return ModuleJeu

