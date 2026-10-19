local constructs = require("constants.monster_construct_components")
local portal = require("policy.combat.monster_summons.portal")

register.system({
    id = "combat.portal_tentacle.tick",
    scope = "active",
    query = { constructs.PORTAL },
    before = { "magic.summon.construct_decision" },
    update = portal.tick,
})
