-- Killing the marker-bound swineherd opens the pigsty grate. Its saved
-- vault origin remains authoritative if the actor moved before death.
local component = require("constants.component")
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local pigsty = require("policy.combat.monster_death.pan_pigsty")
local names = require("constants.pan_pigsty")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The generation hook must create both marker properties through the
-- ordinary placement path; the death policy reads those saved records.
local function source_markers()
    local random = {}

    function random:random_u64()
        return 0, 1
    end

    local builder = grid.new(random)
    local map = placement.place(nil, builder, vaults.get(names.MAP_ID), {
        branch_id = branches.BRANCH_PANDEMONIUM,
        depth = 1,
        branch_bottom = 1,
        absolute_depth = 24,
    })
    local swineherd = false
    local gate = false

    for _, record in ipairs(map.records) do
        if record.kind == effects.MARKER then
            local arguments = record.arguments or {}

            swineherd = swineherd or
                arguments[names.SWINEHERD_PROPERTY] == names.SWINEHERD_VALUE
            gate = gate or
                arguments[names.GATE_PROPERTY] == names.GATE_VALUE
        end
    end

    harness.truthy(swineherd, "placed swineherd has a saved death marker")
    harness.truthy(gate, "placed grate has a saved gate marker")
end

-- Use the production ECS origin schema and a tiny grid service proxy;
-- tests need no second copy of the monster or marker definitions.
function test.run(ctx)
    source_markers()

    local actor = ctx:create()
    local player = ctx:create()
    local changed
    local message
    local world = setmetatable({}, { __index = ctx })

    ctx:add(actor, component.VAULT_ORIGIN, {
        level_id = 23,
        vault_id = names.MAP_ID,
        record_index = 1,
        occurrence = 1,
        spawn_x = 2,
        spawn_y = 1,
    })
    ctx:add(player, component.POSITION, {
        level_id = 23,
        x = 0,
        y = 0,
    })

    function world:player()
        return player
    end

    function world:marker_property(_, x, y, key)
        if key == names.SWINEHERD_PROPERTY and x == 2 and y == 1 then
            return names.SWINEHERD_VALUE
        end

        if key == names.GATE_PROPERTY and x == 1 and y == 1 then
            return names.GATE_VALUE
        end

        return nil
    end

    function world:level_size()
        return 3, 3
    end

    function world:cell()
        return terrain.DNGN_GRATE
    end

    function world:set_cell(_, x, y, kind)
        changed = { x = x, y = y, kind = kind }
    end

    function world:visible()
        return true
    end

    function world:emit(_, text)
        message = text
    end

    harness.falsy(pigsty.on_death(world, actor),
        "pigsty callback does not consume the corpse")
    harness.equal(changed.kind, terrain.DNGN_FLOOR,
        "swineherd death opens the iron grate")
    harness.equal(changed.x, 1, "source gate x")
    harness.equal(changed.y, 1, "source gate y")
    harness.equal(message, names.VISIBLE_OPEN,
        "visible gate uses the source announcement")
end

return test
