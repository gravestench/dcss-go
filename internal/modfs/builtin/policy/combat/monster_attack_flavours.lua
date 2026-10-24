-- Monster attack flavours run after a confirmed melee contact. Each flavour
-- delegates durable state to its normal owner, so generated Pan lords and
-- catalog monsters use the same saved status rules.
local component = require("constants.component")
local attack_ids = require("constants.attack_flavours")
local channels = require("constants.message_channels")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local monster_enchant = require("policy.combat.monster_enchant")
local monster_health = require("policy.combat.monster_health")
local monster_slow = require("policy.combat.monster_slow")
local player_corrosion = require("policy.combat.player_corrosion")
local player_health = require("policy.combat.player_health")
local player_slow = require("policy.character.slow")
local player_weakness = require("policy.combat.player_weakness")
local roll = require("policy.combat.roll")
local stat_loss = require("policy.character.stat_loss")
local stats = require("constants.stats")
local streams = require("constants.rng_streams")
local traits = require("constants.pan_lord_traits")
local resistances = require("constants.resistance_ids")
local trample = require("policy.combat.trample")
local water = require("policy.combat.monster_beams.water")
local web = require("policy.combat.monster_area.web")
local sticky_flame = require("policy.combat.sticky_flame")

local flavours = {}

local drained_stat = {
    [traits.drain_strength] = stats.STRENGTH,
    [traits.drain_intelligence] = stats.INTELLIGENCE,
    [traits.drain_dexterity] = stats.DEXTERITY,
}

-- A monster ally's extra flavour packet can make the killing blow after
-- the physical strike. Award it through the same signal as ordinary melee.
local function damage_monster(ctx, hit, amount)
    local health, dealt = monster_health.damage(ctx, hit.defender,
        amount, hit.attacker)

    if hit.player_credit and dealt > 0 and health.current == 0 then
        ctx:signal("player_kill", hit.defender)
    end

    return dealt > 0
end

-- Source flavour_damage rolls an extra elemental packet after physical
-- contact. It is separate HP loss, so existing player and monster damage
-- owners still apply death, reflection, and temporary resistance rules.
local function elemental(ctx, hit, kind)
    if hit.damage_done <= 0 then
        return false
    end

    local hd = hit.hit_dice
    local raw
    local resistance_id

    if kind == attack_ids.FIRE then
        raw = hd + roll.melee(ctx, hd)
        resistance_id = resistances.FIRE
    elseif kind == attack_ids.COLD then
        raw = hd + roll.melee(ctx, hd * 2)
        resistance_id = resistances.COLD
    else
        raw = hd + roll.melee(ctx, math.floor(hd / 2))
        resistance_id = resistances.ELECTRICITY
    end

    -- Loading this owner at impact avoids a module cycle through fighter,
    -- which also resolves ordinary melee before the flavour packet.
    local damage = require("policy.magic.damage")
    local amount

    if ctx:has(hit.defender, component.PLAYER) then
        amount = damage.player_elemental(ctx, hit.defender, raw,
            resistance_id)
        player_health.damage(ctx, hit.defender, amount,
            false, hit.attacker)
    else
        amount = damage.monster_elemental(ctx, hit.defender,
            raw, resistance_id)

        return damage_monster(ctx, hit, amount)
    end

    return amount > 0
end

-- Keep each dispatch target named so a modder can find the colour's rule.
local function fire(ctx, hit)
    return elemental(ctx, hit, attack_ids.FIRE)
end

-- Cold has a wider second roll than fire at the same monster HD.
local function cold(ctx, hit)
    return elemental(ctx, hit, attack_ids.COLD)
end

-- Electricity has a shorter bonus roll and a stronger resistance divisor.
local function electricity(ctx, hit)
    return elemental(ctx, hit, attack_ids.ELECTRICITY)
end

-- Source AF_ACID calls splash_with_acid rather than equipment corrosion
-- alone. Players take a 4d3 packet; monsters take 2d4. Both use their
-- existing corrosion owner after the separate elemental resistance check.
local function acid(ctx, hit)
    if hit.damage_done <= 0 then
        return false
    end

    if ctx:has(hit.defender, component.PLAYER) then
        require("policy.combat.brands.acid").apply(ctx, hit)

        return true
    end

    local damage = require("policy.magic.damage")

    if damage.monster_resistance(ctx, hit.defender,
        resistances.ACID) >= 3 then
        return false
    end

    local raw = 2 + roll.melee(ctx, 4) + roll.melee(ctx, 4)
    local amount = damage.monster_elemental(ctx, hit.defender,
        raw, resistances.ACID)

    monster_enchant.corrode(ctx, hit.defender,
        hit.defender_definition)
    return damage_monster(ctx, hit, amount)
end

-- Very ugly red things replace a fire packet with the source one-in-three
-- liquid-flame application. The saved status owner handles later burns.
local function napalm(ctx, hit)
    if hit.damage_done <= 0 or roll.melee(ctx, 3) ~= 0 then
        return false
    end

    if ctx:has(hit.defender, component.PLAYER) then
        return sticky_flame.apply_player(ctx, hit.attacker,
            hit.defender, streams.MELEE)
    end

    local degree = math.min(4,
        1 + math.floor(roll.melee(ctx, hit.hit_dice) / 2))

    return sticky_flame.apply(ctx, hit.attacker, hit.defender,
        hit.defender_definition, hit.damage_done, degree)
end

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
    if hit.player_moving or roll.melee(ctx, 3) ~= 0 then
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

local effects = {
    [attack_ids.FIRE] = fire,
    [attack_ids.COLD] = cold,
    [attack_ids.ELECTRICITY] = electricity,
    [attack_ids.ACID] = acid,
    [attack_ids.STICKY_FLAME] = napalm,
    [traits.corrode] = corrode,
    [traits.ensnare] = ensnare,
    [traits.drain_speed] = drain_speed,
    [traits.drown] = drown,
    [traits.weakness] = weaken,
    [traits.trample] = trample.attempt,
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
