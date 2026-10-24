-- Duel challenges one source-worthy opponent to a temporary Arena. Free
-- target rejection and paid illusion revelation share this eligibility rule.
local abilities = require("ids.abilities")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local eligibility = require("policy.world.arena.eligibility")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")
local domains = require("constants.portal_domains")
local branches = require("ids.branches")
local levels = require("policy.generation.branch_levels")
local intent_ids = require("constants.intent")
local okawaru = require("constants.okawaru")

local duel = {}

-- A worshipper needs five stars and no penance to offer this challenge.
function duel.available(ctx, player)
    return costs.available(ctx, player, gods.OKAWARU,
        okawaru.DUEL_RANK) and
        not ctx:has(player, component.PLAYER_ARENA_VISIT)
end

-- Targeting and MP rejection are free; the source charges only after the
-- user has chosen an eligible visible opponent.
function duel.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, okawaru.DUEL_MP) then
        return "You do not have enough magic."
    end

    local target, rejection, illusion = eligibility.target(ctx, player,
        input.dx or 0, input.dy or 0)

    if rejection then
        return rejection
    end

    local failed = costs.failed(ctx, player, okawaru.DUEL_FAIL_BASE,
        okawaru.DUEL_FAIL_SCALE, okawaru.DUEL_FAIL_PIETY)

    if failed or illusion then
        return {
            intent = {
                kind = intent_ids.PLAYER_ABILITY,
                ability_id = abilities.OKAWARU_DUEL,
                target_id = failed and "failed" or "illusion",
            },
            cost = 10,
        }
    end

    local origin = ctx:get(player, component.POSITION)
    local identity = ctx:get(player, component.PLAYER)

    return {
        portal = {
            domain = domains.LUA,
            operation = "enter",
            source = {
                level_id = origin.level_id,
                x = origin.x,
                y = origin.y,
            },
            generate_policy = "world.generate_arena_level",
            generation_input = {
                species_id = identity.species_id,
                player_name = identity.name,
            },
            commit_policy = "world.arena.commit_travel",
            expected_branch_id = branches.BRANCH_ARENA,
            expected_level_id = levels.id(branches.BRANCH_ARENA, 1),
            payload = {
                target_id = tostring(ctx:id(target)),
            },
        },
        cost = 10,
    }
end

-- Failed invocations and eligible illusions spend the prepared action.
-- Real target movement belongs to the staged portal's commit callback.
function duel.resolve(ctx, player, intent)
    if intent.target_id == "failed" then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    if intent.target_id == "illusion" then
        ctx:emit("religion",
            "You challenge your foe to single combat, " ..
            "but it is merely a clone!")
        costs.spend(ctx, player, okawaru.DUEL_MP,
            costs.piety_cost(ctx, okawaru.DUEL_PIETY))

        return
    end

    error("Duel has no prepared challenge outcome")
end

-- The target cursor uses the player's current sight rather than fixed
-- seven-cell reach when Nightstalker or a mod changes visibility.
local function visible_range(_, ctx, player)
    return require("policy.character.vision").radius(ctx, player)
end

registry.add(abilities.OKAWARU_DUEL, {
    name = "Duel",
    available = duel.available,
    range = visible_range,
    prepare = duel.prepare,
    resolve = duel.resolve,
})

return duel
