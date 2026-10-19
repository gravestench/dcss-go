
local component = require("constants.component")
local jobs = require("ids.jobs")
local species = require("ids.species")
local agility = require("policy.character.agility")
local fighter = require("policy.combat.fighter")
local save_status = require("policy.save.status")
local harness = require("tests.harness")

local test = {}

-- Bind agility defense player lookup to this owner while preserving live ECS component reads.
local function player_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })

    -- Bind policy ownership to agility defense fixture actor so player-only branches execute on that entity.
    function proxy.player()
        return player
    end

    return proxy
end

-- Restore rejects a negative Agility duration.
function test.run(ctx)
    local player = ctx:create()
    local battle = player_context(ctx, player)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
        job_id = jobs.JOB_FIGHTER,
        name = "Agility defense test",
    })
    ctx:add(player, component.ATTRIBUTES, {
        strength = 10,
        intelligence = 10,
        dexterity = 10,
    })
    ctx:add(player, component.SKILLS, {
        entries = {},
    })
    ctx:add(player, component.COMBAT, {
        shield_blocks = 0,
    })

    local base = fighter.defense(battle).ev

    agility.apply(battle, player, 20, "mutation")

    harness.equal(fighter.defense(battle).ev, base + 5,
        "Agility grants the source five points of EV")

    agility.tick(battle, player, 350)

    harness.equal(fighter.defense(battle).ev, base,
        "Agility EV expires with the saved duration")

    local corrupt = ctx:get(player, component.AGILITY)
    corrupt.remaining_aut = -1
    ctx:set(player, component.AGILITY, corrupt)

    local accepted = pcall(save_status.run, battle)

    harness.falsy(accepted,
        "restore rejects a negative Agility duration")
end

return test
