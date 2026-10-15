local mappings = require("data.player_spell_zaps")
local zap_caps = require("data.player_zap_caps")

local cap = {}

-- Source: spl-util.cc:spell_power_cap. The first spl-zap.cc mapping is the
-- runtime spell_to_zap choice; a variable-range spell keeps its spell cap.
function cap.for_spell(spell)
    local spell_cap = spell.power_cap or 0
    local links = mappings[spell.id]
    local zap_cap = 0

    if links and links[1] then
        zap_cap = zap_caps[links[1].zap_id] or 0
    end

    if spell_cap == 0 then
        return zap_cap
    end

    if zap_cap == 0 or spell_cap <= zap_cap or
        spell.min_range_expr ~= spell.max_range_expr then
        return spell_cap
    end

    return zap_cap
end

return cap
