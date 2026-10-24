-- Some gods keep a kill clock instead of gaining ordinary piety. The
-- effective god definition names its own Lua reaction so the death system
-- never needs a table of god-specific cases.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")

local progress = {}

-- Only a credited XP death reaches this owner. Run after kill conduct and
-- HP/MP reactions because the source advances Ru's clock at that point.
function progress.on_kill(ctx, player, xp)
    if xp <= 0 then
        return
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id == gods.NO_GOD then
        return
    end

    local god = catalog.get(categories.GODS, worship.god_id)

    if not god.kill_progress_module then
        return
    end

    require(god.kill_progress_module).on_kill(ctx, player, worship)
end

return progress
