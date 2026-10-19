local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")

-- Resolve the selected grid cell again for both validation and the actual weapon transfer.
local function target_at(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)

    return ctx:actor_at(origin.level_id, origin.x + dx, origin.y + dy)
end

-- Prefer the primary weapon, falling back to the alternate slot before declaring a monster unarmed.
local function wielded(ctx, target)
    local worn = equipment.worn(ctx, target, {
        weapon = true,
        alternate_weapon = true,
    })

    return worn.weapon or worn.alternate_weapon
end

-- Avoid stealing from the caster or a summon, and require a real weapon before spawning its dancer.
local function eligible(ctx, player, target)
    if not target or target == player or
        ctx:has(target, component.SUMMON) then
        return nil
    end

    local entry = wielded(ctx, target)

    if not entry or entry.definition.class ~= "OBJ_WEAPONS" or
        not entry.definition.weapon then
        return nil
    end

    return entry
end

-- Source: spl-summoning.cc:tukima_affects and cast_tukimas_dance.
local spell_effects = {}

-- Example: Tukima's Dance rejects an aimed cell without a suitable weapon to animate.
-- Require a real wielded weapon before paying; the resolve path transfers that item to a summon.
function spell_effects.prepare(ctx, player, _, dx, dy)
    local target = target_at(ctx, player, dx, dy)

    if not eligible(ctx, player, target) then
        return "There is no suitable weapon to animate there."
    end
end

-- Tukima's Dance moves the target weapon into an animated summon and equips it there.
function spell_effects.resolve(ctx, player, intent, _, power)
    local target = target_at(ctx, player, intent.dx, intent.dy)
    local entry = eligible(ctx, player, target)

    if not entry then
        return
    end

    local duration = math.min(2 + math.floor(summons.roll(ctx,
        math.max(1, power)) / 5), 6)
    local anchor = ctx:get(target, component.POSITION)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_TUKIMAS_DANCE, monsters.MONS_DANCING_WEAPON, duration,
        999, { anchor = anchor })

    if not creature then
        return
    end

    local item = entry.item
    local definition = catalog.get("items", item.kind_id)

    if definition.class ~= "OBJ_WEAPONS" then
        error("Tukima's Dance target changed weapon class")
    end

    ctx:destroy(entry.entity)
    local animated = ctx:create()
    ctx:add(animated, component.ITEM, item)
    ctx:add(animated, component.CARRIED_BY, { holder = creature })
    ctx:add(animated, "core.equipped", { slot = "weapon" })
    ctx:emit("spell", "The " .. definition.name .. " dances into the air!")
end

registry.add(spells.SPELL_TUKIMAS_DANCE, {
    prepare = spell_effects.prepare,
    resolve = spell_effects.resolve,
})

return spell_effects
