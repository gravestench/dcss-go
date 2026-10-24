-- Jiyva's player clocks age once for each completed player action.
local component = require("constants.component")
local powers = require("policy.religion.jiyva.powers")

local system = {}

-- Monster actions do not shorten a worshipper's invocation duration.
function system.update(ctx, player, aut)
    if player == ctx:player() then
        powers.tick(ctx, player, aut)
    end
end

register.system({
    id = "religion.jiyva_powers",
    scope = "active",
    query = { component.JIYVA_POWERS },
    -- Portals can change levels later than ordinary stairs. Age the clock
    -- after every travel owner so no old-floor wall remains on arrival.
    after = {
        "attack.player_ability",
        "world.stairs",
        "world.bailey_portals",
        "world.bazaar_portals",
        "world.desolation_portals",
        "world.gauntlet_portals",
        "world.ice_cave_portals",
        "world.ossuary_portals",
        "world.sewer_portals",
        "world.volcano_portals",
        "world.wizlab_portals",
    },
    update = system.update,
})

return system
