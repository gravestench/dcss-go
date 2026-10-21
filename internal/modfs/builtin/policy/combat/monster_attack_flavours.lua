-- Monster attack flavours run after a confirmed melee contact. Each flavour
-- delegates durable state to its normal owner, so generated Pan lords and
-- catalog monsters use the same saved status rules.
local catalog = require("policy.catalog")
local component = require("constants.component")
local dislodge = require("policy.combat.dislodge")
local channels = require("constants.message_channels")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local flight = require("policy.combat.flight")
local form_ids = require("constants.form_ids")
local monster_flags = require("constants.monster_flags")
local habitat = require("policy.combat.monster_habitat")
local monster_enchant = require("policy.combat.monster_enchant")
local monster_health = require("policy.combat.monster_health")
local monster_slow = require("policy.combat.monster_slow")
local player_corrosion = require("policy.combat.player_corrosion")
local player_health = require("policy.combat.player_health")
local player_slow = require("policy.character.slow")
local player_weakness = require("policy.combat.player_weakness")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")
local traits = require("constants.pan_lord_traits")
local water = require("policy.combat.monster_beams.water")
local web = require("policy.combat.monster_area.web")

local flavours = {}

local drained_stat = {
    [traits.drain_strength] = stats.STRENGTH,
    [traits.drain_intelligence] = stats.INTELLIGENCE,
    [traits.drain_dexterity] = stats.DEXTERITY,
}

-- Source melee-attack.cc gives stat drain a rare first chance and a wider
-- fallback chance. A monster has no drainable attributes in the source, but
-- the chance rolls still occur before its no-op actor method is called.
local function drain_stat(ctx, hit, field)
    if roll.melee(ctx, 20) ~= 0 and roll.melee(ctx, 3) ~= 0 then
        return false
    end

    if not ctx:has(hit.defender, component.PLAYER) then
        return false
    end

    stat_loss.drain(ctx, hit.defender, field, 1)

    return true
end

-- Source AF_CORRODE calls equipment corrosion directly. Acid splash has a
-- separate proc and must not be substituted here.
local function corrode(ctx, hit)
    if ctx:has(hit.defender, component.PLAYER) then
        return player_corrosion.corrode_equipment(ctx, hit.defender,
            "The " .. (hit.attacker_name or "monster"),
            streams.MELEE, channels.COMBAT)
    end

    return monster_enchant.corrode_equipment(ctx, hit.defender,
        hit.defender_definition,
        "The " .. (hit.attacker_name or "monster") .. "'s attack")
end

-- A hit can make a temporary web even when physical damage was zero. The
-- web owner checks body size, immunity, current hold, and terrain.
local function ensnare(ctx, hit)
    if roll.melee(ctx, 3) ~= 0 then
        return false
    end

    return web.after_hit(ctx, hit.attacker, hit.defender)
end

-- Speed drain is a separate 3-in-5 chance after contact. The strength roll
-- belongs to the effect and changes the saved Slow owner on either target.
local function drain_speed(ctx, hit)
    if roll.melee(ctx, 5) >= 3 then
        return false
    end

    local strength = 5 + roll.melee(ctx, 7)

    if ctx:has(hit.defender, component.PLAYER) then
        return player_slow.apply(ctx, hit.defender, strength)
    end

    monster_slow.apply(ctx, hit.defender,
        hit.defender_definition, strength * 10)

    return true
end

-- Water damage is a second damage event after the physical strike. Source
-- AF_DROWN skips it entirely for a defender that resists drowning.
local function drown(ctx, hit)
    if water.immune(ctx, hit.defender) then
        return false
    end

    local half = math.floor(hit.hit_dice * 3 / 4)
    local amount = half + roll.melee(ctx, half)

    if ctx:has(hit.defender, component.PLAYER) then
        player_health.damage(ctx, hit.defender, amount,
            false, hit.attacker)
    else
        monster_health.damage(ctx, hit.defender, amount,
            hit.attacker)
    end

    return true
end

-- The weakness roll is independent of physical damage. Its status owner
-- supplies stacking, duration, and the later damage penalty.
local function weaken(ctx, hit)
    if roll.melee(ctx, 2) ~= 0 then
        return false
    end

    if ctx:has(hit.defender, component.PLAYER) then
        player_weakness.apply(ctx, hit.defender, 12, streams.MELEE)
    else
        enfeeble.apply_weak(ctx, hit.defender,
            hit.defender_definition, 12, streams.MELEE)
    end

    return true
end

-- Rooted forms and stationary monsters have no legal knockback. A
-- constricted defender cannot be dragged out of its existing hold.
local function held_in_place(ctx, defender)
    if ctx:has(defender, component.CONSTRICTION) then
        return true
    end

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

-- Trample pushes away from the attacker and then follows into the vacated
-- square. Terrain and occupancy are checked before either move so failure
-- cannot strand two actors in one cell.
local function trample(ctx, hit)
    if held_in_place(ctx, hit.defender) or
        dislodge.resists(ctx, hit.defender) then
        return false
    end

    local source = ctx:get(hit.attacker, component.POSITION)
    local target = ctx:get(hit.defender, component.POSITION)

    if not source or not target or source.level_id ~= target.level_id then
        return false
    end

    local chance = dislodge.body_rank(ctx, hit.attacker) -
        dislodge.body_rank(ctx, hit.defender) + 3

    -- Source x_chance_in_y returns certain outcomes without advancing RNG.
    if chance <= 0 then
        return false
    end

    if chance < 6 and roll.melee(ctx, 6) >= chance then
        return false
    end

    local x = target.x + target.x - source.x
    local y = target.y + target.y - source.y
    local target_can_enter

    if ctx:has(hit.defender, component.PLAYER) then
        target_can_enter = ctx:walkable(target.level_id, x, y)
    else
        target_can_enter = habitat.at(ctx, hit.defender,
            target.level_id, x, y)
    end

    if not target_can_enter or
        not habitat.at(ctx, hit.attacker,
            target.level_id, target.x, target.y) or
        ctx:actor_at(target.level_id, x, y) then
        return false
    end

    ctx:move_actor(hit.defender, target.level_id, x, y)
    ctx:move_actor(hit.attacker, source.level_id, target.x, target.y)

    if ctx:has(hit.defender, component.PLAYER) then
        local motion = flight.active(ctx, hit.defender) and
            "are shoved" or "stumble"

        ctx:emit(channels.COMBAT, "You " .. motion .. " backwards!")
    elseif senses.player_sees_actor(ctx, hit.defender) then
        local motion = flight.active(ctx, hit.defender) and
            " is shoved" or " stumbles"
        local name = hit.defender_definition.name

        ctx:emit(channels.COMBAT,
            "The " .. name .. motion .. " backwards!")
    end

    return true
end

local effects = {
    [traits.corrode] = corrode,
    [traits.ensnare] = ensnare,
    [traits.drain_speed] = drain_speed,
    [traits.drown] = drown,
    [traits.weakness] = weaken,
    [traits.trample] = trample,
}

-- The caller supplies the resolved contact, avoiding effect draws on a
-- block, dodge, or miss. Unhandled flavours leave the ordinary hit intact.
function flavours.apply(ctx, flavour_id, hit)
    if hit.kind ~= "hit" then
        return false
    end

    local health = ctx:get(hit.defender, component.HEALTH)

    if not health or health.current <= 0 then
        return false
    end

    local field = drained_stat[flavour_id]

    if field then
        return drain_stat(ctx, hit, field)
    end

    local effect = effects[flavour_id]

    if effect then
        return effect(ctx, hit)
    end

    return false
end

return flavours
