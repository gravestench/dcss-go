# Ordinary monster experience rule

Pinned source: `crawl-ref/source/mon-util.cc:2345-2535`, revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

Extract the source's numeric experience calculation for a monster without spells, equipment, zombie state, merging, or other per-instance experience adjustments. The pure input supplies live maximum HP, hit dice, speed, class experience modifier, four attack damages, and fast-regeneration status. The rule applies the source's base formula and integer truncations in order, including difficulty from regeneration and large melee damage, speed adjustment, slow-monster halving, class modifier, high-value stepdowns, and minimum one XP. It rejects nonsensical numeric inputs. The caller remains responsible for determining that the monster grants XP and meets this ordinary rule's preconditions.

Keep the existing rat/quokka validation and fixed-scenario XP limits, but route their numeric reward through the shared rule. Do not change the saved format or fixed encounters in this category. Later monster creation can reuse the pure rule after validating its own eligibility and special cases.
