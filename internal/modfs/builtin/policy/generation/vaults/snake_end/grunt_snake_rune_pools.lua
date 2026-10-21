-- Theory of operation: the source pools ending has one MAP whose water
-- channels become a lava hold one time in three. This hook emits the
-- chosen source declarations at their original DES position, before the
-- common substitutions reshape the map. The layout stream owns the draw.
local directives = require("constants.vault_directives")

local handler = {}

-- Keep the fire branch together so the same themed monster slots, lava
-- feature, and glyph substitutions are selected by one deterministic draw.
local function fire_theme(api)
    api:emit(directives.MONS,
        "nagaraja / salamander tyrant w:20, guardian serpent")
    api:emit(directives.MONS,
        "naga warrior / naga sharpshooter w:5")
    api:emit(directives.MONS,
        "naga mage / naga ritualist / naga sharpshooter / salamander mystic w:30")
    api:emit(directives.MONS, "naga / salamander w:30")
    api:emit(directives.MONS,
        "guardian serpent w:15 / anaconda w:30 / black mamba / mana viper / shock serpent")
    api:emit(directives.KMONS, "7 = salamander")
    api:emit(directives.KFEAT, "7 = l")
    api:emit(directives.SUBST, "w = l")
    api:emit(directives.NSUBST, "7 = 2=7 / 7llll")
end

-- The water branch retains sea snakes and deep water instead of producing
-- a second map file that could drift from the single source geometry.
local function water_theme(api)
    api:emit(directives.MONS,
        "nagaraja, guardian serpent, naga warrior / naga sharpshooter w:5")
    api:emit(directives.MONS,
        "naga mage w:40 / naga ritualist / naga sharpshooter, naga")
    api:emit(directives.MONS,
        "guardian serpent w:15 / anaconda w:30 / black mamba / mana viper / shock serpent")
    api:emit(directives.KMONS, "7 = sea snake")
    api:emit(directives.KFEAT, "7 = w")
    api:emit(directives.NSUBST, "7 = 2=7 / 7wwww")
end

-- Source `one_chance_in(3)` is the only theme decision for this vault.
local function choose_theme(api)
    if api:one_in(3) then
        fire_theme(api)
    else
        water_theme(api)
    end
end

handler.choose_theme = choose_theme

return handler
