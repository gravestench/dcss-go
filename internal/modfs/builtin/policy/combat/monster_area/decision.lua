-- Monster area spells must evaluate all prospective bodies before a cast.
-- Source mons_should_fire compares expected foe and friend impact using
-- `foe_ratio`; spell files supply their own harmlessness and damage scale.
-- Example: with ratio 80, one equally strong foe and ally are not enough.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local monster_stats = require("policy.combat.monster_stats")
local targets = require("policy.ai.targets")

local decision = {}

-- The source tracer weighs damage by the victim's HD. A player's current
-- experience level fills the same role when the victim is the player.
local function hit_dice(ctx, actor)
    if ctx:has(actor, component.PLAYER) then
        local progression = ctx:get(actor, component.PROGRESSION)

        return progression and math.max(1, progression.level) or 1
    end

    local state = ctx:get(actor, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    return monster_stats.hit_dice(ctx, actor, definition)
end

-- `impact` optionally returns a nonnegative expected damage scale for this
-- spell and victim. Zero excludes an immune body from both totals; absent
-- spell-specific estimates give every living body the same base scale.
function decision.weights(ctx, caster, victims, impact)
    local foes = 0
    local friends = 0

    for _, victim in ipairs(victims) do
        local scale = impact and impact(ctx, victim) or 1

        if scale > 0 then
            local weight = hit_dice(ctx, victim) * scale

            if targets.enemy(ctx, caster, victim) then
                foes = foes + weight
            else
                friends = friends + weight
            end
        end
    end

    return foes, friends
end

-- A source tracer fires only when the weighted foe share clears its
-- threshold. Keep the weights available for spells that rank candidate
-- cells, such as Lee's Rapid Deconstruction.
function decision.accept(ctx, caster, victims, foe_ratio, impact)
    local foes, friends = decision.weights(ctx, caster,
        victims, impact)

    return foes > 0 and
        foes * 100 >= foe_ratio * (foes + friends)
end

return decision
