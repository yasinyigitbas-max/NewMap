# shader_mem: test for engine patches b1 / b2 / b3

24 different spatial shaders on boxes, a shadowed sun and two omni lights, Mobile renderer, `thread_model=2`.
After 150 frames it saves `user://shot.png`, prints process memory and quits. Linux engine built from the same
source (`disable_path_overrides=no`), xvfb + lavapipe:

    xvfb-run -a -s "-screen 0 640x360x24" <engine> --path engine/tests/shader_mem --rendering-driver vulkan --rendering-method mobile

Run each engine twice (the first run fills the shader cache; a run that quits while pipelines still compile shows
the ubershader picture, which differs by a few rounding steps).

12 Nov 2026 (x86, llvmpipe). 24 materials = 313 RD shaders, 200 of them with specialization constants:
parsed re-spirv copies 97.4 MB, their SPIR-V 17.7 MB, the same code as stored in the container 2.4 MB.

| engine | RssAnon MB (runs) | engine-tracked MB | picture vs baseline |
|---|---|---|---|
| baseline | 1157 / 1164 / 1163 / 1162 | 45.0 | - |
| b1 re-spirv off for spec constants | 1112 / 1108 | 44.7 | 4295 of 230400 pixels differ, at most 3/255 |
| b2 parse on demand | 1016 / 1018 / 1015 / 1016 | 49.1 | identical (0 pixels) |
| b3 free variant bytes | 1161 / 1159 | 40.9 | identical (0 pixels) |

b2 parse cost here: 0.7 ms per stage when measured at load (baseline does this for every stage of every shader with
specialization constants), about 1.5 ms per stage on a busy worker thread at pipeline creation; 100+ on-demand
parses, none failed.

`SM_FRAMES=12` quits while pipelines are compiling: the process then hangs in `Main::cleanup` ->
`WorkerThreadPool::exit_languages_threads()` on the baseline too (separate render thread; not from these patches).

Numbers from the game's own shaders (Linux, read during loading, `engine/patches/dev/stats_respv.patch`):
500 shaders with specialization constants = 230 MB parsed copies, 44 MB SPIR-V, 6 MB compressed.

13 Nov 2026, the light grid (patch e) in this test, grid OFF (the scene's two omni lights use the old path):
| engine | RssAnon MB | picture |
|---|---|---|
| baseline | 1163 | - |
| e2_light_grid | 1286 / 1288 / 1285 | identical |
| all1 (a + b2 + b3 + c) | 1004 to 1028 | identical |
| all3 (all1 + e) | 1132 / 1134 | identical |

So the light grid's extra shader code costs about 120 MB here for 313 shaders, with or without b2. It is not the
re-spirv copies (b2 removes those); it is most likely llvmpipe's compiled code for the larger unspecialized and
ubershader variants, which a phone driver stores far more compactly. Unproven: watch total app memory in the
phone lap of e2_light_grid against base.
