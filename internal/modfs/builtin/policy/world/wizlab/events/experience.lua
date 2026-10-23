-- Theory of operation: Zonguldrok creates permanent monsters after the
-- initial Dungeon roster is fixed. A killed grave actor or awakened lich
-- may award XP, so restore grants capacity only for bodies that the
-- encounter state proves have existed and can no longer be alive.
local catalog = require("policy.catalog")
local component = require("constants.component")
local death = require("policy.death")
local monsters = require("ids.monsters")
local roster = require("policy.population.roster")
local wizlab = require("constants.wizlab")

local experience = {}

local grave_forms = {
    {
        kind = monsters.MONS_ZOMBIE,
        health = monsters.MONS_OGRE,
    },
    {
        kind = monsters.MONS_ZOMBIE,
        health = monsters.MONS_TROLL,
    },
    {
        kind = monsters.MONS_ZOMBIE,
        health = monsters.MONS_TWO_HEADED_OGRE,
    },
    {
        kind = monsters.MONS_WIGHT,
        health = monsters.MONS_WIGHT,
    },
    {
        kind = monsters.MONS_VAMPIRE,
        health = monsters.MONS_VAMPIRE,
    },
    {
        kind = monsters.MONS_SKELETAL_WARRIOR,
        health = monsters.MONS_SKELETAL_WARRIOR,
    },
    {
        kind = monsters.MONS_ANCIENT_CHAMPION,
        health = monsters.MONS_ANCIENT_CHAMPION,
    },
}

-- Use the same monster kind and possible HP ceiling as the death award.
-- Zombie HP comes from its source corpse, so those forms are separate.
local function maximum_grave_reward()
    local maximum = 0

    for _, form in ipairs(grave_forms) do
        local definition = catalog.get("monsters", form.kind)
        local profile = roster.profile(form.health)
        local reward = death.experience(definition, profile.maximum)

        maximum = math.max(maximum, reward)
    end

    return maximum
end

-- A live lich has not yet awarded XP. Grave deaths are already counted
-- by the encounter's death hook, even if another monster dealt the blow.
function experience.maximum(ctx)
    local live_lich = {}

    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_EVENT_ACTOR,
    })) do
        local origin = ctx:get(entity,
            component.WORLD_WIZLAB_EVENT_ACTOR)

        if origin.kind == wizlab.EVENT_ACTOR_ZONGULDROK_LICH then
            live_lich[origin.level_id] = true
        end
    end

    local grave_reward = maximum_grave_reward()
    local lich = catalog.get("monsters", monsters.MONS_ANCIENT_LICH)
    local lich_hp = roster.profile(monsters.MONS_ANCIENT_LICH)
    local lich_reward = death.experience(lich, lich_hp.maximum)
    local maximum = 0

    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_ZONGULDROK,
    })) do
        local state = ctx:get(entity,
            component.WORLD_WIZLAB_ZONGULDROK)

        maximum = maximum + state.killed * grave_reward

        if state.awoke and not live_lich[state.level_id] then
            maximum = maximum + lich_reward
        end
    end

    return maximum
end

return experience
