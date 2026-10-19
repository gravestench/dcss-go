# Monster web projectile slice

Ensnare is now a live monster spell for source spellbooks that contain it.
The source-shaped beam profile gives the stream of webbing a five-cell
range and `22 + power / 20` accuracy. Ordinary beam planning preserves
its selected foe and rejects blocking terrain or allies. At resolution,
the projectile can miss, be blocked, or be repelled; only a hit applies
the web. It deals no direct HP damage.

The web policy also serves chaos web effects. Both entry points attach
the same Akara held component and place a disposable floor web where
legal. The trap owner handles later escape, forced release, and save
validation. Giants, insubstantial or web-immune actors, and actors already
held do not gain another restraint.

The Lua rule test executes a real monster cast through beam resolution,
checks a blocked plan, zero HP damage, a saved web hold, duplicate-hit
rejection, and giant immunity. The existing chaos web tests continue to
exercise placement and save behavior through the same owner.
