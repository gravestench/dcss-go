-- Reaching attacks are read from the actor's current melee and gear profile.
-- AI and combat share this check so a projected facet cannot offer an
-- attack that the later intent resolver treats as an ordinary move.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flavours = require("constants.attack_flavours")
local terrain = require("constants.terrain")
local profile = require("policy.combat.monster_profile")
local equipment = require("policy.combat.equipment")
local skills = require("ids.skills")
local artefacts = require("ids.artefacts")
local attack_types = require("constants.monster_attack_types")
local sequence = require("policy.combat.monster_attack_sequence")

local reach = {}

local reaching_flavours = {
    [flavours.REACH] = 2,
    [flavours.REACH_STING] = 2,
    [flavours.REACH_TONGUE] = 2,
    [flavours.RIFT] = 3,
}

-- Source polearms and Lochaber reach two cells. Rift is a polearm whose
-- unique identity extends that range to three through line of sight.
local function weapon_range(weapon)
    if not weapon then
        return 1
    end

    if weapon.unique_id == artefacts.UNRAND_RIFT then
        return 3
    end

    if weapon.skill_id == skills.SK_POLEARMS or
        weapon.unique_id == artefacts.UNRAND_LOCHABER_AXE then
        return 2
    end

    return 1
end

-- The monster's offer uses its strongest natural contact or primary
-- weapon. A later per-slot check still decides which contact can land.
function reach.range(ctx, actor)
    local body = ctx:get(actor, component.ACTOR)

    if not body then
        return 1
    end

    local definition = profile.definition(ctx, actor,
        catalog.get("monsters", body.kind_id))
    local distance = weapon_range(
        equipment.monster_melee(ctx, actor))

    -- Derived undead borrow and downscale a saved base species. The
    -- ordered round is the authoritative live list for both AI and hits.
    for _, selected in ipairs(sequence.for_actor(ctx, actor,
        definition)) do
        local attack = selected.attack

        if attack.damage > 0 then
            distance = math.max(distance,
                reaching_flavours[attack.flavour_id] or 1)
        end
    end

    return distance
end

-- A distant melee round still visits every source slot. A natural
-- reaching flavour can land on its own; only a HIT slot can use a polearm.
-- Reading equipment by slot preserves dual wield order and live unequip.
function reach.contact(ctx, actor, attack, slot_index, distance)
    if attack.damage > 0 and
        (reaching_flavours[attack.flavour_id] or 1) >= distance then
        return true
    end

    if attack.type_id ~= attack_types.HIT then
        return false
    end

    return weapon_range(equipment.monster_melee(ctx,
        actor, slot_index)) >= distance
end

-- Source reach checks both possible middle cells. On diagonals, either
-- open route is enough; on a straight line they are the same cell. The
-- grid owns solidity and opacity, while this Lua rule owns the attack.
local function open_middle(ctx, level_id, x, y)
    return ctx:cell(level_id, x, y) ~= nil and
        not ctx:solid(level_id, x, y) and
        not ctx:opaque(level_id, x, y) and
        ctx:cell(level_id, x, y) ~= terrain.DNGN_GRATE
end

-- A reaching monster needs a foe two or three cells away on the same
-- level. Two-cell reach has middle-cell geometry; Rift uses solid sight.
function reach.can(ctx, actor, origin, target)
    if not origin or not target or
        origin.level_id ~= target.level_id then
        return false
    end

    local dx = target.x - origin.x
    local dy = target.y - origin.y

    local distance = math.max(math.abs(dx), math.abs(dy))

    local max_range = reach.range(ctx, actor)

    if distance < 2 or distance > max_range then
        return false
    end

    if max_range == 3 then
        return ctx:visible_no_trans(origin.level_id,
            origin.x, origin.y, 3, target.x, target.y)
    end

    local half_x = math.floor(math.abs(dx) / 2) *
        (dx < 0 and -1 or 1)
    local half_y = math.floor(math.abs(dy) / 2) *
        (dy < 0 and -1 or 1)
    local level_id = origin.level_id

    return open_middle(ctx, level_id,
        origin.x + half_x, origin.y + half_y) or
        open_middle(ctx, level_id,
            target.x - half_x, target.y - half_y)
end

return reach
