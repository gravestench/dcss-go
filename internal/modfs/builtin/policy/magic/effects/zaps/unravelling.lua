local component = require("constants.component")
local damage = require("policy.magic.damage")
local defense = require("policy.combat.monster_defense")
local enchant = require("policy.combat.monster_enchant")
local explosion = require("policy.combat.explosion")
local irradiate = require("policy.magic.effects.zaps.irradiate")
local range = require("policy.magic.range")
local summons = require("policy.magic.effects.summons.common")

local unravelling = {}

local function roll_damage(ctx, power)
    local sides = 3 + math.floor(math.min(power, 200) / 6)
    local amount = 0

    for _ = 1, 3 do
        amount = amount + 1 + ctx:random("spell", sides)
    end

    return amount
end

function unravelling.prepare(ctx, player, spell, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + dx
    local y = origin.y + dy
    local reach = range.for_spell(ctx, player, spell)

    if math.max(math.abs(dx), math.abs(dy)) > reach or
        not ctx:walkable(origin.level_id, x, y) or
        not ctx:visible(origin.level_id, origin.x, origin.y,
            reach, x, y) then
        return "You cannot unravel magic there."
    end

    local target = ctx:actor_at(origin.level_id, x, y)

    if not target or target == player then
        return "There are no magical effects to unravel."
    end

    if not enchant.can_dispel(ctx, target) and
        not ctx:has(target, component.SUMMON) then
        return "There are no magical effects to unravel."
    end
end

function unravelling.affect_monster(ctx, target, power)
    local definition, current = damage.monster(ctx, target)

    if not definition or current.current <= 0 then
        return
    end

    -- beam.cc applies the mutagenic enchantment before normal blast damage.
    irradiate.wretch(ctx, target, definition)

    local raw = roll_damage(ctx, power)
    local ac = defense.armour(ctx, target, definition)
    local amount = math.max(0, raw - ctx:random("spell", ac + 1))

    damage.apply(ctx, target, amount)
end

function unravelling.resolve(ctx, player, intent, _, power)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + intent.dx
    local y = origin.y + intent.dy
    local target = ctx:actor_at(origin.level_id, x, y)

    if not target then
        return
    end

    if ctx:has(target, component.SUMMON) then
        summons.expire(ctx, target)
    else
        local definition = damage.monster(ctx, target)

        enchant.dispel(ctx, target, definition)
    end

    ctx:emit("spell", "Unravelled magic bursts outward!")

    for _, cell in ipairs(explosion.cells(ctx, origin.level_id,
        x, y, 1)) do
        local victim = ctx:actor_at(origin.level_id, cell.x, cell.y)

        if victim == player then
            error("Unravelling requires saved player malmutation support")
        elseif victim then
            unravelling.affect_monster(ctx, victim, power)
        end
    end
end

-- Registration waits for a saved player mutation domain. The one-cell blast
-- can reach its caster, so enabling this early would silently omit malmutation.
return unravelling
