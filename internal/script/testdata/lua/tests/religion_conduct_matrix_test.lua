-- This source-traced table checks the event surface of every active god.
-- It imports production IDs and modules, rather than copying rule schemas.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local gods = require("constants.gods")
local harness = require("tests.harness")
local kinds = require("constants.religion_conduct")

local test = {}

local kills = {
    kinds.KILL_LIVING,
    kinds.KILL_UNDEAD,
    kinds.KILL_DEMON,
    kinds.KILL_HOLY,
    kinds.KILL_NONLIVING,
}

-- The five ordinary kill classes are repeated by source data, not by
-- separate source formulas. Tests retain the full event set for each god.
local expected = {
    [gods.ZIN] = {
        likes = { kinds.KILL_UNCLEAN, kinds.KILL_CHAOTIC },
        dislikes = {
            kinds.ATTACK_HOLY, kinds.KILL_HOLY, kinds.EVIL,
            kinds.ATTACK_FRIEND, kinds.ATTACK_NEUTRAL,
            kinds.ATTACK_IN_SANCTUARY, kinds.UNCLEAN, kinds.CHAOS,
            kinds.DELIBERATE_MUTATING, kinds.CAUSE_GLOWING,
        },
    },

    [gods.SHINING_ONE] = {
        likes = {
            kinds.KILL_UNDEAD, kinds.KILL_DEMON,
            kinds.KILL_NATURAL_EVIL, kinds.SEE_MONSTER,
        },
        dislikes = {
            kinds.ATTACK_HOLY, kinds.KILL_HOLY, kinds.EVIL,
            kinds.ATTACK_NEUTRAL, kinds.ATTACK_FRIEND,
        },
    },

    [gods.KIKUBAAQUDGHA] = { likes = kills },
    [gods.YREDELEMNUL] = { dislikes = { kinds.HOLY } },
    [gods.XOM] = {},
    [gods.VEHUMET] = { likes = kills },
    [gods.OKAWARU] = { likes = kills },
    [gods.MAKHLEB] = { likes = kills },
    [gods.SIF_MUNA] = { likes = kills },

    [gods.TROG] = {
        likes = {
            kinds.KILL_LIVING, kinds.KILL_UNDEAD,
            kinds.KILL_DEMON, kinds.KILL_HOLY,
            kinds.KILL_NONLIVING, kinds.KILL_WIZARD,
        },
        dislikes = {
            kinds.SPELL_MEMORISE, kinds.SPELL_CASTING,
            kinds.SPELL_PRACTISE, kinds.WIZARDLY_ITEM,
        },
    },

    [gods.NEMELEX_XOBEH] = { likes = { kinds.EXPLORATION } },
    [gods.ELYVILON] = {
        likes = { kinds.EXPLORATION },
        dislikes = {
            kinds.ATTACK_HOLY, kinds.KILL_HOLY, kinds.EVIL,
            kinds.ATTACK_NEUTRAL, kinds.ATTACK_FRIEND,
        },
    },

    [gods.LUGONU] = {
        likes = {
            kinds.KILL_LIVING, kinds.KILL_UNDEAD,
            kinds.KILL_DEMON, kinds.KILL_HOLY,
            kinds.KILL_NONLIVING, kinds.BANISH,
        },
    },

    [gods.BEOGH] = {
        likes = {
            kinds.KILL_LIVING, kinds.KILL_UNDEAD,
            kinds.KILL_DEMON, kinds.KILL_HOLY,
            kinds.KILL_NONLIVING, kinds.KILL_PRIEST,
        },
        dislikes = {
            kinds.DESECRATE_ORCISH_REMAINS, kinds.ATTACK_FRIEND,
        },
    },

    [gods.JIYVA] = {
        likes = { kinds.EXPLORATION },
        dislikes = {
            kinds.KILL_SLIME, kinds.ATTACK_NEUTRAL,
            kinds.ATTACK_FRIEND,
        },
    },

    [gods.FEDHAS] = {
        likes = kills,
        dislikes = { kinds.KILL_PLANT, kinds.ATTACK_FRIEND },
    },

    [gods.CHEIBRIADOS] = {
        likes = { kinds.KILL_FAST },
        dislikes = { kinds.HASTY },
    },

    [gods.ASHENZARI] = { likes = { kinds.EXPLORATION } },
    [gods.DITHMENOS] = { likes = kills },
    [gods.GOZAG] = {},
    [gods.QAZLAL] = { likes = kills },
    [gods.RU] = { likes = { kinds.EXPLORATION } },
    [gods.USKAYAW] = { likes = { kinds.HURT_FOE } },
    [gods.HEPLIAKLQANA] = { likes = { kinds.EXPLORATION } },
    [gods.WU_JIAN] = { likes = kills },
    [gods.IGNIS] = {},
}

-- Compare sets rather than source or VFS loading order: a renamed file
-- cannot reorder a deity's reactions or change a seeded result.
local function same_keys(actual, listed, label)
    local wanted = {}
    local count = 0

    for _, id in ipairs(listed or {}) do
        wanted[id] = true
        harness.truthy(actual[id], label .. " lacks " .. id)
    end

    for id in pairs(actual) do
        harness.truthy(wanted[id], label .. " adds " .. id)
        count = count + 1
    end

    harness.equal(count, #(listed or {}), label .. " key count")
end

-- Every registered source god is checked, even one with no ordinary
-- conduct response. Added mod gods are outside this bundled-source fixture.
function test.run()
    local ids = register.ids(categories.GODS)

    harness.equal(#ids, 26)

    for _, id in ipairs(ids) do
        local source = expected[id]

        harness.truthy(source, "missing source matrix row for " .. id)

        local definition = catalog.get(categories.GODS, id)
        local needs_module = #(source.likes or {}) > 0 or
            #(source.dislikes or {}) > 0

        if needs_module then
            harness.truthy(definition.conduct_module,
                id .. " needs a conduct module")
        else
            harness.falsy(definition.conduct_module,
                id .. " has no source conduct module")
        end

        local handler = needs_module and require(definition.conduct_module)
            or {}

        same_keys(handler.likes or {}, source.likes, id .. " likes")
        same_keys(handler.dislikes or {}, source.dislikes,
            id .. " dislikes")
    end
end

return test
