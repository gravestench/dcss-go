-- A mutant beast's facets are authored in DES and saved on its actor.
-- Keep their spellings here so parsing and live capabilities agree.
local component = require("constants.component")

local facets = {
    STING = "sting",
    BAT = "bat",
    FIRE = "fire",
    WEIRD = "weird",
    SHOCK = "shock",
    OX = "ox",
}

-- Read the live saved form rather than inferring a facet from the shared
-- MONS_MUTANT_BEAST catalog row, which represents every possible form.
function facets.has(ctx, actor, wanted)
    local form = ctx:get(actor, component.MONSTER_MUTANT_BEAST)

    for _, facet in ipairs(form and form.facets or {}) do
        if facet == wanted then
            return true
        end
    end

    return false
end

return facets
