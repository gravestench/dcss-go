-- Theory of operation: the rare aquarium controller chooses one width for
-- every piece on this level, then requests five themed map groups. The
-- width lives in this generation context, not a process global; each child
-- hook reads it through the generic vault setting API.
local settings = require("constants.vault_settings")
local tags = require("constants.vault_tags")
local handler = {}

-- Preserve the source conditional draw order and group counts. Pool width
-- zero produces a narrow window, while width two fills both outer bands.
local function place_aquarium(api)
    local size

    if api:roll(6) < 2 then
        size = 0
    elseif api:roll(4) < 3 then
        size = 1
    else
        size = 2
    end

    local player = api.context.player

    player.settings = player.settings or {}
    player.settings[settings.AQUARIUM_POOL_SIZE] = size

    local bridges = 1 + api:roll(2)
    local windows = 2 + api:roll(3)
    local views = 1 + api:roll(2)
    local balconies = api:roll(2)
    local pools = api:roll(2)

    api:place_maps(tags.AQUARIUM_BRIDGE, bridges)
    api:place_maps(tags.AQUARIUM_WINDOW, windows)
    api:place_maps(tags.AQUARIUM_VIEW, views)
    api:place_maps(tags.AQUARIUM_BALCONY, balconies)
    api:place_maps(tags.AQUARIUM_POOL, pools)
end

handler.place_aquarium = place_aquarium

return handler
