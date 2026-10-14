# Error guard and raw fixture readability

**Goal:** Remove two remaining forms of code crowding throughout handwritten
Go without changing behavior.

**Scope:** A condition that tests an error alongside another condition gives
each boolean clause its own line. A statement that ends with a multiline raw
string literal has a blank line before the next statement. Short single
checks and source text inside raw strings remain as they are.

**Implementation:**

1. Add focused failing cases to the Go readability checker tests.
2. Extend its AST rules to report these forms with clear messages.
3. Reformat the reported Go files. Keep logical groups intact and avoid
   adding unrelated framework code.
4. Compare executable token streams before and after the sweep, then run
   checker tests, all Go tests, vet, build, style, and diff checks.
5. Obtain read-only code review, make one readability-category commit, merge
   into local Go `main`, and verify the merged checkout.

**Contract:** Follow `AGENTS.md`: 120 columns maximum, prefer 80, multiline
struct fields, visual separation between validation and state changes.
