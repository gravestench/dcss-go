local component = require("constants.component")
local zap_ids = require("policy.magic.effects.zaps.ids")
local spells = require("ids.spells")
local monsters = require("ids.monsters")
local damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local death_hooks = require("policy.combat.death_hooks")
local necromancy = require("policy.magic.effects.summons.necromancy")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")
local will = require("policy.magic.effects.zaps.will")
local allies = require("policy.character.allies")
local player_contact = require("policy.combat.player_contact")

local necrotise = {}

-- Check optional holiness or flag lists while filtering corpse and resistance cases.
local function has_value(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Reject summons and unskeletonizable bodies before saving a death mark.
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

-- Apply negative resistance fractions to raw Necrotise damage.
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

-- Example: A living marked rat can rise as an allied skeleton if its corpse remains unconsumed.
-- Trace first contact and save a death mark only when the target can leave a usable skeleton.
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

    player_contact.report(ctx, target, definition)

    local negative = damage.monster_resistance(ctx, target,
        resistances.NEGATIVE_ENERGY)

    if health.current <= 0 or negative >= 3 then
        return
    end

    -- zap-data.h:ZAP_NECROTISE caps at 100 and enchants at 7*power/2.
    local capped = math.min(power, 100)

    if will.resists(ctx, definition, math.floor(capped * 7 / 2),
        target, nil, player) then
        ctx:emit("spell", "The " .. definition.name .. " resists necrotising.")
        return
    end

    local raw = 1 + ctx:random("spell", 4 + math.floor(capped / 5))
    local amount = resist_damage(raw, negative)

    if amount <= 0 then
        return
    end

    if not allies.forbidden(ctx, player) and
        can_skeletonize(ctx, target, definition) then
        local mark = {
            source = player,
            expires_aut = ctx:aut() + 10,
        }

        -- Mark before dealing lethal damage so the death hook can see the
        -- ten-aut skeletonization window.
        if ctx:has(target, zap_ids.component.NECROTISE) then
            ctx:set(target, zap_ids.component.NECROTISE, mark)
        else
            ctx:add(target, zap_ids.component.NECROTISE, mark)
        end
    end

    damage.apply(ctx, target, amount)
    ctx:emit("spell", "The " .. definition.name .. " writhes in agony!")
end

-- Use an unconsumed marked corpse for a skeleton; another death effect may have claimed it.
function necrotise.on_death(ctx, monster, definition, position,
    _, consumed_corpse)
    -- A corpse already consumed by another death effect cannot also become
    -- Necrotise's allied skeleton.
    local mark = ctx:get(monster, zap_ids.component.NECROTISE)

    if not mark or consumed_corpse or
        allies.forbidden(ctx, mark.source) then
        return false
    end

    if ctx:aut() > mark.expires_aut then
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
