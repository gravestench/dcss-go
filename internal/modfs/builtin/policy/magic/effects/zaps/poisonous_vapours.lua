local component = require("constants.component")
local spells = require("ids.spells")
local catalog = require("policy.catalog")
local poison = require("policy.combat.monster_poison")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")

local poisonous_vapours = {}

-- Resolve the aimed adjacent cell before checking occupant and existing cloud state.
local function target(ctx, player, dx, dy)
    local origin = ctx:get(player, component.POSITION)
    local x = origin.x + dx
    local y = origin.y + dy

    return origin, x, y, ctx:actor_at(origin.level_id, x, y)
end

-- Example: Aimed vapours fizzle on an empty cell but poison an eligible adjacent monster.
-- Validate the aimed cell and reject poison-resistant occupants before the cast commits.
function poisonous_vapours.prepare(ctx, player, spell, dx, dy)
    local origin, x, y, monster = target(ctx, player, dx, dy)
    local reach = range.for_spell(ctx, player, spell)

    if math.max(math.abs(dx), math.abs(dy)) > reach or
        not ctx:visible(origin.level_id, origin.x, origin.y, reach, x, y) or
        not ctx:walkable(origin.level_id, x, y) then
        return "You cannot surround that with poisonous vapours."
    end

    if monster and monster ~= player then
        local actor = ctx:get(monster, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        if poison.resistance(definition) > 0 then
            return "That creature cannot be affected by poisonous vapours!"
        end
    end
end

-- Fizzle without a monster target; otherwise place poison only after target checks.
function poisonous_vapours.resolve(ctx, player, intent, _, power)
    local _, _, _, monster = target(ctx, player, intent.dx, intent.dy)

    if not monster or monster == player then
        ctx:emit("spell", "The spell fizzles.")
        return
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    if poison.resistance(definition) > 0 then
        ctx:emit("spell", "The spell fizzles.")
        return
    end

    -- spl-damage.cc:cast_poisonous_vapours uses max(1, div_rand_round(pow,15)).
    local amount = math.floor(power / 15)
    local remainder = power % 15

    if ctx:random("spell", 15) < remainder then
        amount = amount + 1
    end

    ctx:emit("spell", "Poisonous vapours surround the " ..
        definition.name .. "!")
    poison.apply(ctx, monster, definition, math.max(1, amount), player, false)
end

registry.add(spells.SPELL_POISONOUS_VAPOURS, poisonous_vapours)

return poisonous_vapours
