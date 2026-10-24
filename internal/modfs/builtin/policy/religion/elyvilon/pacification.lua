-- Heal Other can permanently turn a willing hostile monster neutral.
-- Eligibility uses its catalog class; the live HP pool is healed only
-- after the class-based pacification roll succeeds.
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local death = require("policy.death")
local awards = require("policy.character.experience_award")
local constriction = require("policy.combat.constriction")
local engulf = require("policy.combat.engulf")
local flags = require("constants.monster_flags")
local flay = require("policy.combat.monster_flay")
local holiness = require("constants.monster_holiness")
local intelligence = require("constants.monster_intelligence")
local items = require("ids.items")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local pacification = {}

-- Geryon alone drops the Horn when accepting peace. The rest of a
-- pacified monster's carried inventory leaves the level with it later.
local function discard_geryon_horn(ctx, target)
    local actor = ctx:get(target, component.ACTOR)

    if actor.kind_id ~= monsters.MONS_GERYON then
        return
    end

    local position = ctx:get(target, component.POSITION)

    for _, entity in ipairs(ctx:query({ component.CARRIED_BY })) do
        local carrier = ctx:get(entity, component.CARRIED_BY)
        local item = ctx:get(entity, component.ITEM)

        if carrier.holder == target and item and
            item.kind_id == items.MISC_HORN_OF_GERYON then
            if ctx:has(entity, component.EQUIPPED) then
                ctx:remove(entity, component.EQUIPPED)
            end

            ctx:remove(entity, component.CARRIED_BY)
            ctx:add(entity, component.POSITION, position)
            ctx:emit("religion", "Geryon discards his horn.")
        end
    end
end

-- These bodies are appendages of another monster. Source treats them as
-- mindless for this invocation even when a profile has animal intelligence.
local tentacles = {
    [monsters.MONS_KRAKEN_TENTACLE] = true,
    [monsters.MONS_KRAKEN_TENTACLE_SEGMENT] = true,
    [monsters.MONS_ELDRITCH_TENTACLE] = true,
    [monsters.MONS_ELDRITCH_TENTACLE_SEGMENT] = true,
    [monsters.MONS_STARSPAWN_TENTACLE] = true,
    [monsters.MONS_STARSPAWN_TENTACLE_SEGMENT] = true,
}

-- Ghosts and Pandemonium lords use the source's effectively unreachable
-- class threshold. Other species use the committed average-HP catalog.
function pacification.threshold(definition)
    if definition.id == monsters.MONS_PANDEMONIUM_LORD or
        definition.id == monsters.MONS_PLAYER_GHOST then
        return 1000
    end

    return math.floor((definition.average_hp_10x or 0) / 10)
end

-- Source class flags, intelligence, and current sleep state determine
-- whether the peace offer can be understood and acted upon.
function pacification.reason(ctx, target, definition)
    if definition.intelligence_id == intelligence.BRAINLESS or
        tentacles[definition.id] then
        return "You cannot pacify mindless monsters!"
    end

    for _, value in ipairs(definition.holiness or {}) do
        if value == holiness.NONLIVING then
            return "You cannot pacify nonliving monsters!"
        end
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.STATIONARY then
            return "You cannot pacify immobile monsters!"
        end
    end

    local ai = ctx:get(target, component.AI)
    local stasis = ctx:get(target, component.MONSTER_STASIS)

    if (ai and ai.behavior == behaviors.SLEEP) or
        (stasis and stasis.hibernating) then
        return "You cannot pacify this monster while it is asleep!"
    end

    return nil
end

-- Source holy bodies are easier to pacify than natural ones; undead and
-- demonic bodies divide the offer more severely. Animal intelligence
-- triples the effective sides before the average-HP threshold.
function pacification.sides(ctx, player, definition, power)
    local divisor = 3

    for _, value in ipairs(definition.holiness or {}) do
        if value == holiness.HOLY then
            divisor = 2
            break
        elseif value == holiness.UNDEAD then
            divisor = 4
            break
        elseif value == holiness.DEMONIC then
            divisor = 5
            break
        end
    end

    local rank = intelligence.rank[definition.intelligence_id] or 0
    local multiplier = rank < intelligence.rank[intelligence.HUMAN] and
        3 or 1
    local magic_power = require("policy.magic.power")
    local skills = require("ids.skills")
    local trained = magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, power)

    return math.floor(multiplier * (trained + power) / divisor)
end

-- Source biased_random2(sides-1, 2) walks a decreasing denominator.
-- Its early exits favour small values without changing the RNG stream.
local function biased_roll(ctx, sides)
    local maximum = sides - 1

    for value = 0, maximum - 1 do
        local denominator = maximum + 1 - value

        if ctx:random(streams.RELIGION, denominator) < 2 then
            return value
        end
    end

    return 0
end

-- A successful offer grants full nonlethal XP once, changes real
-- allegiance, drops its active pursuit, and heals the new neutral actor.
function pacification.attempt(ctx, player, target, healed, power)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local reason = pacification.reason(ctx, target, definition)

    if reason then
        ctx:emit("religion", reason)

        return "abort"
    end

    local threshold = pacification.threshold(definition)
    local sides = pacification.sides(ctx, player, definition, power)

    if sides < threshold then
        ctx:emit("religion", "The monster is unfazed by your offer of peace.")

        return "abort"
    end

    local result = biased_roll(ctx, sides)

    if result * 23 < threshold * 20 then
        ctx:emit("religion", "The light of Elyvilon fails to reach the " ..
            definition.name .. ".")

        return "failed"
    end

    if result < threshold then
        ctx:emit("religion", "The light of Elyvilon almost touches the " ..
            definition.name .. ".")

        return "failed"
    end

    if not ctx:has(target, component.ELYVILON_PACIFIED) then
        ctx:add(target, component.ELYVILON_PACIFIED, {
            pacified = true,
        })

        if not ctx:has(target, component.SUMMON) then
            local health = ctx:get(target, component.HEALTH)
            local xp = death.experience(definition, health.max)

            awards.monster(ctx, player, xp)
        end
    end

    -- Source ends the monster's holds and flaying at allegiance change,
    -- not when it eventually reaches a stair. A freed player acts next.
    flay.release_for_ghost(ctx, target)
    constriction.release_for(ctx, target)
    engulf.release_for(ctx, target)

    if ctx:has(target, component.PLAYER_CONSTRICTION) then
        ctx:remove(target, component.PLAYER_CONSTRICTION)
    end

    discard_geryon_horn(ctx, target)

    local ai = ctx:get(target, component.AI)

    if ai then
        ai.behavior = behaviors.WANDER
        ai.memory_until_aut = 0
        ctx:set(target, component.AI, ai)
    end

    if ctx:has(target, component.MONSTER_PATROL) then
        ctx:remove(target, component.MONSTER_PATROL)
    end

    ctx:emit("religion", "The " .. definition.name .. " turns neutral.")
    pacification.heal(ctx, target, healed)

    return "pacified"
end

-- Healing is shared by friendly and pacified targets. Full HP does not
-- cancel a targeted invocation, and no monster identity is exposed by
-- asking this owner to heal an empty cell.
function pacification.heal(ctx, target, amount)
    local health = ctx:get(target, component.HEALTH)

    if not health or health.current >= health.max then
        return false
    end

    health.current = math.min(health.max, health.current + amount)
    ctx:set(target, component.HEALTH, health)
    local actor = ctx:get(target, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    ctx:emit("religion", "You heal the " .. definition.name .. ".")

    return true
end

-- Restore checks the durable neutral side marker before AI or combat
-- reads it. Other source-specific attitudes may coexist but cannot
-- invent a pacification marker on the player or a removed actor.
function pacification.validate(ctx)
    for _, entity in ipairs(ctx:query({ component.ELYVILON_PACIFIED })) do
        local state = ctx:get(entity, component.ELYVILON_PACIFIED)

        if not state.pacified or
            not ctx:has(entity, component.ACTOR) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) or
            targets.real_attitude(ctx, entity) ~= attitudes.NEUTRAL then
            error("invalid Elyvilon pacified monster")
        end
    end
end

return pacification
