-- Source Ensnare replaces a trap already under its victim. That ensures
-- saved held state has a matching web rather than a different trap kind.
local component = require("constants.component")
local harness = require("tests.harness")
local placement = require("policy.traps.placement")
local sources = require("constants.trap_sources")
local traps = require("ids.traps")

local test = {}

-- Fake only entity storage. The production placement policy must destroy
-- the old trap before it writes a temporary web in the same cell.
function test.run()
    local old_trap = 11
    local new_trap = 22
    local destroyed
    local added = {}
    local ctx = {}

    -- Discovery returns the occupied floor cell's previous trap.
    function ctx:query()
        return { old_trap }
    end

    -- The old alarm occupies precisely the cell Ensnare will replace.
    function ctx:get(_, id)
        if id == component.WORLD_TRAP then
            return {
                kind_id = traps.TRAP_ALARM,
                level_id = 1,
                x = 4,
                y = 5,
            }
        end
    end

    -- Record removal so replacement cannot silently leave duplicate traps.
    function ctx:destroy(entity)
        destroyed = entity
    end

    -- Return a distinct ECS handle for the spell-created web.
    function ctx:create()
        return new_trap
    end

    -- Capture both components to check the new web's saved metadata.
    function ctx:add(entity, id, value)
        added[id] = {
            entity = entity,
            value = value,
        }
    end

    placement.temporary_web(ctx, 1, 4, 5)

    harness.equal(destroyed, old_trap,
        "the prior floor trap is replaced as in source DCSS")
    harness.equal(added[component.WORLD_TRAP].entity, new_trap,
        "the new web has its own ECS entity")
    harness.equal(added[component.WORLD_TRAP].value.kind_id,
        traps.TRAP_WEB, "the held actor has a matching web")
    harness.equal(added[component.WORLD_TRAP].value.charges, 0,
        "ordinary web charges satisfy save validation")
    harness.equal(added[component.WORLD_TRAP].value.source_record,
        sources.CHAOS_ENSNARE,
        "the runtime origin remains distinct from vault records")
end

return test
