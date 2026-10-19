-- These fixtures drive the production cry effects and saved boon owner with
-- an explicit game context, so no test-only spell schema is duplicated.
local component = require("constants.component")
local attitudes = require("constants.attitude")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local terrain = require("constants.terrain")

local test = {}
local caster = 101
local foe = 202
local ally = 303
local listener = 404

-- Put one same-genus ally beside the source cry and another monster within
-- hearing range. Deterministic draws give a 12-turn boon at speed ten.
local function context()
    local values = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ORC_KNIGHT,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 1,
                y = 1,
            },
            [component.HEALTH] = {
                current = 40,
                max = 40,
            },
        },
        [foe] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GOBLIN,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 5,
                y = 1,
            },
            [component.HEALTH] = {
                current = 20,
                max = 20,
            },
            [component.SUMMON] = {
                attitude = attitudes.FRIENDLY,
            },
        },
        [ally] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_ORC_WARRIOR,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 1,
            },
            [component.HEALTH] = {
                current = 30,
                max = 30,
            },
        },
        [listener] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_GOBLIN,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 4,
                y = 1,
            },
            [component.HEALTH] = {
                current = 20,
                max = 20,
            },
            [component.AI] = {
                behavior = "wander",
                target_x = 0,
                target_y = 0,
            },
        },
    }
    local ctx = {
        values = values,
        events = {},
        sight = true,
        draws = 0,
        width = 10,
    }

    -- Keep player-specific aura modifiers absent in this monster encounter.
    function ctx:player()
        return 999
    end

    -- Read current ECS state, including boon records added by the cry.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    -- Component presence checks distinguish a boon from an empty actor.
    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    -- Every lasting enchantment is stored on the recipient entity.
    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    -- AI hearing and boon updates return through the same ECS view.
    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    -- An expired or dispelled component leaves no ghost record.
    function ctx:remove(entity, id)
        self.values[entity][id] = nil
    end

    -- Queries select only live actors with the requested components.
    function ctx:query(ids)
        local matches = {}

        for entity, fields in pairs(self.values) do
            local complete = true

            for _, id in ipairs(ids) do
                if not fields[id] then
                    complete = false
                end
            end

            if complete then
                matches[#matches + 1] = entity
            end
        end

        table.sort(matches)

        return matches
    end

    -- A blocked sight flag models opaque terrain between actors.
    function ctx:visible_no_trans()
        return self.sight
    end

    -- Player-facing descriptions and hearing use ordinary sight, which
    -- can differ from the caster's no-trans eligibility.
    function ctx:visible()
        return self.sight
    end

    -- A bounded floor lets the production noise field propagate normally.
    function ctx:cell(_, x, y)
        if x >= 0 and x < self.width and
            y >= 0 and y < self.width then
            return terrain.DNGN_FLOOR
        end
    end

    -- Fixed draws pin the source minimum boon duration and RNG order.
    function ctx:random(_, bound)
        harness.truthy(bound > 0, "cry random bound is positive")
        self.draws = self.draws + 1

        return 0
    end

    -- A noise alert uses the same absolute clock as other AI memory.
    function ctx:aut()
        return 0
    end

    -- Preserve messages without a terminal renderer.
    function ctx:emit(kind, message)
        self.events[#self.events + 1] = {
            kind = kind,
            message = message,
        }
    end

    return ctx
end

-- All three cry files must use their real planning and resolution contracts.
function test.run()
    local battlecry = effects.effect(spells.SPELL_BATTLECRY)
    local hunting = effects.effect(spells.SPELL_HUNTING_CALL)
    local warning = effects.effect(spells.SPELL_WARNING_CRY)
    local ctx = context()
    local plan = battlecry.plan(ctx, caster, foe)

    harness.truthy(plan, "a same-genus ally makes Battlecry useful")
    harness.equal(ctx.draws, 0, "planning does not draw randomness")
    battlecry.resolve(ctx, caster, foe, nil, plan)

    local boon = ctx:get(ally, component.MONSTER_BOONS)

    harness.truthy(boon and boon.might_aut >= 120,
        "Battlecry grants saved Might for source minimum duration")
    harness.falsy(ctx:get(caster, component.MONSTER_BOONS),
        "the battlecry caster cannot buff itself")
    harness.falsy(battlecry.plan(ctx, caster, foe),
        "an already mighty ally does not cause a recast")

    local unseen = context()
    unseen.values[999] = {
        [component.POSITION] = {
            level_id = 1,
            x = 9,
            y = 9,
        },
    }
    local unseen_plan = battlecry.plan(unseen, caster, foe)

    battlecry.resolve(unseen, caster, foe, nil, unseen_plan)
    harness.equal(#unseen.events, 0,
        "a battlecry must not disclose unseen allies")

    local seen = context()
    seen.values[999] = {
        [component.POSITION] = {
            level_id = 1,
            x = 0,
            y = 1,
        },
    }
    local seen_plan = battlecry.plan(seen, caster, foe)

    battlecry.resolve(seen, caster, foe, nil, seen_plan)
    harness.equal(#seen.events, 1,
        "a visible recipient gets one battlecry announcement")

    local group = context()
    group.values[999] = seen.values[999]
    group.values[listener][component.ACTOR].kind_id =
        monsters.MONS_ORC_WARRIOR
    local group_plan = battlecry.plan(group, caster, foe)

    battlecry.resolve(group, caster, foe, nil, group_plan)
    harness.truthy(group.events[#group.events].message:find(
        "allies go into", 1, true),
        "a visible group uses the plural announcement")

    local swift = context()
    local swift_plan = hunting.plan(swift, caster, foe)

    harness.truthy(swift_plan, "Hunting Call finds an unbuffed ally")
    hunting.resolve(swift, caster, foe, nil, swift_plan)
    harness.truthy(swift:get(ally, component.MONSTER_BOONS).swift_aut > 0,
        "Hunting Call stores Swift on its recipient")

    local hasted = context()
    hasted.values[ally][component.MONSTER_BOONS] = {
        haste_aut = 50,
        might_aut = 0,
        swift_aut = 0,
    }
    harness.falsy(hunting.plan(hasted, caster, foe),
        "an already hasted ally gains no Hunting Call")

    local sleeper = context()
    sleeper.values[ally][component.MONSTER_STASIS] = {
        hibernating = true,
        sleep_wary_aut = 0,
        petrifying_aut = 0,
        petrified_aut = 0,
    }
    local sleeper_plan = battlecry.plan(sleeper, caster, foe)

    harness.truthy(sleeper_plan, "a sleeping ally remains eligible")
    battlecry.resolve(sleeper, caster, foe, nil, sleeper_plan)
    harness.falsy(sleeper:get(ally,
        component.MONSTER_STASIS).hibernating,
        "the affected sleeper wakes after the boon")

    local peaceful = context()
    peaceful.values[caster][component.SUMMON] = {
        attitude = attitudes.FRIENDLY,
    }
    peaceful.values[foe][component.SUMMON] = nil
    peaceful.values[ally][component.SUMMON] = {
        attitude = attitudes.GOOD_NEUTRAL,
    }
    harness.truthy(battlecry.plan(peaceful, caster, foe),
        "friendly and good-neutral monsters are aligned")

    local hostile = context()
    hostile.values[ally][component.SUMMON] = {
        attitude = attitudes.FRIENDLY,
    }
    harness.falsy(battlecry.plan(hostile, caster, foe),
        "a monster on the opposite side cannot be inspired")

    local wrong_genus = context()
    wrong_genus.values[ally][component.ACTOR].kind_id =
        monsters.MONS_GOBLIN
    harness.falsy(battlecry.plan(wrong_genus, caster, foe),
        "a different genus cannot receive Battlecry")

    local confused = context()
    confused.values[ally][component.MONSTER_CONFUSION] = {
        remaining_aut = 30,
    }
    harness.falsy(battlecry.plan(confused, caster, foe),
        "a confused ally cannot receive Battlecry")

    local paralyzed = context()
    paralyzed.values[ally][component.PARALYSIS] = {
        remaining_aut = 30,
    }
    harness.falsy(battlecry.plan(paralyzed, caster, foe),
        "a paralyzed ally cannot respond to a cry")

    local blocked = context()
    blocked.sight = false
    harness.falsy(battlecry.plan(blocked, caster, foe),
        "opaque terrain blocks cry planning")

    local silent = context()
    silent.values[caster][component.MONSTER_MUTE] = {
        remaining_aut = 30,
    }
    harness.falsy(battlecry.plan(silent, caster, foe),
        "a mute caster cannot announce a Battlecry")

    local alarm = context()
    alarm.values[999] = {
        [component.POSITION] = {
            level_id = 1,
            x = 0,
            y = 1,
        },
    }
    local alarm_plan = warning.plan(alarm, caster, foe)

    harness.truthy(alarm_plan, "hostile monster can issue Warning Cry")
    warning.resolve(alarm, caster, foe, nil, alarm_plan)
    harness.equal(alarm:get(listener, component.AI).target_x, 1,
        "Warning Cry propagates sound to a wandering listener")
    harness.truthy(#alarm.events > 0,
        "Warning Cry reports its sound to the client")

    local distant_warning = context()
    distant_warning.values[999] = {
        [component.POSITION] = {
            level_id = 2,
            x = 0,
            y = 0,
        },
    }
    local distant_plan = warning.plan(distant_warning, caster, foe)

    warning.resolve(distant_warning, caster, foe, nil, distant_plan)
    harness.equal(#distant_warning.events, 0,
        "an unheard off-floor warning discloses nothing")

    local remote_warning = context()
    remote_warning.width = 40
    remote_warning.values[999] = {
        [component.POSITION] = {
            level_id = 1,
            x = 35,
            y = 35,
        },
    }
    local remote_plan = warning.plan(remote_warning, caster, foe)

    warning.resolve(remote_warning, caster, foe, nil, remote_plan)
    harness.equal(#remote_warning.events, 0,
        "a same-level warning outside hearing discloses nothing")

    local silenced_listener = context()
    silenced_listener.width = 30
    silenced_listener.values[999] = {
        [component.POSITION] = {
            level_id = 1,
            x = 20,
            y = 20,
        },
        [component.PLAYER_STATUS] = {
            silence_aut = 100,
        },
    }
    local silenced_plan = warning.plan(silenced_listener, caster, foe)

    harness.truthy(silenced_plan,
        "a distant player Silence does not mute the caster")
    warning.resolve(silenced_listener, caster, foe, nil, silenced_plan)
    harness.equal(#silenced_listener.events, 0,
        "a player in Silence cannot hear an external warning")

    local friendly_warning = context()
    friendly_warning.values[caster][component.SUMMON] = {
        attitude = attitudes.FRIENDLY,
    }
    harness.falsy(warning.plan(friendly_warning, caster, foe),
        "a friendly monster does not issue a hostile warning")

    local neutral_warning = context()
    neutral_warning.values[caster][component.SUMMON] = {
        attitude = attitudes.GOOD_NEUTRAL,
    }
    harness.truthy(warning.plan(neutral_warning, caster, foe),
        "source Warning Cry only rejects strictly friendly casters")
end

return test
