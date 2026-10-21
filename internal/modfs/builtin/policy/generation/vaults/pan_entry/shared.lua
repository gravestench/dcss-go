-- Pan entry geometry stays in each DES file. The source's shared threat
-- decision runs here when the chosen entry is placed on a Depths floor.
local directives = require("constants.vault_directives")

local shared = {}

-- The source raises the chance of a serious guard as Depths gets deeper.
-- Only the selected entry spends this draw; a refused or unplaced portal
-- does not advance the vault RNG stream.
local function threat(api, glyph)
    local depth = api:depth()

    if api:chance(depth + 3, depth + 5) then
        api:emit(directives.TAGS,
            "luniq_hellpanabyss_threat_entry")
        api:emit(directives.KMONS, glyph .. " = green death / " ..
            "blizzard demon / balrug / cacodemon / hell beast / " ..
            "hellion / reaper / lorocyproca / tormentor / shadow demon")

        return
    end

    api:emit(directives.SUBST, "12 = .")
    api:emit(directives.KMONS,
        glyph .. " = common demon / nothing")
end

-- `O` is the guard cell in the eight original random-demon entries.
function shared.threat_o(api)
    threat(api, "O")
end

-- `e` is the guard cell in the four compact lord-inspired entries.
function shared.threat_e(api)
    threat(api, "e")
end

return shared
