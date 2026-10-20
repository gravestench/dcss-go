-- Theory of operation: the source ten-percent controller only qualifies
-- on open D:5-10 layouts. Once selected, it asks the shared placement API
-- for four to six weighted camp pieces, allowing huts and kennels to mix.
local tags = require("constants.vault_tags")
local handler = {}

-- One bounded source draw adds zero to two pieces to the four-piece base.
-- The tagged child selector owns weight and uniqueness decisions.
local function place_gnoll_camp(api)
    local count = 4 + api:roll(3)

    api:place_maps(tags.SERIAL_GNOLL_CAMP, count)
end

handler.place_gnoll_camp = place_gnoll_camp

return handler
