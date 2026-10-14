-- The sorted domain order is part of the ruleset contract. New files in a
-- domain tree are discovered without editing this entrypoint.
mod.load_tree("schemas")
mod.load_tree("content")
mod.load_tree("policy")
mod.load_tree("systems")
mod.load_tree("generation")
mod.load_tree("ui")
