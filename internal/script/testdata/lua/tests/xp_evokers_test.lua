-- XP evoker debt belongs to the player, so duplicate items cannot make
-- their own charges. These checks exercise the production rule owner.
local component = require("constants.component")
local evokers = require("policy.inventory.evokers")
local harness = require("tests.harness")
local items = require("ids.items")
local species = require("ids.species")

local test = {}

-- The runtime returns fresh Lua tables for component reads. Copying here
-- catches policies that mutate a stale read without staging ctx:set first.
local function copy_state(value)
    if not value then
        return nil
    end

    local copy = { debt = {} }

    for kind_id, debt in pairs(value.debt or {}) do
        copy.debt[kind_id] = debt
    end

    return copy
end

-- Supply the real player fields read by XP scaling and a pair of carried
-- rods. The second rod must observe the first rod's spent charge.
local function context()
    local player = {}
    local rods = { {}, {} }
    local state = nil
    local messages = {}
    local ctx = {}

    function ctx:get(entity, id)
        if entity == player then
            if id == component.XP_EVOKERS then
                return copy_state(state)
            elseif id == component.PROGRESSION then
                return { level = 1 }
            elseif id == component.PLAYER then
                return { species_id = species.SP_HUMAN }
            elseif id == component.SKILLS then
                return { entries = {} }
            end
        end

        for _, rod in ipairs(rods) do
            if entity == rod then
                if id == component.ITEM then
                    return { kind_id = items.MISC_LIGHTNING_ROD }
                elseif id == component.CARRIED_BY then
                    return { holder = player }
                end
            end
        end
    end

    function ctx:has(entity, id)
        return entity == player and id == component.XP_EVOKERS and
            state ~= nil
    end

    function ctx:add(entity, id, value)
        harness.equal(entity, player)
        harness.equal(id, component.XP_EVOKERS)
        state = copy_state(value)
    end

    function ctx:set(entity, id, value)
        harness.equal(entity, player)
        harness.equal(id, component.XP_EVOKERS)
        state = copy_state(value)
    end

    function ctx:query(required)
        if required[1] == component.XP_EVOKERS then
            return state and { player } or {}
        end

        return rods
    end

    function ctx:random(_, bound)
        harness.truthy(bound > 0)

        return 0
    end

    function ctx:emit(_, message)
        messages[#messages + 1] = message
    end

    return ctx, player, rods, function()
        return state, messages
    end, function(next_state)
        state = next_state
    end
end

-- Check every source subtype, shared debt, and credited XP recovery.
function test.run()
    local expectations = {
        { items.MISC_PHIAL_OF_FLOODS, 10, 1 },
        { items.MISC_HORN_OF_GERYON, 10, 1 },
        { items.MISC_LIGHTNING_ROD, 3, 4 },
        { items.MISC_TIN_OF_TREMORSTONES, 10, 2 },
        { items.MISC_PHANTOM_MIRROR, 10, 1 },
        { items.MISC_BOX_OF_BEASTS, 10, 1 },
        { items.MISC_CONDENSER_VANE, 10, 1 },
        { items.MISC_XOMS_CHESSBOARD, 2, 15 },
    }

    for _, row in ipairs(expectations) do
        local rule = evokers.definition(row[1])

        harness.equal(rule.charge_debt, row[2])
        harness.equal(rule.max_charges, row[3])
    end

    local ctx, player, rods, result, set_state = context()
    local rod = items.MISC_LIGHTNING_ROD

    harness.equal(evokers.charges(ctx, player, rod), 4)
    evokers.expend(ctx, player, rod)
    harness.equal(evokers.charges(ctx, player, rod), 3)
    harness.equal(ctx:get(rods[2], component.ITEM).kind_id, rod)
    harness.equal(evokers.charges(ctx, player, rod), 3)

    local state = result()

    harness.equal(state.debt[rod], 3)

    -- At XL1 and zero skill the factor is 11 XP per unit of debt.
    evokers.award_xp(ctx, player, 11)
    harness.equal(evokers.charges(ctx, player, rod), 3)
    evokers.award_xp(ctx, player, 22)
    harness.equal(evokers.charges(ctx, player, rod), 4)

    local messages

    state, messages = result()
    harness.equal(state.debt[rod], 0)
    harness.equal(#messages, 1, "recovered charge announces itself")

    -- Debt is retained while the subtype is absent, and save validation
    -- rejects values that could invent charges on a later pickup.
    evokers.expend(ctx, player, rod)
    table.remove(rods)
    table.remove(rods)
    evokers.award_xp(ctx, player, 100000)
    harness.equal(evokers.charges(ctx, player, rod), 3)

    set_state({ debt = { [rod] = -1 } })
    local valid = pcall(evokers.validate, ctx, player)
    harness.equal(valid, false)
end

return test
