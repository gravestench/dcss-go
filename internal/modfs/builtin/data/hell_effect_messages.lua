-- These are the source's two Hell arrival message groups. The first quiet
-- line has a second form for characters that cannot smell brimstone.
-- Keeping the groups in Lua lets an overlay replace prose without changing
-- the arrival policy or its chance and consequence rolls.
local messages = {}
local stats = require("constants.stats")

messages.quiet = {
    "You smell brimstone.",
    '"Abandon all hope!"',
    '"Die, mortal!"',
    '"Leave now, before it is too late!"',
    '"No one will save a wretch like you!"',
    '"Run while you still can, mortal!"',
    '"Trespassers are not welcome here!"',
    '"We do not forgive those who trespass against us!"',
    '"We have such sights to show you!"',
    '"We have you now!"',
    '"We will enjoy watching you die!"',
    '"Whatever you seek here, you will find only death!"',
}

messages.no_smell = "Brimstone rains from above."

-- lose_stat emits a second warning after the Hell line; the stat owner
-- stores the loss, while this catalog keeps its source-facing wording.
messages.stat_loss = {
    [stats.STRENGTH] = "You feel weakened.",
    [stats.INTELLIGENCE] = "You feel dopey.",
    [stats.DEXTERITY] = "You feel clumsy.",
}

messages.noisy = {
    '"BEGONE, TRESPASSER!"',
    '"WE\'VE GOT YOU NOW!"',
    "A chorus of shrieks echoes around you!",
    "A gut-wrenching scream fills the air!",
    "A hateful voice recites your deepest, darkest secrets!",
    "An anguished voice wails for what feels like eternity, then is suddenly cut off.",
    "You hear a dreadful howling, growing closer and closer...",
    "You hear a scream, and then it ends suddenly with a sickening wet crunch.",
    "You hear abhorrent words that no mortal tongue could ever pronounce...",
    "You hear an infernal cacophony!",
    "You hear diabolical laughter!",
    "You hear unearthly screeching!",
    "You hear the gnashing of teeth!",
    "You hear words spoken in a strange and terrible language...",
    "You hear your loved ones begging you to come home...",
    "You hear your loved ones encouraging you to just give up and die...",
    "You hear your loved ones mocking you for coming here!",
}

return messages
