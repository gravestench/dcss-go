local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local hex = require("policy.combat.monster_hexes")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")

local test = {}

local caster = 101
local foe = 202
local ally = 303

local function context(wall_x, ally_x)
    local ctx = {}

    function ctx:player()
        return foe
    end

    function ctx:get(entity, id)
        if id == component.ACTOR and entity == caster then
            return {
                kind_id = monsters.MONS_ORC_WIZARD,
            }
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

    function ctx:actor_at(_, x)
        if x == ally_x then
            return ally
        end

        if x == 4 then
            return foe
        end

        return nil
    end

    return ctx
end

function test.run()
    local profile = catalog.get("monster_beams", spells.SPELL_SLOW)
    local clear = hex.plan(context(), caster, foe, profile)

    harness.equal(clear.kind, target_kind.ENTITY,
        "a hex keeps its selected entity target")
    harness.equal(clear.entity, foe,
        "a hex plan retains the selected foe")
    harness.falsy(hex.plan(context(3), caster, foe, profile),
        "a wall blocks a targeted hex")
    harness.falsy(hex.plan(context(nil, 2), caster, foe, profile),
        "an ally blocks a targeted hex")
end

return test
