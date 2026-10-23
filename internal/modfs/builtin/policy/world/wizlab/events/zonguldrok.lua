-- Theory of operation: each live G grave can wake once. A saved M clock
-- visits remaining graves, escalating the undead roster as more wake.
-- Killed grave actors contribute to a separate D door threshold, while
-- entering an L cell awakens the named lich exactly once. The terrain
-- grid owns opened graves and door; Akara owns all counters and flags.
local channels = require("constants.message_channels")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local factory = require("policy.population.factory")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local terrain = require("constants.terrain")
local wizlab = require("constants.wizlab")

local zonguldrok = {}

-- Source wave selection uses counts of prior spawned actors, not the
-- number of elapsed callbacks. The base species carries zombie HD.
local function next_undead(ctx, state)
    local random = function(limit)
        return ctx:random(streams.WIZLAB_EVENTS, limit)
    end

    if state.count < 9 or
        (state.count < 18 and random(5) == 0) then
        if random(2) == 0 then
            return monsters.MONS_ZOMBIE, {
                base_id = monsters.MONS_OGRE,
            }
        end

        return monsters.MONS_WIGHT, {}
    end

    if state.count < 21 or
        (state.count < 26 and random(4) == 0) then
        if state.vampire_count > 3 or random(2) == 0 then
            return monsters.MONS_ZOMBIE, {
                base_id = monsters.MONS_TROLL,
            }
        end

        state.vampire_count = state.vampire_count + 1

        return monsters.MONS_VAMPIRE, {}
    end

    if state.count < 28 or state.champion_count > 1 or
        random(7) < 6 then
        if state.warrior_count > 5 or random(2) == 0 then
            return monsters.MONS_ZOMBIE, {
                base_id = monsters.MONS_TWO_HEADED_OGRE,
            }
        end

        state.warrior_count = state.warrior_count + 1

        return monsters.MONS_SKELETAL_WARRIOR, {}
    end

    state.champion_count = state.champion_count + 1

    return monsters.MONS_ANCIENT_CHAMPION, {}
end

-- Revealing a grave changes its cell to floor before placing its awake
-- undead. A blocked grave remains armed for a later clock callback.
local function wake_grave(ctx, state, index)
    local x = state.grave_x[index]
    local y = state.grave_y[index]

    if ctx:actor_at(state.level_id, x, y) then
        return false
    end

    local kind, options = next_undead(ctx, state)

    ctx:set_cell(state.level_id, x, y, terrain.DNGN_FLOOR)
    options.generate_awake = true

    local actor = factory.spawn(ctx, kind, state.level_id, x, y,
        options)

    ctx:add(actor, component.WORLD_WIZLAB_EVENT_ACTOR, {
        level_id = state.level_id,
        vault_id = state.vault_id,
        source_index = state.grave_indices[index],
        kind = wizlab.EVENT_ACTOR_ZONGULDROK,
    })

    state.grave_active[index] = false
    state.count = state.count + 1

    return true
end

-- The first source chance is specific to visible graves. Every grave
-- also gets the one-in-eight fallback, even if the visible draw fails.
local function grave_wave(ctx, state, position)
    local changed = false

    for index, active in ipairs(state.grave_active) do
        if active then
            local x = state.grave_x[index]
            local y = state.grave_y[index]
            local visible = ctx:visible(state.level_id,
                position.x, position.y, 7, x, y)
            local first = visible and
                ctx:random(streams.WIZLAB_EVENTS,
                    wizlab.ZONG_VISIBLE_CHANCE) == 0
            local second = not first and
                ctx:random(streams.WIZLAB_EVENTS,
                    wizlab.ZONG_OTHER_CHANCE) == 0

            if (first or second) and
                wake_grave(ctx, state, index) then
                changed = true
            end
        end
    end

    return changed
end

-- L cells are a synchronized trigger: any one may awaken the lich, and
-- only a successful spawn consumes the shared one-shot flag.
local function awaken_lich(ctx, state, position)
    if state.awoke then
        return false
    end

    local stepped = false

    for index, x in ipairs(state.awaken_x) do
        if x == position.x and state.awaken_y[index] == position.y then
            stepped = true
            break
        end
    end

    if not stepped or
        ctx:actor_at(state.level_id,
            state.wizard_x, state.wizard_y) then
        return false
    end

    ctx:set_cell(state.level_id, state.wizard_x,
        state.wizard_y, terrain.DNGN_FLOOR)

    local lich = factory.spawn(ctx, monsters.MONS_ANCIENT_LICH,
        state.level_id, state.wizard_x, state.wizard_y, {
            generate_awake = true,
            colour = "brown",
            custom_name = "antique lich",
            name_descriptor = true,
            tile = "mons_zonguldrok_lich",
        })

    if not lich then
        return false
    end

    ctx:add(lich, component.WORLD_WIZLAB_EVENT_ACTOR, {
        level_id = state.level_id,
        vault_id = state.vault_id,
        source_index = state.wizard_index,
        kind = wizlab.EVENT_ACTOR_ZONGULDROK_LICH,
    })
    state.awoke = true

    return true
end

-- Only the player's actions on this floor advance M. Long actions can
-- cross multiple deadlines without losing a wave or a random draw.
function zonguldrok.tick(ctx, state, position, elapsed_aut, moved)
    if state.level_id ~= position.level_id then
        return false
    end

    local changed = moved and awaken_lich(ctx, state, position)
        or false
    local now = ctx:aut() + elapsed_aut

    while now >= state.next_aut do
        changed = grave_wave(ctx, state, position) or changed
        state.next_aut = state.next_aut + 10 *
            (wizlab.ZONG_DELAY_MIN_TURNS +
                ctx:random(streams.WIZLAB_EVENTS,
                    wizlab.ZONG_DELAY_RANGE_TURNS))
        changed = true
    end

    return changed
end

-- The D callback counts only actors awakened from G graves. Its source
-- threshold opens the authored wall once enough graves are gone.
function zonguldrok.monster_died(ctx, actor, _, position)
    local origin = ctx:get(actor,
        component.WORLD_WIZLAB_EVENT_ACTOR)

    if not origin or origin.kind ~=
        wizlab.EVENT_ACTOR_ZONGULDROK then
        return false
    end

    for _, entity in ipairs(ctx:query({
        component.WORLD_WIZLAB_ZONGULDROK,
    })) do
        local state = ctx:get(entity,
            component.WORLD_WIZLAB_ZONGULDROK)

        if state.level_id == position.level_id then
            state.killed = state.killed + 1

            local remaining = #state.grave_active -
                state.count

            if not state.door_appeared and
                remaining * 2 < state.killed * 3 and
                remaining < 10 then
                ctx:set_cell(state.level_id,
                    state.door_x, state.door_y,
                    terrain.DNGN_CLOSED_DOOR)
                state.door_appeared = true

                local player = ctx:get(ctx:player(),
                    component.POSITION)
                local visible = player and
                    player.level_id == state.level_id and
                    ctx:visible(state.level_id, player.x,
                        player.y, 7, state.door_x, state.door_y)

                if visible then
                    ctx:emit(channels.VAULT,
                        "A door appears!")
                else
                    ctx:emit(channels.VAULT,
                        "The walls vibrate.")
                end
            end

            ctx:set(entity,
                component.WORLD_WIZLAB_ZONGULDROK,
                state)
        end
    end

    return false
end

death_hooks.add("wizlab.zonguldrok_graves",
    zonguldrok.monster_died)

return zonguldrok
