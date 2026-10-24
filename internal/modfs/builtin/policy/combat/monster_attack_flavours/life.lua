-- Natural melee life theft and magic disruption use the resolved contact.
-- Weapon brands share some saved state owners, but have different chances
-- and power formulas, so their proc policy does not decide these flavours.
local component = require("constants.component")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local life_transfer = require("policy.combat.life_transfer")
local necromancy = require("policy.combat.brand_necromancy")
local monster_flags = require("constants.monster_flags")
local monster_health = require("policy.combat.monster_health")
local monster_slow = require("policy.combat.monster_slow")
local player_drain = require("policy.combat.player_drain")
local player_health = require("policy.combat.player_health")
local player_slow = require("policy.character.slow")
local roll = require("policy.combat.roll")
local resistances = require("constants.resistance_ids")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")
local monsters = require("ids.monsters")

local life = {}

-- The second negative-energy packet can be lethal after the physical
-- strike. Preserve player or allied kill credit through the usual signal.
local function damage_monster(ctx, hit, amount)
    if amount <= 0 then
        return false
    end

    local health, dealt = monster_health.damage(ctx, hit.defender,
        amount, hit.attacker)

    if hit.player_credit and dealt > 0 and health.current == 0 then
        ctx:signal("player_kill", hit.defender)
    end

    return dealt > 0
end

-- `drain_defender` starts with a second skip against monsters. The saved
-- monster drain owner then supplies its own small HP packet and timed HD
-- penalty before this contact's negative-energy bonus is applied.
local function drain_monster(ctx, hit)
    if roll.melee(ctx, 2) == 0 then
        return false
    end

    if not life_transfer.living(ctx, hit.defender) then
        return false
    end

    local resistance = life_transfer.resistance(ctx, hit.defender)

    if resistance >= 3 then
        return false
    end

    local raw = math.floor((1 + roll.melee(ctx,
        hit.damage_done)) / 2)
    local bonus = life_transfer.resisted(raw, resistance, true)
    local monster_drain = require("policy.combat.monster_drain")

    monster_drain.apply(ctx, hit.defender,
        hit.defender_definition, hit.attacker, streams.MELEE,
        hit.player_credit)

    if ctx:get(hit.defender, component.HEALTH).current > 0 then
        damage_monster(ctx, hit, bonus)
    end

    return true
end

-- Player drain reduces temporary maximum HP before the bonus packet.
-- Source `drain_player` halves power per positive rN pip and refuses rN3;
-- the generic saved status owner receives that already adjusted power.
local function drain_player(ctx, hit)
    local resistance = life_transfer.resistance(ctx, hit.defender)

    if resistance >= 3 then
        return false
    end

    local raw = math.floor((1 + roll.melee(ctx,
        hit.damage_done)) / 2)
    local bonus = life_transfer.resisted(raw, resistance, false)

    local power = hit.damage_done + 1

    if resistance > 0 then
        power = math.floor(power / (resistance * 2))
    end

    if power > 0 then
        player_drain.apply(ctx, hit.defender, power,
            streams.MELEE)
    end

    if bonus > 0 then
        player_health.damage(ctx, hit.defender, bonus,
            false, hit.attacker)
    end

    return true
end

-- AF_DRAIN has one outer coin flip before actor-specific drain_defender.
-- A monster defender spends the routine's second coin flip independently.
function life.drain(ctx, hit)
    if hit.damage_done <= 0 or
        roll.melee(ctx, 2) ~= 0 then
        return false
    end

    if ctx:has(hit.defender, component.PLAYER) then
        if not life_transfer.living(ctx, hit.defender) then
            return false
        end

        return drain_player(ctx, hit)
    end

    return drain_monster(ctx, hit)
end

-- Natural Vampiric contact has no weapon-brand 2/5 veto. It heals only
-- from a susceptible victim already injured by the physical strike and
-- scales the healed amount through that victim's live negative resistance.
function life.vampiric(ctx, hit)
    if hit.damage_done <= 0 or
        not life_transfer.susceptible(ctx, hit.defender) then
        return false
    end

    local attacker = ctx:get(hit.attacker, component.HEALTH)
    local victim = ctx:get(hit.defender, component.HEALTH)

    if not attacker or attacker.current <= 0 or
        not victim or victim.current >= victim.max then
        return false
    end

    local raw = 1 + roll.melee(ctx, hit.damage_done)

    local resistance = life_transfer.resistance(ctx, hit.defender)
    local healed = life_transfer.resisted(raw, resistance,
        not ctx:has(hit.defender, component.PLAYER))

    if healed <= 0 then
        return false
    end

    attacker.current = math.min(attacker.max,
        attacker.current + healed)
    ctx:set(hit.attacker, component.HEALTH, attacker)

    if ctx:has(hit.defender, component.PLAYER) then
        ctx:emit(channels.COMBAT, "The " .. hit.attacker_name ..
            " draws strength from your wounds!")
    else
        ctx:emit(channels.COMBAT, "The " .. hit.attacker_name ..
            " is healed.")
    end

    return true
end

-- Speed drain rolls three chances in five, then a 5..11 strength.
-- Its recipient's saved Slow owner supplies duration and resistance.
function life.drain_speed(ctx, hit)
    if hit.damage_done <= 0 or roll.melee(ctx, 5) >= 3 then
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

-- Scarab deliberately falls through from speed drain into natural
-- Vampiric in source melee; either effect may succeed independently.
function life.scarab(ctx, hit)
    if hit.damage_done <= 0 then
        return false
    end

    local slowed = life.drain_speed(ctx, hit)
    local healed = life.vampiric(ctx, hit)

    return slowed or healed
end

-- Pain rolls Necromancy skill separately for activation and damage.
-- The second packet is negative energy on either kind of defender; the
-- live resistance owner handles undead immunity and temporary gear.
function life.pain(ctx, hit)
    if hit.damage_done <= 0 then
        return false
    end

    local skill = necromancy.monster_skill(ctx, hit.attacker)

    if roll.melee(ctx, skill + 1) == 0 then
        return false
    end

    local raw = roll.melee(ctx,
        necromancy.monster_skill(ctx, hit.attacker) + 1)
    local amount

    if ctx:has(hit.defender, component.PLAYER) then
        amount = damage.player_elemental(ctx, hit.defender,
            raw, resistances.NEGATIVE_ENERGY)

        if amount > 0 then
            player_health.damage(ctx, hit.defender, amount,
                false, hit.attacker)
            ctx:emit(channels.COMBAT, "You writhe in agony!")
        end
    else
        amount = damage.monster_elemental(ctx, hit.defender,
            raw, resistances.NEGATIVE_ENERGY)

        if damage_monster(ctx, hit, amount) then
            ctx:emit(channels.COMBAT, "The " .. hit.defender_definition.name ..
                " writhes in agony!")
        end
    end

    return amount > 0
end

-- `BEAM_DRAIN_MAGIC` averages three draws below power/8 before subtracting
-- current MP. Ghost moths regain exactly the MP removed by that beam.
local function drain_player_magic(ctx, hit, power)
    local magic = ctx:get(hit.defender, component.MAGIC)

    if not magic or magic.current <= 0 then
        return false
    end

    local amount = roll.average_three(ctx, streams.MELEE,
        math.floor(power / 8))
    amount = math.min(magic.current, amount)

    if amount <= 0 then
        return false
    end

    magic.current = magic.current - amount
    ctx:set(hit.defender, component.MAGIC, magic)
    ctx:emit(channels.COMBAT, "You feel your power leaking away.")

    local actor = ctx:get(hit.attacker, component.ACTOR)

    if actor.kind_id == monsters.MONS_GHOST_MOTH then
        local health = ctx:get(hit.attacker, component.HEALTH)

        health.current = math.min(health.max,
            health.current + amount)
        ctx:set(hit.attacker, component.HEALTH, health)
    end

    return true
end

-- Source firewood has no meaningful energy or threat to revive a vine.
-- The same compact predicate is used for natural life transfer.
local function firewood(definition)
    if definition.speed ~= 0 then
        return false
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == monster_flags.NO_THREAT then
            return true
        end
    end

    return false
end

-- A vine stalker under antimagic shortens its own enchantment after a
-- contact with a player or a lasting, non-summoned monster. This source
-- follow-up happens even if the victim had no MP left to drain.
local function invigorate_vine(ctx, hit)
    local actor = ctx:get(hit.attacker, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local status = ctx:get(hit.attacker, component.MONSTER_ENFEEBLE)

    if definition.genus_id ~= monsters.MONS_VINE_STALKER or
        not status or status.antimagic_aut <= 0 then
        return false
    end

    if not ctx:has(hit.defender, component.PLAYER) and
        (ctx:has(hit.defender, component.SUMMON) or
            firewood(hit.defender_definition)) then
        return false
    end

    status.antimagic_aut = math.max(0,
        status.antimagic_aut - 1 - roll.melee(ctx,
            hit.damage_done))
    ctx:set(hit.attacker, component.MONSTER_ENFEEBLE, status)
    if senses.player_sees_actor(ctx, hit.attacker) then
        local magic = ctx:get(hit.defender, component.MAGIC)
        local spell_user = magic and magic.max > 0 or
            hit.defender_definition and
            enfeeble.antimagic_susceptible(ctx, hit.defender)
        local word = spell_user and " very" or ""

        ctx:emit(channels.COMBAT, "The " .. definition.name ..
            " looks" .. word .. " invigorated.")
    end

    return true
end

-- Natural Antimagic passes monster HD times twelve to the magic-drain
-- beam, whereas the weapon brand uses dealt damage times eight.
function life.antimagic(ctx, hit)
    if hit.damage_done <= 0 then
        return false
    end

    local power = hit.hit_dice * 12

    local applied

    if ctx:has(hit.defender, component.PLAYER) then
        applied = drain_player_magic(ctx, hit, power)
    else
        applied = enfeeble.apply_antimagic(ctx, hit.defender,
            hit.defender_definition, power)
    end

    local invigorated = invigorate_vine(ctx, hit)

    return applied or invigorated
end

return life
