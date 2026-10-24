-- Xom's demon gifts and hostile visitors are ordinary saved summons. The
-- source choices belong here; placement, allegiance, and expiry belong to
-- the shared ECS summon owner.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local gods = require("constants.gods")
local ids = require("ids.xom_events")
local monsters = require("ids.monsters")
local pool = require("policy.population.pool")
local roster = require("policy.population.roster")
local scenarios = require("constants.scenarios")
local sentinels = require("constants.population_sentinels")
local streams = require("constants.rng_streams")
local summon = require("policy.magic.effects.summons.common")
local factory = require("policy.population.factory")
local tiers = require("data.demon_tiers")

local effect = {}

-- Source first decides lesser versus common by severity, with a rare
-- Chaos Spawn in the common branch. The demon tier table is shared with
-- other summon effects, so monster IDs are declared once.
local function random_demon(ctx, severity, stream)
    local roll = ctx:random(stream, math.max(1, severity * 5))
    local tier = 5

    if roll >= 340 then
        if ctx:random(stream, 10) == 0 then
            return monsters.MONS_CHAOS_SPAWN
        end

        tier = ctx:random(stream, 10) < 6 and 4 or 3
    end

    local choices = tiers[tier]

    return choices[ctx:random(stream, #choices) + 1]
end

-- Source RANDOM_MOBILE_MONSTER draws from the active branch's population,
-- excluding stationary creatures rather than naming a second roster.
local function random_mobile(ctx, player, stream)
    local position = ctx:get(player, component.POSITION)
    local branch = ctx:level_branch(position.level_id)
    local scenario = scenarios.GENERATED_DUNGEON_BASIC
    local allowed = roster.allowed(scenario, branch)

    for kind_id in pairs(allowed) do
        local definition = catalog.get(categories.MONSTERS, kind_id)

        for _, flag in ipairs(definition.flags or {}) do
            if flag == flags.STATIONARY then
                allowed[kind_id] = nil
                break
            end
        end
    end

    local depth = ctx:level_depth(position.level_id)
    local choices = pool.at_depth(branch, depth,
        allowed, scenario)

    -- Ambient generation can choose NO_MONSTER as a deliberate empty
    -- spawn. RANDOM_MOBILE_MONSTER specifically needs a real creature.
    local mobile = {}
    local total = 0

    for _, choice in ipairs(choices) do
        if choice.id ~= sentinels.NO_MONSTER then
            mobile[#mobile + 1] = choice
            total = total + choice.weight
        end
    end

    return pool.pick(ctx, mobile, total, stream)
end

-- All Xom summons record Xom as their god source. A failed adjacent
-- placement simply lets the next attempt try, as in create_monster.
local function place(ctx, player, kind_id, degree, attitude, stream)
    local creature = summon.spawn(ctx, player, gods.XOM,
        kind_id, degree, nil, {
            attitude = attitude,
            source_category = categories.GODS,
            stream = stream,
            silent_failure = true,
            silent_hostility = true,
        })

    if creature then
        local position = ctx:get(player, component.POSITION)
        local depth = ctx:level_depth(position.level_id)

        factory.equip_generated(ctx, creature, kind_id, depth)
    end

    return creature
end

-- Xom's single ally lasts six abjuration degrees, while each member of
-- the larger party lasts three. The latter count is three nested draws
-- capped at sixteen and then at the player's experience level.
local function friendly(ctx, player, severity, stream, single)
    local attempts = 1
    local degree = 6

    if not single then
        attempts = severity

        for _ = 1, 3 do
            attempts = ctx:random(stream, attempts + 1)
        end

        local progress = ctx:get(player, component.PROGRESSION)

        attempts = math.min(attempts + 2, 16,
            progress and progress.level or 1)
        degree = 3
    end

    local first
    local created = 0

    for _ = 1, attempts do
        local kind_id = random_demon(ctx, severity, stream)
        local creature = place(ctx, player, kind_id,
            degree, attitudes.FRIENDLY, stream)

        if creature then
            first = first or creature
            created = created + 1
        end
    end

    if created > 0 then
        ctx:emit(channels.RELIGION,
            single and "Xom sends an ally to your aid!" or
            "Xom sends allies to your aid!")
    end

    return single and first or created
end

-- Bad summoning uses shadow creatures one time in three. Otherwise it
-- uses the same severity-shaped demon count as the good group, with a
-- lower cap unless Xom penance is active.
local function hostile(ctx, player, severity, stream)
    local shadows = ctx:random(stream, 3) == 0
    local attempts

    if shadows then
        attempts = 1 + ctx:random(stream, 4)
    else
        attempts = severity

        for _ = 1, 3 do
            attempts = ctx:random(stream, attempts + 1)
        end

        attempts = math.min(attempts + 1, 14)

        local worship = ctx:get(player, component.RELIGION_WORSHIP)
        local penance = worship and (worship.penance or {})[gods.XOM] or 0

        if penance == 0 then
            local progress = ctx:get(player, component.PROGRESSION)
            local level = progress and progress.level or 1

            attempts = math.min(attempts,
                math.floor(level / 2) + 1)
        end
    end

    local created = 0

    for _ = 1, attempts do
        local kind_id = shadows and
            random_mobile(ctx, player, stream) or
            random_demon(ctx, severity, stream)

        if place(ctx, player, kind_id, 4,
            attitudes.HOSTILE, stream) then
            created = created + 1
        end
    end

    if created > 0 then
        ctx:emit(channels.RELIGION,
            "Xom sends hostile creatures after you!")
    end

    return created
end

-- An unknown Xom summon action is a porting error; its catalog entry
-- must not claim success before its live effect has been implemented.
function effect.apply(ctx, player, event_id, severity, request)
    local stream = request and request.stream or streams.RELIGION

    if event_id == ids.GOOD_SINGLE_ALLY then
        return friendly(ctx, player, severity, stream, true)
    end

    if event_id == ids.GOOD_ALLIES then
        return friendly(ctx, player, severity, stream, false)
    end

    if event_id == ids.BAD_SUMMON_HOSTILES then
        return hostile(ctx, player, severity, stream)
    end

    error("summon effect received another Xom event")
end

return effect
