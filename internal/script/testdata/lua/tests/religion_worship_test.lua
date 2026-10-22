-- Worship transitions use the production god catalog and ECS schema. Each
-- case creates a fresh player so past conversions cannot mask first-god rules.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local jobs = require("ids.jobs")
local species = require("ids.species")
local piety = require("policy.religion.piety")
local sources = require("constants.religion_sources")
local signals = require("constants.religion_signals")
local worship = require("policy.religion.worship")

local test = {}

-- Use real components and a saved wallet; the join path must not rely on a
-- duplicated test schema or a made-up character record.
local function player(ctx, job_id)
    local actor = ctx:create()

    ctx:add(actor, component.PLAYER, {
        species_id = species.SP_HILL_ORC,
        job_id = job_id or jobs.JOB_FIGHTER,
        name = "Worship test",
    })
    ctx:add(actor, component.WALLET, {})
    ctx:add(actor, component.RELIGION_WORSHIP, {})

    return actor
end

-- Capture the source's Xom timeout draws and transition events without
-- replacing the real ECS access methods or production rules.
local function observed(ctx, draws)
    local proxy = setmetatable({}, { __index = ctx })
    local events = {}
    local used = 0

    function proxy:random(_, bound)
        used = used + 1
        harness.equal(bound, 40)

        return draws and draws[used] or 0
    end

    function proxy:signal(name, value)
        events[#events + 1] = {
            name = name,
            value = value,
        }
    end

    function proxy:events()
        return events
    end

    function proxy:draws_used()
        return used
    end

    return proxy
end

-- Every source god must resolve through the same catalog and initialize its
-- own source starting value; file name and discovery order never select it.
local function all_starts(ctx)
    local ids = register.ids(categories.GODS)

    harness.equal(#ids, 26)

    for index = 2, #ids do
        harness.truthy(ids[index - 1] < ids[index],
            "god traversal must use stable ID order")
    end

    for _, god_id in ipairs(ids) do
        local actor = player(ctx)
        local rule = observed(ctx, { 3, 5 })
        local definition = catalog.get(categories.GODS, god_id)

        worship.join(rule, actor, god_id, sources.ALTAR)

        local state = ctx:get(actor, component.RELIGION_WORSHIP)

        harness.equal(state.god_id, god_id)
        harness.equal(state.worshipped[god_id], 1)
        harness.equal(state.piety, definition.starting_piety +
            (god_id == gods.LUGONU and 20 or 0))

        if god_id == gods.XOM then
            harness.equal(rule:draws_used(), 2)
            harness.equal(state.gift_timeout, 8)
        else
            harness.equal(rule:draws_used(), 0)
        end
    end
end

-- The old god must leave before the new god joins. Good-god transfer saves
-- half of devotion above the first star, then clears its temporary bridge.
local function transfer(ctx)
    local actor = player(ctx)
    local rule = observed(ctx)

    worship.join(rule, actor, gods.ZIN, sources.ALTAR)

    local state = ctx:get(actor, component.RELIGION_WORSHIP)

    state.piety = 90
    ctx:set(actor, component.RELIGION_WORSHIP, state)

    worship.join(rule, actor, gods.ELYVILON, sources.ALTAR)

    state = ctx:get(actor, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 45)
    harness.equal(state.previous_good_god, gods.NO_GOD)
    harness.equal(state.saved_good_piety, 0)
    harness.equal(rule:events()[2].name, signals.LEFT)
    harness.equal(rule:events()[3].name, signals.JOINED)
    harness.equal(rule:events()[2].value.god_id, gods.ZIN)
    harness.equal(rule:events()[3].value.god_id, gods.ELYVILON)
end

-- A first-god Monk gets a source entry bonus only once. Ecumenical prayer
-- adds its separate bonus after the ordinary transition.
local function bonuses(ctx)
    local monk = player(ctx, jobs.JOB_MONK)
    local rule = observed(ctx)

    worship.join(rule, monk, gods.ZIN, sources.ALTAR)

    harness.equal(ctx:get(monk, component.RELIGION_WORSHIP).piety, 50)

    worship.renounce(rule, monk)
    worship.join(rule, monk, gods.TROG, sources.ALTAR)

    harness.equal(ctx:get(monk, component.RELIGION_WORSHIP).piety, 15)

    local convert = player(ctx)

    worship.join(rule, convert, gods.TROG, sources.ECUMENICAL)

    harness.equal(ctx:get(convert, component.RELIGION_WORSHIP).piety, 35)
end

-- Gozag charges the wallet at join, after eligibility. Ignis keeps spent
-- piety on return rather than minting a fresh reserve.
local function god_exceptions(ctx)
    local greedy = player(ctx)
    local wallet = ctx:get(greedy, component.WALLET)

    wallet.gold = 100
    wallet.generated_gold = 100
    ctx:set(greedy, component.WALLET, wallet)

    worship.join(observed(ctx), greedy, gods.GOZAG, sources.ALTAR)

    wallet = ctx:get(greedy, component.WALLET)

    harness.equal(wallet.gold, 75)
    harness.equal(wallet.gozag_gold_used, 25)

    local refused = player(ctx)
    local low_funds = ctx:get(refused, component.WALLET)

    low_funds.gold = 10
    low_funds.generated_gold = 100
    ctx:set(refused, component.WALLET, low_funds)

    local allowed = observed(ctx)

    -- Zin now tithes one of the ten carried pieces before Gozag evaluates
    -- the later fee. Use the real RNG for that independent religion rule.
    worship.join(ctx, refused, gods.ZIN, sources.ALTAR)

    local ok = pcall(worship.join, allowed, refused, gods.GOZAG,
        sources.ALTAR)

    harness.falsy(ok, "a refused Gozag fee cannot renounce the old god")
    harness.equal(ctx:get(refused, component.RELIGION_WORSHIP)
        .god_id, gods.ZIN)
    harness.equal(ctx:get(refused, component.WALLET).gold, 9)

    worship.join(allowed, refused, gods.GOZAG, sources.ECUMENICAL)

    harness.equal(ctx:get(refused, component.WALLET).gold, 9)
    harness.equal(ctx:get(refused, component.WALLET).gozag_gold_used, 0)

    local ember = player(ctx)
    local rule = observed(ctx)

    worship.join(rule, ember, gods.IGNIS, sources.ALTAR)
    piety.lose(rule, ember, 20)
    worship.renounce(rule, ember)
    worship.join(rule, ember, gods.IGNIS, sources.ALTAR)

    harness.equal(ctx:get(ember, component.RELIGION_WORSHIP).piety, 111)

    piety.lose(rule, ember, 200)
    worship.renounce(rule, ember)
    worship.join(rule, ember, gods.IGNIS, sources.ALTAR)

    harness.equal(ctx:get(ember, component.RELIGION_WORSHIP).piety, 0)
end

-- Special entry rewards are saved with their own god owner. Later
-- sacrifice, curse, soul, and Xom systems can consume them after restore.
local function special_rewards(ctx)
    local monk_ru = player(ctx, jobs.JOB_MONK)

    worship.join(observed(ctx), monk_ru, gods.RU, sources.ALTAR)

    harness.equal(ctx:get(monk_ru, component.RELIGION_RU)
        .sacrifice_progress, 9999)
    harness.equal(ctx:get(monk_ru, component.RELIGION_WORSHIP)
        .piety, 10)

    local monk_ash = player(ctx, jobs.JOB_MONK)

    worship.join(observed(ctx), monk_ash, gods.ASHENZARI, sources.ALTAR)

    local curse = ctx:get(monk_ash, component.RELIGION_ASHENZARI)

    harness.equal(curse.curse_progress, 19)
    harness.truthy(curse.offer_pending)

    local altar_ru = player(ctx)

    worship.join(observed(ctx), altar_ru, gods.RU, sources.ECUMENICAL)

    harness.equal(ctx:get(altar_ru, component.RELIGION_RU)
        .sacrifice_progress, 9999)

    local altar_ash = player(ctx)

    worship.join(observed(ctx), altar_ash, gods.ASHENZARI,
        sources.ECUMENICAL)

    harness.equal(ctx:get(altar_ash, component.RELIGION_ASHENZARI)
        .curse_progress, 9999)

    local altar_xom = player(ctx)

    worship.join(observed(ctx, { 3, 5 }), altar_xom, gods.XOM,
        sources.ECUMENICAL)

    harness.equal(ctx:get(altar_xom, component.RELIGION_XOM)
        .pending_stimulation, 200)

    local monk_yred = player(ctx, jobs.JOB_MONK)

    worship.join(observed(ctx), monk_yred, gods.YREDELEMNUL,
        sources.ALTAR)

    harness.equal(ctx:get(monk_yred, component.RELIGION_YREDELEMNUL)
        .pending_bonus_stars, 2)

    local altar_yred = player(ctx)

    worship.join(observed(ctx), altar_yred, gods.YREDELEMNUL,
        sources.ECUMENICAL)

    harness.equal(ctx:get(altar_yred, component.RELIGION_YREDELEMNUL)
        .pending_bonus_stars, 1)
end

-- Renunciation records each source god's penance even though later wrath
-- systems still own the punishment. No god keeps a current piety total.
local function renunciation(ctx)
    for _, god_id in ipairs(register.ids(categories.GODS)) do
        local actor = player(ctx)
        local rule = observed(ctx)
        local definition = catalog.get(categories.GODS, god_id)

        worship.join(rule, actor, god_id, sources.ALTAR)
        harness.truthy(worship.renounce(rule, actor))

        local state = ctx:get(actor, component.RELIGION_WORSHIP)

        harness.equal(state.god_id, gods.NO_GOD)
        harness.equal(state.piety, 0)
        harness.equal(state.penance[god_id], definition.wrath_penance)
        harness.falsy(worship.renounce(rule, actor))
    end
end

-- Exercise source transitions in independent records under the real VM.
function test.run(ctx)
    all_starts(ctx)
    transfer(ctx)
    bonuses(ctx)
    god_exceptions(ctx)
    special_rewards(ctx)
    renunciation(ctx)
end

return test
