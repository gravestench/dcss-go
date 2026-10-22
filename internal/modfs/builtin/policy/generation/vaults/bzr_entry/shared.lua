-- Bazaar entries remain source DES maps. These methods run at each map's
-- original script position and add the portal identity and saved timer
-- request without replacing its authored geometry.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")

local shared = {}

-- Source entries are usually temporary. Draw their duration once during
-- placement and keep it as a typed marker for the live portal owner.
local function place_portal(api, permanent)
    api:emit(directives.KFEAT, "O = enter_bazaar")

    local timed = not permanent and not api:one_in(6)
    local low = 200 + 30 * (40 - api:absolute_depth()) + api:roll(200)
    local high = low + api:roll(low) + 100

    -- Source bazaar_portal computes both bounds even for a permanent arch.
    -- Keep those draws so later generation uses the same RNG position.
    if not timed then
        api:emit(directives.MARKER,
            'O = lua:one_way_stair { floor = "stone_arch" }')

        return
    end

    api:emit(directives.MARKER,
        "O = lua:timed_marker { low = " .. low ..
        ", high = " .. high ..
        ', single_timed = true, floor = "stone_arch" }')
end

-- Most source entry maps use the same five-in-six timed portal choice.
function shared.portal(api)
    place_portal(api, false)
end

-- The statue entrance is explicitly permanent in the source script.
function shared.permanent_portal(api)
    place_portal(api, true)
end

-- The dummy exists to suppress another Bazaar while one is already on the
-- travel stack; its saved state is supplied by the later portal owner.
function shared.active_bazaar(api)
    return api.bazaar_active == true
end

-- Keep the Pan-only entrance's wall name as a typed presentation record.
function shared.crystal_name(api)
    api:record(effects.FEATURE_NAME, {
        feature = "crystal_wall",
        name = "wall of crystal",
    })
end

return shared
