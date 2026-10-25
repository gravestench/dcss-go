# Generated Name Fidelity Design

## Intent

Use one source-backed `make_name` policy for ordinary names, scroll labels,
and Jiyva names. Current Pan and vault names use different approximations;
scroll labels use a fixed syllable code. A single readable Lua owner should
make these callers consistent without moving name policy into Go.

## Random ownership

The source seeds a temporary PCG generator with the game's seed and a
32-bit name seed. Drawing the seed spends the caller's named gameplay RNG
once; spelling the name spends only the temporary generator. The Go kernel
will expose a short-lived local PCG stream to Lua as a general random
primitive. It will not persist that stream, because the completed name or
appearance seed belongs to the caller's saved state. The source PCG
bounded-draw method, including rejection, is part of the primitive.

Lua owns `policy.names.source`. It contains the source weighted letters,
position-specific clusters, 150-iteration limit, final-consonant rule,
and capitalization. Its three named modes are ordinary, scroll, and
Jiyva. Scroll mode adds six length units and uppercases the result.
Jiyva mode starts with J, forbids spaces, caps length at eight, and
retries a too-short name using a new caller-stream seed.

## Callers

Scroll appearance state keeps one unique index in the 151 by 151 source
seed space. The name owner maps that index to the two source draws and
the pinned `OBJ_SCROLLS` class byte, then spells the label with the
private subgenerator. Pan lords and DES vault hooks call the ordinary
name mode; each consumes one seed draw and stores or emits the finished
name where its existing owner already does. Jiyva's generated second
name uses the dedicated mode when that name is initialized. Random
artefact and book catalog titles retain their separate source naming
database; only their direct `make_name` fallback uses this policy.
Each fallback word draws its own seed from the saved item-generation stream.
Ordinary shops unpack their saved keeper bytes and call `from_seed` without
another gameplay draw; explicit DES owner names still win.

## Verification

Compare known seeds and modes with an independent source-derived oracle.
Test private RNG behavior, scroll appearance uniqueness and save/restore,
Pan and vault caller integration, and a sparse mod replacing the Lua
name policy. No C++ checkout or generated-name importer is needed at
build or runtime.
