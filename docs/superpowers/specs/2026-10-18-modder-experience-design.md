# Lua readability and mod creation design

## Goal

A reader should be able to open a Lua file, understand its responsibility,
identify the state it owns, and see how its rules correspond to DCSS without
searching the C++ tree. A modder should be able to create a sparse overlay by
running one command or answering a small set of terminal prompts.

## Scope

This is one repository-wide modder experience category, separate from adding
gameplay domains. It covers all bundled Lua, including generated content,
handwritten policy and systems, component schemas, and vault hooks. The
public guide lives in the root README and the detailed `docs/modding.md`.

## Comments

Every Lua file gets its own explanation of the behavior or data it contains.
Do not paste one shared header across a family of files or substitute a file
name into boilerplate. Longer files need comments throughout the relevant
functions, branches, and field groups. Non-obvious rules get comments next to
the decision or formula: why the order matters,
what DCSS behavior is being preserved, and which component or policy owns a
lasting effect. System files explain their query, schedule, and turn scope.
Content files explain the meaning of their important groups of fields. The
committed Lua is authoritative after the initial port, so its comments are
maintained directly with the content.

Comments should explain a reason or a relationship rather than restating an
assignment. Source filenames and symbol names are useful context. Original
C++ line numbers are omitted from Lua comments. The pinned revision remains
in documentation for historical context.

Every Lua function, including callbacks in test fixtures, needs an adjacent
comment that answers what rule it serves, why it is needed, and how it carries
out the rule. A call-shaped example alone does not satisfy this standard.
Every system includes a theory of operation, and every policy file includes a
concrete usage example.

## Names and order

Remove leading decimal index tokens from all bundled Lua filenames. The
relative path of a definition is its override identity, so the guide and
examples use the new descriptive path.
Catalog traversal uses stable ID order, regardless of file load order or
filename. Top-level definitions do not carry `source_order`. A rule that
requires authored ordering stores it in its own ordered records. Directory
discovery, duplicate-ID diagnostics, sparse overlays, and ruleset hashing
retain their existing semantics.

## Retire import tooling

After the ported data is committed, remove the C++ import commands, Lua
regenerators, and tests devoted solely to those tools. Keep developer tools
that validate the live code, such as style checks. Audit intermediate JSON
artifacts for runtime consumers before removing them. Historical plans may
still describe how the initial import happened; current guides and code
should not direct modders to regenerate Lua from C++.

## Mod guide

The root README explains launch, mod directory precedence, the wizard, and
the shortest complete example. `docs/modding.md` covers every current file
category, the data/behavior split, component and system contracts, policy
selection, vault `.des` and Lua hook ownership, testing, save identity, and
how to replace an embedded file at the same relative path.

Use policy for a reusable rule invoked at a decision point: eligibility,
calculation, selection, or an effect that does not own a turn schedule. Use
an ECS system when behavior is driven by turn order, query membership, or a
timer. Store mutable state that survives a turn or save in a component.
Definitions hold facts; a new mechanic can require a definition plus a
focused policy or system. The guide names the existing directories and
registration APIs for each case.

## Scaffolder

`dcrawl-mod` is a separate Go CLI that accepts `--mod-dir`, `--kind`, and
`--name`. With missing options in an interactive terminal, it asks concise
questions. Explicit flags work non-interactively for scripts. It supports
the current content categories, component, system, policy, player spell
effect, monster spell effect, and vault. The file templates live on disk,
outside Go string literals, and are embedded only into the scaffolder.

The command validates slugs and IDs, shows the files it will create, and
refuses to overwrite an existing file. It writes only beneath the selected
mod root, with the same relative layout the runtime discovers. A base file
contains a named local object and top-level functions rather than nested
anonymous callbacks. It includes meaningful comments describing fields to
fill and points to the guide. A vault scaffold uses original `.des` map
syntax and a separate Lua hook when script behavior is needed.

## Verification

Check every generated path is unique and index-free. Verify stable ID order
of representative catalogs across file renames and overlay layers,
verify sparse replacement and additive mods, and run the bundled Lua and Go
suites. Exercise scaffolding in a temporary mod directory, then load the
result through the production VFS and reject traversal or overwrite cases.
Audit the resulting comment coverage and read a sample from each Lua family
for actual explanatory value rather than raw comment count alone.
