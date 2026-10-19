-- A temporary Chaos web must survive save validation with no vault record.
-- Its held actor and trap share one cell, while authored traps still need
-- their original vault provenance.
local component = require("constants.component")
local harness = require("tests.harness")
local save_traps = require("policy.save.traps")
local sources = require("constants.trap_sources")
local trap_ids = require("ids.traps")

local test = {}
local actor = 11
local trap = 22

-- Exercise the production validator with a minimal ECS-shaped context.
-- No test-only component schema or trap definition is redeclared here.
function test.run()
    local position = {
        level_id = 1,
        x = 4,
        y = 5,
    }
    local ctx = {}

    -- The validator discovers traps, held actors, and marks separately.
    function ctx:query(required)
        if required[1] == component.WORLD_TRAP then
            return { trap }
        end

        if required[1] == component.TRAP_HELD then
            return { actor }
        end

        return {}
    end

    -- Return a matching web and held actor with no authored vault origin.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return position
        end

        if entity == actor and id == component.ACTOR then
            return { kind_id = "MONS_RAT" }
        end

        if entity == actor and id == component.TRAP_HELD then
            return {
                kind_id = trap_ids.TRAP_WEB,
                net_item_id = 0,
            }
        end

        if entity == trap and id == component.WORLD_TRAP then
            return {
                kind_id = trap_ids.TRAP_WEB,
                level_id = 1,
                x = 4,
                y = 5,
                charges = 0,
                revealed = true,
                source_record = sources.CHAOS_ENSNARE,
            }
        end
    end

    -- Stable IDs make any validation error identify the offending entity.
    function ctx:id(entity)
        return entity
    end

    -- The fixture's restrained actor is a monster, not the player.
    function ctx:player()
        return nil
    end

    -- Webs attach to walkable terrain even though they have their own entity.
    function ctx:walkable()
        return true
    end

    -- Floor requires a matching web for any saved web hold.
    function ctx:cell()
        return "DNGN_FLOOR"
    end

    local result = save_traps.validate(ctx, { levels = {} })

    harness.equal(type(result), "table",
        "a matching temporary Chaos web passes restore validation")
end

return test
