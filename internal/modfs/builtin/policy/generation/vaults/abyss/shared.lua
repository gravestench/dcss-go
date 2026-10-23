-- Theory of operation: source exit vaults share one depth-sensitive glyph
-- rule. Their DES geometry stays in each map; this handler emits the source
-- KFEAT or KITEM at the map's original script line. The same layout RNG
-- stream drives the bottom-floor alternative.
local directives = require("constants.vault_directives")

local shared = {}

-- At the Abyss bottom, no downward stair can exist. Source Crawl chooses
-- an exit on six of ten draws and a guarded floor item otherwise. Higher
-- floors retain the source six-to-four exit versus stair weight.
local function exit_choice(api, glyph)
    if api:depth() == api:branch_bottom() then
        if api:roll(10) > 3 then
            api:emit(directives.KFEAT, glyph .. " = exit_abyss")
        else
            api:emit(directives.KITEM, glyph .. " = any no_pickup")
        end

        return
    end

    api:emit(directives.KFEAT,
        glyph .. " = exit_abyss w:6 / abyssal_stair w:4")
end

-- Most source exit maps key their portal to O.
function shared.exit_o(api)
    exit_choice(api, "O")
end

-- A choices map uses N so its other keyed cells remain source-authored.
function shared.exit_n(api)
    exit_choice(api, "N")
end

-- The kobold exit uses P to preserve its source key map.
function shared.exit_p(api)
    exit_choice(api, "P")
end

return shared
