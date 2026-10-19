local component = require("constants.component")
local order = require("constants.damage_reaction_order")
local mutations = require("ids.mutations")
local reactions = require("policy.combat.player_damage_reactions")
local levels = require("policy.mutations.levels")
local might = require("policy.character.might")
local agility = require("policy.character.agility")

local powered_by_pain = {}

-- Use a mutation-stream remainder draw to preserve fractional expected MP
-- recovery while storing only integer resources.
local function rounded_divide(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("mutation", denominator) < remainder then
        return whole + 1
    end

    return whole
end

-- Consume the chance draw before the half-HP shortcut, matching the source
-- RNG sequence even when a sufficiently large hit guarantees activation.
local function triggered(ctx, player, damage)
    local progression = ctx:get(player, component.PROGRESSION)
    local health = ctx:get(player, component.HEALTH)

    if not progression or not health then
        error("powered by pain requires player progression and health")
    end

    -- Source: ouch.cc:_powered_by_pain evaluates the random test before
    -- the half-HP shortcut, even when the shortcut will trigger.
    local rolled = ctx:random("mutation", damage)
    local threshold = 4 + rounded_divide(ctx, progression.level, 4)

    return rolled > threshold or damage >= health.max / 2
end

-- Roll the level-scaled MP gain only below maximum, then write the resource
-- component back so the restoration survives the current action.
local function restore_magic(ctx, player, level)
    local magic = ctx:get(player, component.MAGIC)

    if not magic or magic.current >= magic.max then
        return
    end

    ctx:emit("mutation", "You focus on the pain.")

    local sides = 2 + 3 * level
    local restored = 0

    for _ = 1, 3 do
        restored = restored + 1 + ctx:random("mutation", sides)
    end

    magic.current = math.min(magic.max, magic.current + restored)
    ctx:set(player, component.MAGIC, magic)
    ctx:emit("mutation", "You feel your power returning.")
end

-- Compare damage with the level threshold and maximum HP before choosing a mutation effect.
-- Example: a large hit can restore MP, with its amount and effect branch drawn from the mutation stream.
function powered_by_pain.on_damage(ctx, player, damage)
    local level = levels.effective(ctx, player,
        mutations.MUT_POWERED_BY_PAIN)

    if level <= 0 or not triggered(ctx, player, damage) then
        return
    end

    local effect = ctx:random("mutation", 4)

    if effect < 2 then
        restore_magic(ctx, player, level)
    elseif effect == 2 then
        ctx:emit("mutation", "You focus on the pain.")
        ctx:emit("duration", might.apply(ctx, player,
            level * 20, "mutation"))
    else
        ctx:emit("mutation", "You focus on the pain.")
        ctx:emit("duration", agility.apply(ctx, player,
            level * 20, "mutation"))
    end
end

reactions.add(mutations.MUT_POWERED_BY_PAIN,
    order.POWERED_BY_PAIN, powered_by_pain.on_damage)

return powered_by_pain
