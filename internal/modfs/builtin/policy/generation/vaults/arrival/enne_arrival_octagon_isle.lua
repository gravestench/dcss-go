-- Example: Draw the octagon obliqueness before the optional smear, preserving the source random order.
local effects = require("constants.vault_effects")

local handler = {}

-- Draw the octagon obliqueness before the optional smear, preserving the source random order.
local function shape_octagon_isle(api)
    local oblique = api:random_range(3, 7)

    api:record(effects.OCTA_ROOM, {
        oblique = oblique,
        replace = ".",
        outside = "W",
        inside = ".",
    })

    if api:coinflip() then
        api:record(effects.SMEAR_MAP, {
            iterations = 20,
            smear = "x",
            onto = ".W",
            boxy = true,
        })
    end
end

handler.shape_octagon_isle = shape_octagon_isle

return handler
