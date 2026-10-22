-- Theory of operation: slimy walls remain ordinary terrain, but each actor
-- action tests the eight neighboring cells for acidic wall exposure.
-- Jiyva and slime identity change immunity at use time, not in a saved flag.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local causes = require("constants.damage_causes")
local damage = require("policy.magic.damage")
local defenses = require("policy.religion.jiyva.defenses")
local display = require("policy.combat.monster_support.display")
local identity = require("policy.religion.jiyva.identity")
local monster_health = require("policy.combat.monster_health")
local monsters = require("ids.monsters")
local player_health = require("policy.combat.player_health")
local resistance = require("constants.resistance_ids")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local vision = require("policy.character.vision")

local walls = {}

-- Original DCSS uses a small source-defined icy-body set for the wall
-- message. The actor's catalog identity keeps display choices out of Go.
local icy_kinds = {
    [monsters.MONS_ICE_BEAST] = true,
    [monsters.MONS_SIMULACRUM] = true,
    [monsters.MONS_ICE_STATUE] = true,
    [monsters.MONS_BLOCK_OF_ICE] = true,
    [monsters.MONS_NARGUN] = true,
}

-- Source adjacent_iterator includes diagonals. Query the current grid so
-- temporary terrain and a changed vault wall take effect immediately.
function walls.adjacent(ctx, level_id, x, y)
    local count = 0

    for dy = -1, 1 do
        for dx = -1, 1 do
            if (dx ~= 0 or dy ~= 0) and
                ctx:cell(level_id, x + dx, y + dy) ==
                    terrain.DNGN_SLIMY_WALL then
                count = count + 1
            end
        end
    end

    return count
end

-- Jiyva protects only the player at zero stars. Monster slime genus and
-- full acid immunity are the two independent source exceptions.
function walls.immune(ctx, actor)
    if actor == ctx:player() then
        return defenses.active(ctx, actor, 0)
    end

    local body = ctx:get(actor, component.ACTOR)

    if not body then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, body.kind_id)

    return identity.slime(definition) or
        damage.monster_resistance(ctx, actor, resistance.ACID) >= 3
end

-- Source div_rand_round samples only when action time leaves a remainder.
-- A zero-sided die contributes no damage and consumes no random number.
local function rounded_strength(ctx, count, elapsed_aut)
    local numerator = 3 * count * elapsed_aut
    local whole = math.floor(numerator / 10)
    local remainder = numerator % 10

    if remainder > 0 and
        ctx:random(streams.SLIME_WALL, 10) < remainder then
        whole = whole + 1
    end

    return whole
end

-- Each source die is independent. The environmental stream is saved with
-- the run so restoring cannot reroll a wall exposure or shift spell RNG.
local function roll_dice(ctx, count, sides)
    if sides <= 0 then
        return 0
    end

    local total = 0

    for _ = 1, count do
        total = total + 1 + ctx:random(streams.SLIME_WALL, sides)
    end

    return total
end

-- Source DCSS only harms a monster when its cell is in the player's
-- no-transparency sight. Resolve this after rolling damage, preserving the
-- source RNG sequence even when an offscreen monster is spared.
local function monster_exposure_visible(ctx, position)
    local player = ctx:player()
    local origin = player and ctx:get(player, component.POSITION)

    return origin and origin.level_id == position.level_id and
        ctx:visible_no_trans(position.level_id, origin.x, origin.y,
            vision.radius(ctx, player), position.x, position.y) or false
end

-- Singular and plural terrain use the source verbs; a visible monster
-- should never lose HP to a wall without an explanation in the log.
local function monster_message(ctx, actor, count)
    local body = ctx:get(actor, component.ACTOR)
    local verb = icy_kinds[body.kind_id] and "melt" or "burn"
    local subject = "the " .. display.name(ctx, actor)

    if count > 1 then
        ctx:emit(channels.COMBAT,
            "The walls " .. verb .. " " .. subject .. "!")
    else
        ctx:emit(channels.COMBAT,
            "The wall " .. verb .. "s " .. subject .. "!")
    end
end

-- Apply one completed actor action's damage through normal health owners.
-- The player uses elapsed-action strength; monsters take source 2d4.
function walls.expose(ctx, actor, elapsed_aut)
    if elapsed_aut <= 0 or walls.immune(ctx, actor) then
        return 0
    end

    local position = ctx:get(actor, component.POSITION)
    local health = ctx:get(actor, component.HEALTH)

    if not position or not health or health.current <= 0 then
        return 0
    end

    local count = walls.adjacent(ctx, position.level_id,
        position.x, position.y)

    if count == 0 then
        return 0
    end

    local raw
    local dealt

    if actor == ctx:player() then
        local strength = rounded_strength(ctx, count, elapsed_aut)

        raw = roll_dice(ctx, 4, strength)
        dealt = damage.player_elemental(ctx, actor, raw,
            resistance.ACID)

        ctx:emit(channels.COMBAT,
            "You are splashed with acid" ..
            (dealt == 0 and " but take no damage." or "!"))
        player_health.damage(ctx, actor, dealt, false,
            nil, causes.ACID)
    else
        raw = roll_dice(ctx, 2, 4)
        dealt = damage.monster_elemental(ctx, actor, raw,
            resistance.ACID)

        if dealt <= 0 or not monster_exposure_visible(ctx, position) then
            return 0
        end

        monster_message(ctx, actor, count)
        monster_health.damage(ctx, actor, dealt, nil,
            causes.ACID)
    end

    return dealt
end

return walls
