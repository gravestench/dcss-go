local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local component = require("constants.component")
local terrain = require("content.terrain_features")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")

local test = {}

local caster = 101
local foe = 202
local blocker = 303

local function context(wall_x, blocker_x, cloud_ally)
    local ctx = {}

    function ctx:player()
        return foe
    end

    function ctx:get(entity, id)
        if id == component.ACTOR and entity == caster then
            return { kind_id = monsters.MONS_ORC_WIZARD }
        end

        if id == component.POSITION then
            if entity == caster then
                return {
                    level_id = 1,
                    x = 1,
                    y = 1,
                }
            end

            if entity == foe then
                return {
                    level_id = 1,
                    x = 4,
                    y = 1,
                }
            end
        end

        return nil
    end

    function ctx:walkable(_, x)
        return x ~= wall_x
    end

    function ctx:actor_at(_, x, y)
        if cloud_ally and x == 4 and y == 2 then
            return blocker
        end

        if x == blocker_x then
            return blocker
        end

        if x == 4 then
            return foe
        end

        return nil
    end

    function ctx:query()
        return {}
    end

    function ctx:visible()
        return true
    end

    function ctx:cell()
        return terrain.vault_terrain.DNGN_FLOOR
    end

    return ctx
end

function test.run()
    local dart = catalog.get("monster_beams", spells.SPELL_MAGIC_DART)
    local lightning = catalog.get("monster_beams",
        spells.SPELL_LIGHTNING_BOLT)
    local clear = beam.plan(context(), caster, foe, dart)

    harness.equal(clear.kind, target_kind.ENTITY,
        "Magic Dart plans an actor target")
    harness.equal(clear.entity, foe, "Magic Dart retains its foe")
    harness.equal(clear.dx, 3, "beam direction points toward the foe")
    harness.equal(clear.dy, 0, "horizontal beam has zero y direction")

    harness.falsy(beam.plan(context(3), caster, foe, dart),
        "a wall before the foe blocks Magic Dart")
    harness.falsy(beam.plan(context(nil, 2), caster, foe, dart),
        "an allied monster in the shot blocks Magic Dart")
    harness.falsy(beam.plan(context(nil, 5), caster, foe, lightning),
        "Lightning Bolt avoids an ally behind its first target")
    local stone = catalog.get("monster_beams", spells.SPELL_STONE_ARROW)

    harness.falsy(beam.plan(context(nil, 5), caster, foe, stone),
        "Stone Arrow avoids an ally behind a foe it could miss")

    local freezing = catalog.get("monster_beams",
        spells.SPELL_FREEZING_CLOUD)
    local cloud_plan = beam.plan(context(), caster, foe, freezing)

    harness.equal(cloud_plan.kind, target_kind.CELL,
        "Freezing Cloud plans a level cell")
    harness.equal(cloud_plan.level_id, 1,
        "the cloud cell stays on the caster's level")
    harness.equal(cloud_plan.x, 4,
        "the cloud cell uses the selected foe's x coordinate")
    harness.equal(cloud_plan.y, 1,
        "the cloud cell uses the selected foe's y coordinate")
    harness.truthy(beam.plan(context(nil, 8), caster, foe, freezing),
        "Freezing Cloud stops at its selected cell")
    harness.falsy(beam.plan(context(nil, nil, true), caster, foe,
        freezing), "Freezing Cloud avoids an ally in its possible area")

    local fireball = catalog.get("monster_beams", spells.SPELL_FIREBALL)
    local blast_plan = beam.plan(context(), caster, foe, fireball)

    harness.equal(blast_plan.kind, target_kind.CELL,
        "Fireball plans a blast cell")
    harness.falsy(beam.plan(context(nil, nil, true), caster, foe,
        fireball), "Fireball avoids an ally in its blast radius")
end

return test
