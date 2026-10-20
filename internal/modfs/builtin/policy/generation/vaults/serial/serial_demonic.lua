-- Theory of operation: the source one-percent demonic controller owns no
-- terrain. After its chance succeeds, it places several tagged children.
-- Each child's own Lua setup scales possible demons with absolute depth.
local tags = require("constants.vault_tags")
local handler = {}

-- Multiply independent source draws to favor four patches while allowing
-- as many as ten; the common controller API handles weighted child maps.
local function place_demonic(api)
    local count = 4 + api:roll(3) * api:roll(4)

    api:place_maps(tags.SERIAL_DEMONIC, count)
end

handler.place_demonic = place_demonic

return handler
