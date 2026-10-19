-- Resonance Strike draws more earth power from nonliving creatures on the
-- caster's side adjacent to its foe. Other creatures give no bonus die.
local catalog = require("policy.catalog")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local holiness = require("constants.monster_holiness")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
local spells = require("ids.spells")
local targets = require("policy.ai.targets")

local effect = {}

-- Use the catalog's holiness instead of guessing constructs from names.
local function nonliving(definition)
    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.NONLIVING then
            return true
        end
    end

    return false
end

-- Only aligned, nonliving actors next to the victim power the strike.
local function nearby_constructs(ctx, caster, position)
    local count = 0

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local actor = ctx:actor_at(position.level_id,
                    position.x + dx, position.y + dy)

                if actor and targets.aligned(ctx, caster, actor) then
                    local state = ctx:get(actor, component.ACTOR)
                    local definition = state and
                        catalog.get("monsters", state.kind_id)

                    if definition and nonliving(definition) then
                        count = count + 1
                    end
                end
            end
        end
    end

    return count
end

-- Earth power reaches a visible foe without a projectile ray.
function effect.plan(ctx, caster, foe)
    return direct.plan(ctx, caster, foe, spells.SPELL_RESONANCE_STRIKE)
end

-- Source mon-cast.cc rolls 3d(spell HD) plus one die per two allied
-- constructs, stochastically rounding an odd count before rolling.
-- Example: two nearby allied golems add one die.
function effect.resolve(ctx, caster, foe, _, plan)
    local position = direct.require(ctx, caster, foe, plan)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local constructs = nearby_constructs(ctx, caster, position)
    local dice = 3 + roll.random_divide(ctx, constructs, 2,
        "monster_spell")
    local raw = 0

    for _ = 1, dice do
        raw = raw + 1 + roll.spell(ctx, hd)
    end

    direct.damage(ctx, caster, foe, direct.armour(ctx, foe, raw))
    ctx:emit("spell", "A blast of power from the earth strikes the target!")
end

return effect
