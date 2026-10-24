# Monster polymorph routing: text floor

The focused Lua rule test places a merged slime at `(40,40)` in open
Dungeon floor cells. `S` is the original three-blob slime and `?` is an
individually transformed body. The fixture returns zero for every draw,
so fair placement selects the last available site in scan order. Species
are intentionally omitted; the test asserts each body changed form.

```text
 y   Before spell                       After forced division and polymorph
38   .....                              .....
39   .....                              .....
40   ..S..                              ..?..
41   .....                              ..??.
42   .....                              .....

     S: size 3, HP 90/90                ?: three living ECS actors
                                         each has its own rolled form
                                         both children keep slime.birth
```

The rule also covers a fully blocked neighboring ring. With no legal split
cell, the original body still changes form in its own cell. The forced
division draws a fair placement site from the `slime_creature` stream. It
consumes the ordinary one-in-two draw but ignores its result, matching the
source condition's evaluation order.
