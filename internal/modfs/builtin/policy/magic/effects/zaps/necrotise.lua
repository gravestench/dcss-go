local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local monsters = require("ids.monsters")
local damage = require("policy.magic.damage")
local death_hooks = require("policy.combat.death_hooks")
local necromancy = require("policy.magic.effects.summons.necromancy")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")

local necrotise = {}

local function has_value(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function resistance(definition)
    if not has_value(definition.holiness, "MH_NATURAL") and
        not has_value(definition.holiness, "MH_PLANT") then
        return 3
    end

    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == "MR_RES_NEG" then
            return entry.level
        end
    end

    return 0
end

local function can_skeletonize(ctx, target, definition)
    if ctx:has(target, component.SUMMON) or
        has_value(definition.flags, "M_NO_ZOMBIE") or
        has_value(definition.flags, "M_NO_SKELETON") or
        has_value(definition.flags, "M_INSUBSTANTIAL") or
        not (has_value(definition.holiness, "MH_NATURAL") or
            definition.leaves_corpse) then
        return false
    end

    for _, attack in ipairs(definition.attacks or {}) do
        if attack.type_id ~= "AT_NONE" then
            return true
        end
    end

    return false
end

local function resist_damage(raw, level)
    if level >= 3 then
        return 0
    elseif level > 0 then
        return math.floor(raw / (level * 2))
    elseif level < 0 then
        return math.floor(raw * 3 / 2)
    end

    return raw
end

function necrotise.resolve(ctx, player, intent, spell, power)
    local origin = ctx:get(player, component.POSITION)
    local ray = trajectory.trace(ctx, origin.level_id, origin.x, origin.y,
        origin.x + intent.dx, origin.y + intent.dy,
        range.for_spell(ctx, player, spell))
    local contact = ray.contacts[1]

    if not contact then
        return
    end

    local target = contact.actor
    local definition, health = damage.monster(ctx, target)

    if not definition or not health then
        error("Necrotise struck an actor without health")
    end

    local negative = resistance(definition)

    if health.current <= 0 or negative >= 3 then
        return
    end

    -- zap-data.h:ZAP_NECROTISE caps at 100 and enchants at 7*power/2.
    local capped = math.min(power, 100)

    if will.resists(ctx, definition, math.floor(capped * 7 / 2)) then
        ctx:emit("spell", "The " .. definition.name .. " resists necrotising.")
        return
    end

    local raw = 1 + ctx:random("spell", 4 + math.floor(capped / 5))
    local amount = resist_damage(raw, negative)

    if amount <= 0 then
        return
    end

    if can_skeletonize(ctx, target, definition) then
        local mark = {
            source = player,
            expires_aut = ctx:aut() + 10,
        }

        if ctx:has(target, zap_ids.component.NECROTISE) then
            ctx:set(target, zap_ids.component.NECROTISE, mark)
        else
            ctx:add(target, zap_ids.component.NECROTISE, mark)
        end
    end

    damage.apply(ctx, target, amount)
    ctx:emit("spell", "The " .. definition.name .. " writhes in agony!")
end

function necrotise.on_death(ctx, monster, definition, position,
    _, consumed_corpse)
    local mark = ctx:get(monster, zap_ids.component.NECROTISE)

    if not mark or consumed_corpse or ctx:aut() > mark.expires_aut then
        return false
    end

    if necromancy.raise(ctx, mark.source, spells.SPELL_NECROTISE,
        monsters.MONS_SKELETON, definition.id, position) then
        ctx:emit("spell", "The dead monster rises as a skeleton.")
    end

    return true
end

death_hooks.add(zap_ids.component.NECROTISE, necrotise.on_death)
registry.add(spells.SPELL_NECROTISE, necrotise)

return necrotise
