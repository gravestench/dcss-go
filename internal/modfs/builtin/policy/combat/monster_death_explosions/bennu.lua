-- A Bennu blazes out in a radius-two negative-energy pyre, then rises
-- once in its former cell. The second body's ECS component closes the
-- lifecycle even after a save and restore.
local blast = require("policy.magic.effects.summons.blast")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local factory = require("policy.population.factory")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")
local resistances = require("constants.resistance_ids")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local bennu = {}

-- First resolve the pyre, then place one new actor if the old cell remains
-- open. Other explosive deaths in the same action may occupy it first.
function bennu.on_death(ctx, actor, definition, position)
    if definition.id ~= monsters.MONS_BENNU then
        return false
    end

    if not ctx:has(actor, component.INNER_FLAME) then
        local hd = monster_stats.hit_dice(ctx, actor, definition)
        local sides = 5 + math.floor(hd * 5 / 4)

        blast.area(ctx, actor, 2, 3, sides,
            resistances.NEGATIVE_ENERGY, nil,
            streams.MONSTER_SPELL, position)
        ctx:emit("combat", "The bennu blazes out!")
    end

    local state = ctx:get(actor, component.BENNU_REVIVAL)

    if not state and ctx:walkable(position.level_id,
        position.x, position.y) and
        not ctx:actor_at(position.level_id,
            position.x, position.y) then
        local next_life = factory.spawn(ctx, monsters.MONS_BENNU,
            position.level_id, position.x, position.y, {
                attitude = targets.real_attitude(ctx, actor),
            })

        ctx:add(next_life, component.BENNU_REVIVAL, {
            revives = 1,
        })

        -- The resurrected body is the same Duel opponent. Copy only this
        -- lineage mark, never the old body's inventory or arena position.
        local duel = ctx:get(actor, component.MONSTER_ARENA_DUEL)

        if duel and duel.current then
            ctx:add(next_life, component.MONSTER_ARENA_DUEL, duel)
        end
    end

    return true
end

death_hooks.add("monster.bennu_explosion", bennu.on_death)

return bennu
