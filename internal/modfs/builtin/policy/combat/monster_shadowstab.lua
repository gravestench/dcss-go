-- Shadowstab is one attack with three source melee phases: unseen contact,
-- pre-armour stab damage, and loss of temporary invisibility after a hit.
-- Keeping them together prevents the two defender paths from drifting.
local behaviors = require("constants.ai_behaviors")
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local senses = require("policy.character.senses")
local hex_status = require("policy.combat.monster_hexes.status")
local monster_senses = require("policy.combat.monster_senses")
local player_invisibility = require("policy.potions.invisibility")
local flavours = require("constants.attack_flavours")

local shadowstab = {}

-- Catalog flags represent innate invisibility; the enchant timer represents
-- spell invisibility. Backlighting and fire champion make either visible.
local function monster_invisible(ctx, monster, definition)
    if ctx:has(monster, component.IGNIS_FIRE_CHAMPION) or
        hex_status.backlit(ctx, monster) then
        return false
    end

    local enchant = ctx:get(monster, component.MONSTER_ENCHANT)

    if enchant and enchant.invisible_aut > 0 then
        return true
    end

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.INVISIBLE then
            return true
        end
    end

    return false
end

-- Source actor::can_see checks map sight and creature visibility. A blind
-- monster cannot identify the Shadow even with see-invisible equipment.
local function monster_sees(ctx, defender, attacker)
    local eye = ctx:get(defender, component.POSITION)
    local target = ctx:get(attacker, component.POSITION)

    if not eye or not target or eye.level_id ~= target.level_id or
        not ctx:visible(eye.level_id, eye.x, eye.y, 7,
            target.x, target.y) then
        return false
    end

    local enchant = ctx:get(defender, component.MONSTER_ENCHANT)

    if enchant and enchant.blind_aut > 0 then
        return false
    end

    local attacker_actor = ctx:get(attacker, component.ACTOR)
    local attacker_def = catalog.get("monsters", attacker_actor.kind_id)

    if not monster_invisible(ctx, attacker, attacker_def) then
        return true
    end

    local defender_actor = ctx:get(defender, component.ACTOR)
    local defender_def = catalog.get("monsters", defender_actor.kind_id)

    return monster_senses.see_invisible(ctx, defender, defender_def)
end

-- The player and monster have different perception owners. A target that
-- cannot see this particular attacker grants the source automatic contact.
function shadowstab.unseen(ctx, attacker, defender)
    if ctx:has(defender, component.PLAYER) then
        return not senses.player_sees_actor(ctx, attacker)
    end

    return not monster_sees(ctx, defender, attacker)
end

-- Sleep gives any monster melee attack a stab bonus. Shadowstab adds that
-- bonus when unseen, but the two openings never multiply one another twice.
local function defender_asleep(ctx, defender)
    if ctx:has(defender, component.PLAYER) then
        local sleep = ctx:get(defender, component.PLAYER_SLEEP)

        return sleep ~= nil and sleep.remaining_aut > 0
    end

    local stasis = ctx:get(defender, component.MONSTER_STASIS)
    local ai = ctx:get(defender, component.AI)

    return stasis ~= nil and stasis.hibernating or
        ai ~= nil and ai.behavior == behaviors.SLEEP
end

-- Source applies 5/2 to raw monster damage before the defender's armour.
-- Ordinary melee against a sleeper shares this rule with Shadowstab.
function shadowstab.damage(ctx, attack, raw)
    if not attack.defender then
        return raw
    end

    local opening = defender_asleep(ctx, attack.defender) or
        attack.flavour_id == flavours.SHADOWSTAB and attack.attacker and
        shadowstab.unseen(ctx, attack.attacker, attack.defender)

    if opening then
        return math.floor(raw * 5 / 2)
    end

    return raw
end

-- Source announces the darkness strike only when the player's current
-- view contains the attacked cell. The normal hit line is then suppressed.
function shadowstab.announce(ctx, attacker, defender)
    local position = ctx:get(defender, component.POSITION)

    if not senses.player_sees_cell(ctx, position) then
        return
    end

    local actor = ctx:get(attacker, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local target = "you"

    if not ctx:has(defender, component.PLAYER) then
        local defender_actor = ctx:get(defender, component.ACTOR)
        local defender_def = catalog.get("monsters",
            defender_actor.kind_id)

        target = "the " .. defender_def.name
    end

    ctx:emit(channels.COMBAT, "The " .. definition.name ..
        " strikes at " .. target .. " from the darkness!")
end

-- Flavour resolution occurs after a confirmed hit, including a hit whose
-- physical damage was wholly absorbed. Keep unrelated enchant fields.
function shadowstab.after_hit(ctx, hit)
    if hit.kind ~= "hit" then
        return false
    end

    local enchant = ctx:get(hit.attacker, component.MONSTER_ENCHANT)

    if not enchant or enchant.invisible_aut <= 0 then
        return false
    end

    enchant.invisible_aut = 0

    if enchant.blind_aut == 0 and enchant.corrosion_aut == 0 then
        ctx:remove(hit.attacker, component.MONSTER_ENCHANT)
    else
        ctx:set(hit.attacker, component.MONSTER_ENCHANT, enchant)
    end

    return true
end

return shadowstab
