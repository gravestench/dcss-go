local catalog = require("policy.catalog")
local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")

local hand = {}

-- One positive timer backs both the will and regeneration consumers.
function hand.active(ctx, monster)
    local state = ctx:get(monster, component.MONSTER_TROGS_HAND)

    return state ~= nil and state.remaining_aut > 0
end

-- monster.cc adds 80 willpower before its lowered-will division.
function hand.will_bonus(ctx, monster)
    return hand.active(ctx, monster) and 80 or 0
end

-- mon-cast.cc rolls two HD-scaled dice and caps the invocation at 100 turns.
-- Its duration is independent of the caster's spell_hd enhancements.
function hand.invoke(ctx, monster)
    local actor = ctx:get(monster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local hd = monster_stats.hit_dice(ctx, monster, definition)
    local sides = math.floor(hd * 10 / 3) + 1
    local turns = 5

    for _ = 1, 2 do
        turns = turns + 1 + roll.spell(ctx, sides)
    end

    ctx:add(monster, component.MONSTER_TROGS_HAND, {
        remaining_aut = 10 * math.min(turns, 100),
    })

    ctx:emit("spell", "The " .. display.name(ctx, monster) ..
        " invokes Trog's protection!")
end

-- Age the invocation once per actor action and drop both protections at zero.
function hand.tick(ctx, monster, elapsed_aut)
    local state = ctx:get(monster, component.MONSTER_TROGS_HAND)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(monster, component.MONSTER_TROGS_HAND)
    else
        ctx:set(monster, component.MONSTER_TROGS_HAND, state)
    end
end

return hand
