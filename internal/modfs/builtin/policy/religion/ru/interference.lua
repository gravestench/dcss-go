-- Theory of operation: Ru's one-star aura may stop a hostile monster's
-- attack or force it toward another monster. This owner makes the source
-- roll and spatial choice before combat consumes hit or spell-target RNG.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local gods = require("constants.gods")
local kinds = require("constants.ru_interference")
local piety = require("policy.religion.piety")
local powers = require("constants.ru_powers")
local radius_order = require("policy.world.radius_order")
local roll = require("policy.combat.roll")
local spell_flags = require("constants.monster_spell_flags")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local vision = require("policy.character.vision")

local interference = {}

-- Source adjacent_iterator(pos, false) visits the center, then compass
-- cells in reverse clockwise order. This lets melee redirection hit self.
local adjacent_offsets = {
    {
        x = 0,
        y = 0,
    },
    {
        x = -1,
        y = -1,
    },
    {
        x = -1,
        y = 0,
    },
    {
        x = -1,
        y = 1,
    },
    {
        x = 0,
        y = 1,
    },
    {
        x = 1,
        y = 1,
    },
    {
        x = 1,
        y = 0,
    },
    {
        x = 1,
        y = -1,
    },
    {
        x = 0,
        y = -1,
    },
}

-- Check catalog traits without copying them into a second mutable status.
local function has_flag(definition, wanted)
    for _, value in ipairs(definition.flags or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Source firewood is an inert stationary body; projectile actors are also
-- invalid redirect targets even when they occupy a visible cell.
local function targetable(ctx, monster)
    if not monster or monster == ctx:player() or
        targets.attitude(ctx, monster) == attitudes.FRIENDLY then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local health = ctx:get(monster, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local firewood = has_flag(definition, flags.STATIONARY) and
        has_flag(definition, flags.NO_THREAT)

    return not firewood and
        not has_flag(definition, flags.PROJECTILE)
end

-- Melee checks each source compass cell, including the attacker's own
-- cell, so reservoir draws match the order of a real adjacent iterator.
local function adjacent_targets(ctx, attacker)
    local origin = ctx:get(attacker, component.POSITION)
    local result = {}

    for _, offset in ipairs(adjacent_offsets) do
        local monster = ctx:actor_at(origin.level_id,
            origin.x + offset.x, origin.y + offset.y)

        if targetable(ctx, monster) then
            result[#result + 1] = monster
        end
    end

    return result
end

-- Source ranged and spell redirects scan the player's ordinary visible
-- radius. Sorting by source cell order makes choice independent of ECS
-- query or mod registration order.
local function distant_targets(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local radius = vision.radius(ctx, player)
    local result = {}

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if targetable(ctx, monster) then
            local position = ctx:get(monster, component.POSITION)
            local distance = math.max(
                math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if position.level_id == origin.level_id and
                distance <= radius and
                ctx:visible(origin.level_id, origin.x,
                    origin.y, radius, position.x, position.y) then
                result[#result + 1] = {
                    entity = monster,
                    x = position.x,
                    y = position.y,
                    id = ctx:id(monster),
                }
            end
        end
    end

    table.sort(result, function(left, right)
        return radius_order.before(origin, left, right)
    end)

    local ordered = {}

    for _, record in ipairs(result) do
        ordered[#ordered + 1] = record.entity
    end

    return ordered
end

-- One-in-N reservoir replacement gives each eligible monster equal
-- weight without drawing an extra random number for the first candidate.
local function select_target(ctx, candidates)
    local selected = nil

    for index, candidate in ipairs(candidates) do
        if roll.draw(ctx, streams.RELIGION, index) == 0 then
            selected = candidate
        end
    end

    return selected
end

-- Live worship and current no-trans sight must both hold immediately
-- before an attack. A newly imposed penance or submerged state takes
-- effect without any cached passive bit on the monster.
local function worship_for(ctx, attacker)
    local player = ctx:player()
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local origin = ctx:get(player, component.POSITION)
    local position = ctx:get(attacker, component.POSITION)
    local submerged = ctx:get(attacker, component.MONSTER_SUBMERGED)

    if not worship or not origin or not position or
        worship.god_id ~= gods.RU or
        (worship.penance[gods.RU] or 0) > 0 or
        piety.rank(gods.RU, worship.piety) <
            powers.INTERFERENCE_RANK or
        submerged and submerged.active or
        not targetable(ctx, attacker) or
        origin.level_id ~= position.level_id then
        return nil
    end

    local radius = vision.radius(ctx, player)

    if not ctx:visible_no_trans(origin.level_id,
        origin.x, origin.y, radius,
        position.x, position.y) then
        return nil
    end

    return worship
end

-- Draw the attack roll before rounded piety, then round half-chance only
-- if the block comparison failed. The source uses the same sequence for
-- melee, missiles, and spells.
function interference.choose(ctx, attacker, mode)
    if mode ~= kinds.MELEE and mode ~= kinds.DISTANT then
        error("unknown Ru interference mode " .. tostring(mode))
    end

    local worship = worship_for(ctx, attacker)

    if not worship then
        return { kind = kinds.NONE }
    end

    local chance_roll = roll.draw(ctx, streams.RELIGION,
        powers.INTERFERENCE_ROLL_BOUND)
    local chance = roll.random_divide(ctx, worship.piety,
        powers.INTERFERENCE_CHANCE_DIVISOR, streams.RELIGION)

    if chance_roll < chance then
        return { kind = kinds.BLOCK }
    end

    local redirect_chance = roll.random_divide(ctx, chance,
        powers.INTERFERENCE_REDIRECT_DIVISOR, streams.RELIGION)

    if chance_roll >= chance + redirect_chance then
        return { kind = kinds.NONE }
    end

    local candidates = mode == kinds.MELEE and
        adjacent_targets(ctx, attacker) or
        distant_targets(ctx, ctx:player())

    return {
        kind = kinds.REDIRECT,
        target = select_target(ctx, candidates),
    }
end

-- Only the current attack may see a same-side monster as an enemy. The
-- component is saved by Akara if an action spans a transaction boundary,
-- while the action owner still removes it immediately after resolution.
function interference.force_target(ctx, attacker, target)
    if ctx:has(attacker, component.COMBAT_FORCED_TARGET) then
        error("Ru forced target already exists on attacker")
    end

    ctx:add(attacker, component.COMBAT_FORCED_TARGET, {
        target = target,
    })
end

-- A completed or failed spell plan must not carry its override into a
-- later ordinary monster decision or collateral area-effect scan.
function interference.clear_target(ctx, attacker)
    if ctx:has(attacker, component.COMBAT_FORCED_TARGET) then
        ctx:remove(attacker, component.COMBAT_FORCED_TARGET)
    end
end

-- Combat owners use one source message for a blocked physical attack.
function interference.message_block(ctx, attacker)
    local actor = ctx:get(attacker, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    ctx:emit(channels.RELIGION, "The " .. definition.name ..
        " is stunned by your conviction and fails to attack.")
end

-- A successful forced target replaces the player; no candidate means
-- melee silently attacks normally, as in the source action routine.
function interference.message_redirect(ctx, attacker)
    local actor = ctx:get(attacker, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    ctx:emit(channels.RELIGION,
        "You redirect the " .. definition.name .. "'s attack!")
end

-- The source describes a stopped wizard, priest, or natural spell with
-- the first matching role found anywhere in the monster's current book.
function interference.message_block_spell(ctx, caster, book)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local priest = false
    local action = "attack"

    for _, slot in ipairs(book and book.slots or {}) do
        for _, flag in ipairs(slot.flags or {}) do
            if flag == spell_flags.WIZARD then
                action = "cast a spell"

                break
            end

            if flag == spell_flags.PRIEST then
                priest = true
            end
        end

        if action == "cast a spell" then
            break
        end
    end

    if action ~= "cast a spell" and priest then
        action = "pray"
    end

    ctx:emit(channels.RELIGION, "The " .. definition.name ..
        " begins to " .. action ..
        ", but is stunned by your conviction!")
end

return interference
