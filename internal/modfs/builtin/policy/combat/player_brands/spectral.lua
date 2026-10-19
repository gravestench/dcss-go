local categories = require("constants.catalog")
local component = require("constants.component")
local monsters = require("ids.monsters")
local summons = require("policy.magic.effects.summons.common")

local brand = {}

local offsets = {
    {
        x = -1,
        y = -1,
    },

    {
        x = 0,
        y = -1,
    },

    {
        x = 1,
        y = -1,
    },

    {
        x = -1,
        y = 0,
    },

    {
        x = 1,
        y = 0,
    },

    {
        x = -1,
        y = 1,
    },

    {
        x = 0,
        y = 1,
    },

    {
        x = 1,
        y = 1,
    },
}

-- A spectral ally can strike across diagonal neighboring cells on the same level.
local function adjacent(left, right)
    return left.level_id == right.level_id and
        math.max(math.abs(left.x - right.x),
            math.abs(left.y - right.y)) <= 1
end

-- Reuse only the spectral ally owned by this attacker, not another player's
-- or monster's identical weapon summon.
local function existing(ctx, owner)
    for _, entity in ipairs(ctx:query({ component.SPECTRAL_WEAPON })) do
        local summon = ctx:get(entity, component.SUMMON)

        if summon and summon.owner == owner then
            return entity, ctx:get(entity, component.SPECTRAL_WEAPON)
        end
    end

    return nil, nil
end

-- Mark this aut as used so the ally cannot attack twice from one player swing.
local function mark(ctx, actor, state)
    state.triggered_aut = ctx:aut()
    ctx:set(actor, component.SPECTRAL_WEAPON, state)
end

-- Choose equally among cells that border both owner and target for a newly spawned ally.
local function adjacent_cell(ctx, origin, target)
    local seen = 0
    local selected

    -- Source: fineff.cc uses reservoir sampling among cells
    -- adjacent to the player that can also reach the defender.
    for _, offset in ipairs(offsets) do
        local x = origin.x + offset.x
        local y = origin.y + offset.y
        local place = {
            level_id = origin.level_id,
            x = x,
            y = y,
        }

        if adjacent(place, target) and
            ctx:walkable(origin.level_id, x, y) and
            not ctx:actor_at(origin.level_id, x, y) then
            seen = seen + 1

            if ctx:random("melee", seen) == 0 then
                selected = place
            end
        end
    end

    return selected
end

-- The ally equips a copy of the struck weapon's current item state so later
-- melee uses its kind, plus, charges, and ego.
local function copy_weapon(ctx, owner, ally)
    local source = ctx:get(owner, component.ITEM)

    if not source then
        error("spectral source weapon disappeared")
    end

    local copy = ctx:create()

    ctx:add(copy, component.ITEM, {
        kind_id = source.kind_id,
        quantity = 1,
        plus = source.plus,
        charges = source.charges,
        ego = source.ego,
    })
    ctx:add(copy, component.CARRIED_BY, { holder = ally })
    ctx:add(copy, component.EQUIPPED, { slot = "weapon" })
end

-- Reuse monster melee resolution so the spectral follow-up honors the defender's normal defenses.
local function strike(ctx, ally, defender)
    require("policy.combat.melee_actions").monster_target(ctx,
        ally, defender)
end

-- Example: brand.apply() with Spectral Weapon brand -> no contact effect; follow-up runs after attack
-- Spectral Weapon acts after the full swing, so the contact hook is intentionally empty.
function brand.apply()
end

-- An adjacent existing spectral weapon attacks immediately; otherwise find a
-- shared-adjacent cell, spawn a replacement, and expire the old ally.
function brand.after_attack(ctx, hit)
    if hit.health.current <= 0 or not hit.weapon_entity then
        return
    end

    local owner = hit.attacker
    local target = ctx:get(hit.defender, component.POSITION)
    local old, state = existing(ctx, owner)

    if old then
        mark(ctx, old, state)

        local old_position = ctx:get(old, component.POSITION)

        if state.source_weapon == hit.weapon_entity and
            old_position and adjacent(old_position, target) then
            strike(ctx, old, hit.defender)

            return
        end
    end

    local origin = ctx:get(owner, component.POSITION)
    local place = adjacent_cell(ctx, origin, target)

    if not place then
        return
    end

    local ally = summons.spawn(ctx, owner, hit.weapon_id,
        monsters.MONS_SPECTRAL_WEAPON, 1, 2, {
            anchor = origin,
            exact = place,
            source_category = categories.ITEMS,
            passive = true,
        })

    if not ally then
        return
    end

    ctx:add(ally, component.SPECTRAL_WEAPON, {
        source_weapon = hit.weapon_entity,
        triggered_aut = ctx:aut(),
    })
    copy_weapon(ctx, hit.weapon_entity, ally)

    if old then
        summons.expire(ctx, old)
    end

    strike(ctx, ally, hit.defender)
end

return brand
