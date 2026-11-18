# font_race: test for engine patch a

Creates Label3D nodes with new glyphs every frame, with the separate render thread on (`thread_model=2`).
Needs a Linux engine built from the same source with `disable_path_overrides=no`, xvfb and Mesa's lavapipe:

    scons platform=linuxbsd target=template_debug disable_path_overrides=no      # in the engine tree, patch applied or not
    xvfb-run -a <engine binary> --path engine/tests/font_race --rendering-driver vulkan --rendering-method mobile
    # count lines: Condition "p_image.is_null() || p_image->is_empty()" is true

12 Nov 2026, 240 frames, llvmpipe: unpatched 146 / 154 errors (Mobile), 129 / 120 / 85 (Forward+); patched 0 / 0.
The three other errors in the output (ALSA, global script cache, finalize at exit) are the same on both and come
from the headless test setup.
