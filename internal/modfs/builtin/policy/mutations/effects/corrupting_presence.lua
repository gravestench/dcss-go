-- Source: monster.cc:monster::hurt, at pinned DCSS revision e60ba356.
local capabilities = require("constants.mutation_capabilities")
local mutations = require("ids.mutations")
local catalog = require("policy.catalog")
local enchant = require("policy.combat.monster_enchant")
local irradiate = require("policy.magic.effects.zaps.irradiate")
local effects = require("policy.mutations.effects.registry")

local presence = {}

-- Check corrosion and, at higher rank, wretchedness independently on the damaged monster.
-- Example: damage near a level-two Corrupting Presence can make two separate mutation-stream checks.
function presence.after_damage(level, ctx, _, hit)
    local actor = ctx:get(hit.target, "core.actor")

    if not actor then
        return
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if ctx:random("mutation", 12) == 0 then
        enchant.corrode_equipment(ctx, hit.target, definition,
            "Your corrupting presence")
    end

    if level > 1 and ctx:random("mutation", 12) == 0 then
        irradiate.wretch(ctx, hit.target, definition)
    end
end

effects.add(mutations.MUT_CORRUPTING_PRESENCE, {
    [capabilities.AFTER_MONSTER_DAMAGE] = presence.after_damage,
})

return presence
