-- Injury Bond routes half of an ally's ordinary incoming damage to a live
-- protector before the ally loses HP. The bond's handle survives saves.
-- Source: monster.cc:monster::hurt and mon-ench.cc:ENCH_INJURY_BOND.
local causes = require("constants.damage_causes")
local component = require("constants.component")
local targets = require("policy.ai.targets")

local bond = {}

-- The bond ends if its protector dies, changes side, or stops existing.
-- A saved handle alone cannot prove that redirected damage is safe.
local function protector(ctx, monster, state)
    local owner = state.protector
    local health = owner and ctx:get(owner, component.HEALTH)

    if not owner or owner == monster or not health or
        health.current <= 0 or
        not ctx:has(owner, component.ACTOR) or
        not targets.aligned(ctx, owner, monster) then
        return nil
    end

    return owner
end

-- Grant only an absent bond; source selection avoids replacing another
-- protector while that first protector is still accepting injuries.
function bond.grant(ctx, monster, owner, duration_aut)
    if ctx:has(monster, component.MONSTER_INJURY_BOND) or
        duration_aut <= 0 then
        return false
    end

    ctx:add(monster, component.MONSTER_INJURY_BOND, {
        protector = owner,
        remaining_aut = duration_aut,
    })

    return true
end

-- Only a living allied protector receives the source's floor(half) split.
-- Redirected damage bypasses another split to prevent recursive bonds.
function bond.split(ctx, monster, amount, cause)
    local state = ctx:get(monster, component.MONSTER_INJURY_BOND)

    if not state or state.remaining_aut <= 0 or amount <= 1 or
        cause == causes.INJURY_BOND then
        return amount, nil, 0
    end

    local owner = protector(ctx, monster, state)

    if not owner then
        return amount, nil, 0
    end

    local shared = math.floor(amount / 2)

    return amount - shared, owner, shared
end

-- Age the recipient's saved timer on its own action. A dead protector
-- cancels immediately even if duration remains.
function bond.tick(ctx, monster, elapsed_aut)
    local state = ctx:get(monster, component.MONSTER_INJURY_BOND)

    if not state then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 or not protector(ctx, monster, state) then
        ctx:remove(monster, component.MONSTER_INJURY_BOND)
    else
        ctx:set(monster, component.MONSTER_INJURY_BOND, state)
    end
end

return bond
