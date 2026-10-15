# Lua terminal input policy

## Intent

The bundled terminal client should keep the DCSS controls and screen flow it
already has while making keymaps and menu decisions editable through the same
embedded Lua tree as other game policy. A same-path mod override should change
one screen's controls without rebuilding Go. The effective ruleset hash must
capture that change.

## Boundary

Go owns Bubble Tea messages, terminal dimensions, canvas drawing, game
lifecycle, save I/O, and the concrete execution of a game command. Lua owns
what a key means on each screen, menu selection and invalid-key messages,
focus movement, and navigation decisions. The current Go key switches are
removed in the same pass. There is no fallback Go keymap or compatibility
route.

One `terminal.input` Lua policy receives a snapshot of the terminal's
relevant state and the pressed key. It returns the next terminal state plus
an optional effect request. Effects are a small set of host capabilities,
such as running a game command, starting a game, saving, or loading. The host
validates policy output before applying it and reports malformed mod output
with a diagnostic notice, without changing navigation or game state. Each
screen's Lua code lives in a focused module
under `policy/input/`; the policy dispatches by screen ID without a growing
key switch.

The input policy uses the catalog Lua VM throughout the session with a
read-only host context. It receives all needed terminal state in its input,
so a modded key decision cannot mutate the live game before Go validates
it. Lua source is stored only as `.lua` files in the
embedded mod directory. Existing startup, character choice, game commands,
inventory, targeting, skills, help, save confirmation, and death screens
retain their current visible behavior.

## Verification

Exercise representative keys from every screen, disabled game modes and
items, multiple menu pages, equipment delay, and save/restore navigation.
An override of one input module must alter the action and ruleset hash.
Run the full terminal and game suites, vet, build, style and diff checks at
the category boundary. Commit the whole conversion once and merge to local
Go `main` while preserving the user's untracked save.
