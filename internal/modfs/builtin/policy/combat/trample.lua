-- Source melee trample moves the defender during contact. A final effect
-- follows into the old square only after the remaining attack reactions.
-- This separation prevents a dead or displaced attacker from following.
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local dislodge = require("policy.combat.dislodge")
local flight = require("policy.combat.flight")
local form_ids = require("constants.form_ids")
local forms = require("policy.magic.effects.forms.player")
local habitat = require("policy.combat.monster_habitat")
local monster_flags = require("constants.monster_flags")
local passwall = require("policy.magic.effects.translocation.passwall")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local terrain = require("constants.terrain")
local traps = require("policy.traps.activation")
local vault_triggers = require("policy.world.vault_triggers")
local water = require("policy.character.water")

local trample = {}

-- Source stationary defenders skip knockback before any size roll.
local function stationary(ctx, defender)
    if ctx:has(defender, component.PLAYER) then
        local form = ctx:get(defender, component.PLAYER_FORM)

        return form and form.form_id == form_ids.TREE and
            form.remaining_aut > 0 or false
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == monster_flags.STATIONARY then
            return true
        end
    end

    return false
end

-- A held defender cannot leave its constrictor, but the source checks this
-- after the size roll and destination checks. Two ECS links express holds.
local function constricted(ctx, defender)
    return ctx:has(defender, component.CONSTRICTION) or
        ctx:has(defender, component.PLAYER_CONSTRICTION)
end

-- A late paralysis or petrification can stop a monster before knockback.
-- Source monster::cannot_act checks these two states after melee damage.
local function cannot_act(ctx, attacker)
    local paralysis = ctx:get(attacker, component.PARALYSIS)
    local stasis = ctx:get(attacker, component.MONSTER_STASIS)

    return (paralysis and paralysis.remaining_aut > 0) or
        (stasis and stasis.petrified_aut > 0) or false
end

-- The source refuses a dangerous landing if its enabling flight or form is
-- about to expire. Its flight and transformation warning threshold is 100
-- AUT. Permanent flight and swimming remain safe in their own terrain.
local function player_habitable(ctx, player, level_id, x, y)
    if not ctx:walkable(level_id, x, y) or
        ctx:cell(level_id, x, y) == terrain.DNGN_MALIGN_GATEWAY then
        return false
    end

    local feature = ctx:cell(level_id, x, y)
    local danger = feature == terrain.DNGN_LAVA or
        (feature == terrain.DNGN_DEEP_WATER and
            not water.can_swim(ctx, player))

    if not danger then
        return true
    end

    if not flight.active(ctx, player) then
        return false
    end

    if flight.permanent(ctx, player) then
        return true
    end

    local temporary = ctx:get(player, component.ZAP_FLIGHT)
    local form = ctx:get(player, component.PLAYER_FORM)
    local form_flight = form and forms.modifiers(ctx, player).flight == "enable"

    if temporary and temporary.remaining_aut > 0 and
        temporary.remaining_aut <= 100 then
        return false
    end

    if form_flight and form.remaining_aut > 0 and
        form.remaining_aut <= 100 then
        return false
    end

    return true
end

-- The ordinary monster habitat owner handles water, lava, and live flight.
-- Player habitability also asks whether temporary flight is expiring.
local function habitable(ctx, actor, level_id, x, y)
    if ctx:has(actor, component.PLAYER) then
        return player_habitable(ctx, actor, level_id, x, y)
    end

    return habitat.at(ctx, actor, level_id, x, y)
end

-- Rejected visible knockback gives source feedback. A constriction has its
-- own message, while Mountain Boots add their specific protection message.
local function blocked_message(ctx, hit, constrained, boots)
    local defender = hit.defender
    local player = ctx:has(defender, component.PLAYER)

    if not player and not senses.player_sees_actor(ctx, defender) then
        return
    end

    if boots and player then
        ctx:emit(channels.COMBAT,
            "Your boots keep you from being knocked back.")
    end

    local subject = player and "You" or
        "The " .. (hit.defender_definition and
            hit.defender_definition.name or "monster")
    local verb

    if constrained then
        verb = player and " are held in place!" or " is held in place!"
    else
        verb = player and " hold your ground!" or " holds its ground!"
    end

    ctx:emit(channels.COMBAT, subject .. verb)
end

-- A successful shove tells the player what happened. Incapacitated or
-- airborne defenders are shoved; an active grounded defender stumbles.
local function moved_message(ctx, hit)
    local defender = hit.defender
    local player = ctx:has(defender, component.PLAYER)
    local incapacitated = ctx:has(defender, component.PLAYER_PARALYSIS) or
        ctx:has(defender, component.PARALYSIS)
    local shoved = flight.active(ctx, defender) or incapacitated

    if player then
        ctx:emit(channels.COMBAT,
            shoved and "You are shoved backwards!" or
                "You stumble backwards!")
    elseif senses.player_sees_actor(ctx, defender) then
        local name = hit.defender_definition and
            hit.defender_definition.name or "monster"
        local verb = shoved and " is shoved" or " stumbles"

        ctx:emit(channels.COMBAT,
            "The " .. name .. verb .. " backwards!")
    end
end

-- Move the defender before source-style location effects. A player loses
-- Passwall on displacement, and traps or vault markers see the new cell.
local function displace(ctx, hit, target, x, y)
    local old_position = {
        level_id = target.level_id,
        x = target.x,
        y = target.y,
    }

    ctx:move_actor(hit.defender, target.level_id, x, y)
    moved_message(ctx, hit)

    if ctx:has(hit.defender, component.PLAYER) and
        ctx:has(hit.defender, component.PASSWALL_DELAY) then
        ctx:emit(channels.SPELL,
            passwall.cancel(ctx, hit.defender))
    end

    local new_position = ctx:get(hit.defender, component.POSITION)

    if ctx:has(hit.defender, component.PLAYER) then
        vault_triggers.enter(ctx, hit.defender, new_position)
    end

    -- A marker may move the player again; traps inspect the actual current
    -- landing rather than the position captured before that callback.
    new_position = ctx:get(hit.defender, component.POSITION)

    if new_position then
        traps.enter(ctx, hit.defender, old_position, new_position)
    end
end

-- Source x_chance_in_y consumes no draw for impossible or certain size
-- outcomes. Only a legal destination can commit the defender's movement.
function trample.attempt(ctx, hit)
    hit.trample_follow = nil

    if hit.player_moving or hit.attacker == hit.defender or
        stationary(ctx, hit.defender) or
        cannot_act(ctx, hit.attacker) then
        return false
    end

    local source = ctx:get(hit.attacker, component.POSITION)
    local target = ctx:get(hit.defender, component.POSITION)

    if not source or not target or source.level_id ~= target.level_id then
        return false
    end

    local chance = dislodge.body_rank(ctx, hit.attacker) -
        dislodge.body_rank(ctx, hit.defender) + 3

    if chance <= 0 or
        (chance < 6 and roll.melee(ctx, 6) >= chance) then
        blocked_message(ctx, hit, false, false)

        return false
    end

    local x = target.x + target.x - source.x
    local y = target.y + target.y - source.y
    local destination_blocked =
        not habitable(ctx, hit.defender, target.level_id, x, y) or
        not habitat.at(ctx, hit.attacker,
            target.level_id, target.x, target.y) or
        ctx:actor_at(target.level_id, x, y)
    local held = not destination_blocked and
        constricted(ctx, hit.defender)
    local boots = not destination_blocked and not held and
        dislodge.resists(ctx, hit.defender)

    if destination_blocked or held or boots then
        blocked_message(ctx, hit, held, boots)

        return false
    end

    -- A final effect remembers the old defender cell. It is resolved after
    -- damage and reactions, so another effect may legitimately cancel it.
    hit.trample_follow = {
        level_id = target.level_id,
        x = target.x,
        y = target.y,
    }

    displace(ctx, hit, target, x, y)

    return true
end

-- Follow only while the attacker is still alive, adjacent, and able to
-- inhabit the vacated cell. Source fineff performs this after the attack.
function trample.follow(ctx, hit)
    local cell = hit and hit.trample_follow

    if not cell then
        return false
    end

    hit.trample_follow = nil

    local health = ctx:get(hit.attacker, component.HEALTH)
    local position = ctx:get(hit.attacker, component.POSITION)

    if not health or health.current <= 0 or not position or
        position.level_id ~= cell.level_id or
        (position.x == cell.x and position.y == cell.y) or
        math.max(math.abs(position.x - cell.x),
            math.abs(position.y - cell.y)) ~= 1 or
        ctx:actor_at(cell.level_id, cell.x, cell.y) or
        not habitat.at(ctx, hit.attacker,
            cell.level_id, cell.x, cell.y) then
        return false
    end

    ctx:move_actor(hit.attacker, cell.level_id, cell.x, cell.y)

    return true
end

return trample
