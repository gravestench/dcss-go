-- Airstrike bypasses projectiles but rewards open air around the victim.
-- Occupied or solid adjacent cells give no damage bonus.
local catalog = require("policy.catalog")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
local spells = require("ids.spells")
local senses = require("policy.character.senses")

local effect = {}

-- Count source adjacent empty cells, excluding the victim's own square.
local function empty_air(ctx, position)
    local count = 0

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy

                local occupant = ctx:actor_at(position.level_id, x, y)

                -- Source monster_at excludes the player. A player beside
                -- a monster target does not displace that square's air.
                if ctx:walkable(position.level_id, x, y) and
                    (not occupant or
                        ctx:has(occupant, component.PLAYER)) then
                    count = count + 1
                end
            end
        end
    end

    return count
end

-- Airstrike reaches a visible foe through intervening actors.
function effect.plan(ctx, caster, foe)
    return direct.plan(ctx, caster, foe, spells.SPELL_AIRSTRIKE)
end

-- Source mon-cast.cc uses 12 power per spell HD and two averaged random
-- draws; the air component has no resistance, then ordinary AC applies.
-- Example: open air contributes two damage per empty neighbour.
function effect.resolve(ctx, caster, foe, _, plan)
    local position = direct.require(ctx, caster, foe, plan)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local sides = 2 + roll.random_divide(ctx, hd * 12, 7,
        "monster_spell")
    local raw = empty_air(ctx, position) * 2 +
        roll.average_two(ctx, "monster_spell", sides)

    direct.damage(ctx, caster, foe, direct.armour(ctx, foe, raw))

    -- The hit belongs to the foe even when the caster acts out of view.
    if ctx:has(foe, component.PLAYER) or
        senses.player_sees_actor(ctx, foe) then
        ctx:emit("spell", "The air twists around and strikes the target!")
    end
end

return effect
