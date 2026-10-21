-- Theory of operation: taking the Orb changes the player's saved chapter.
-- Every crossed five-turn boundary then checks the source 5-in-18 wandering
-- chance. A successful check chooses a close defender and creates one normal
-- hostile ECS actor. The phase and RNG stream survive save/restore; there is
-- no private timer to reset when the player changes floors.
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local branches = require("ids.branches")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local endgame = require("policy.character.endgame")
local factory = require("policy.population.factory")
local habitat = require("policy.combat.monster_habitat")
local history = require("policy.population.unique_history")
local monsters = require("ids.monsters")
local phases = require("constants.endgame")
local rune_ids = require("constants.runes")
local runes = require("policy.character.runes")
local streams = require("constants.rng_streams")
local tiers = require("data.demon_tiers")

local run = {}

local CHECK_AUT = 50
local NORMAL_RATE = 18
local CLOSE_RADIUS = 7

local pan_lords = {
    { rune = rune_ids.GLOWING, monster = monsters.MONS_MNOLEG },
    { rune = rune_ids.DARK, monster = monsters.MONS_GLOORX_VLOQ },
    { rune = rune_ids.FIERY, monster = monsters.MONS_CEREBOV },
    { rune = rune_ids.MAGICAL, monster = monsters.MONS_LOM_LOBON },
}

-- Absolute aut makes a save between two checks resume at the next source
-- boundary. An action crossing several boundaries performs each check.
function run.boundaries(start_aut, elapsed_aut)
    if elapsed_aut < 0 then
        error("Orb-run elapsed aut cannot be negative")
    end

    return math.floor((start_aut + elapsed_aut) / CHECK_AUT) -
        math.floor(start_aut / CHECK_AUT)
end

-- Pick uniformly within the committed source demon tier. This uses the
-- same imported tier list as summons, but the Orb-run RNG stream.
local function tier(ctx, number)
    local choices = tiers[number]

    if not choices or #choices == 0 then
        error("Orb run has no demon tier " .. tostring(number))
    end

    return choices[ctx:random(streams.ORB_RUN, #choices) + 1]
end

-- `pick_monster_no_rarity(Pan)` indexes the source population rows rather
-- than using rarity. Its draw happens before weighted category selection in
-- C++ because function arguments are evaluated before the call.
local function pan_monster(ctx)
    local rows = {}

    for _, definition in ipairs(catalog.all(categories.POPULATIONS)) do
        if definition.branch_id == branches.BRANCH_PANDEMONIUM then
            for _, row in ipairs(definition.rows) do
                rows[#rows + 1] = row.monster_id
            end
        end
    end

    if #rows == 0 then
        error("Orb run has no Pandemonium population")
    end

    return rows[ctx:random(streams.ORB_RUN, #rows) + 1]
end

-- The rare branch can recall a named Pan lord whose rune was stolen, Boris
-- after his first death, or a seraph. Each conditional one-in-ten check is
-- drawn in source order, even when an earlier unique is unavailable.
local function rare_defender(ctx)
    local player = ctx:player()

    for _, entry in ipairs(pan_lords) do
        if runes.has(ctx, player, entry.rune) and
            not history.seen(ctx, entry.monster) and
            ctx:random(streams.ORB_RUN, 10) == 0 then
            return entry.monster
        end
    end

    if history.boris_killed(ctx) and
        not history.seen(ctx, monsters.MONS_BORIS) and
        ctx:random(streams.ORB_RUN, 10) == 0 then
        return monsters.MONS_BORIS
    end

    if ctx:random(streams.ORB_RUN, 10) == 0 then
        return monsters.MONS_SERAPH
    end

    return monsters.MONS_PANDEMONIUM_LORD
end

-- The source first gives the rare group a one-in-ten chance. Outside that
-- group, 15/90 are guardians, 25/90 greater demons, 10/90 common demons,
-- and 40/90 a uniformly drawn Pan population row.
function run.pick_defender(ctx)
    if ctx:random(streams.ORB_RUN, 10) == 0 then
        return rare_defender(ctx)
    end

    local pan = pan_monster(ctx)
    local category = ctx:random(streams.ORB_RUN, 90)

    if category < 15 then
        return monsters.MONS_ORB_GUARDIAN
    end

    if category < 40 then
        local number = ctx:random(streams.ORB_RUN, 10) < 6 and 2 or 1

        return tier(ctx, number)
    end

    if category < 50 then
        local number = ctx:random(streams.ORB_RUN, 10) < 6 and 4 or 3

        return tier(ctx, number)
    end

    return pan
end

-- Row-major candidate collection removes file order and Lua table order
-- from the spawn draw. Source PROX_CLOSE_TO_PLAYER means within LOS radius;
-- the chosen monster still needs compatible terrain and an empty cell.
local function close_cells(ctx, position, kind_id)
    local width, height = ctx:level_size(position.level_id)
    local cells = {}

    for y = math.max(0, position.y - CLOSE_RADIUS),
        math.min(height - 1, position.y + CLOSE_RADIUS) do
        for x = math.max(0, position.x - CLOSE_RADIUS),
            math.min(width - 1, position.x + CLOSE_RADIUS) do
            local distance = math.max(math.abs(x - position.x),
                math.abs(y - position.y))

            if distance > 0 and distance <= CLOSE_RADIUS and
                not ctx:actor_at(position.level_id, x, y) and
                habitat.kind_at(ctx, kind_id,
                    position.level_id, x, y) then
                cells[#cells + 1] = {
                    x = x,
                    y = y,
                }
            end
        end
    end

    return cells
end

-- A failed placement consumes the defender draw but cannot fabricate an
-- actor on occupied terrain. Successful spawns use ordinary AI and saves.
local function spawn(ctx, position)
    local kind_id = run.pick_defender(ctx)
    local cells = close_cells(ctx, position, kind_id)

    if #cells == 0 then
        return nil
    end

    local cell = cells[ctx:random(streams.ORB_RUN, #cells) + 1]
    local actor = factory.spawn(ctx, kind_id,
        position.level_id, cell.x, cell.y, {
            attitude = attitudes.HOSTILE,
            generate_awake = true,
        })
    local ai = ctx:get(actor, component.AI)

    if ai then
        ai.behavior = behaviors.SEEK
        ai.target_x = position.x
        ai.target_y = position.y
        ai.memory_until_aut = ctx:aut() + 50
        ctx:set(actor, component.AI, ai)
    end

    return actor
end

-- Only the player action moves the Orb-run clock. Abyss suspension mirrors
-- source mercy: the escaping chapter persists there, but these spawns do not.
function run.update(ctx, actor, elapsed_aut)
    if actor ~= ctx:player() or
        endgame.phase(ctx, actor) ~= phases.ESCAPING then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if not position or
        ctx:level_branch(position.level_id) == branches.BRANCH_ABYSS then
        return
    end

    for _ = 1, run.boundaries(ctx:aut(), elapsed_aut) do
        if ctx:random(streams.ORB_RUN, NORMAL_RATE) < 5 then
            spawn(ctx, position)
        end
    end
end

return run
