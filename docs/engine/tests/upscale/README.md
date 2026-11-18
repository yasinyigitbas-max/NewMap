# upscale: test for engine patch c (SGSR 1 in the Mobile renderer)

A still street scene (3D text, thin rails, crosswalk, low-angle paving, facades). Env: `UP_SCALE`, `UP_MODE`
(0 bilinear, 1 = FSR 1 mode, which runs SGSR 1 with patch c), `UP_AA` (1 FXAA), `UP_SHARP`, `UP_NAME`.

    UP_NAME=sgsr UP_SCALE=0.5 UP_MODE=1 UP_AA=1 xvfb-run -a -s "-screen 0 1280x720x24" <engine> \
        --path engine/tests/upscale --rendering-driver vulkan --rendering-method mobile

12 Nov 2026, 1280x720 output, 640x360 internal, FXAA on, x86 llvmpipe:
- patched engine, mode 0 (bilinear): bit-identical to the unpatched engine. Mode 1 at scale 1.0: identical to native.
- unpatched engine, mode 1: falls back to bilinear (same file as mode 0).
- PSNR against the native 100 % frame: bilinear 29.32 dB, SGSR plain 28.90 dB, SGSR edge direction 29.46 dB.
  The plain mode turned FXAA's steps into wobbly lines; the edge-direction mode is what the patch ships.
- `results/compare_crops.png`: native | today (bilinear) | new (SGSR 1), 3x zoom. `results/compare_full.png`: full frames.
- FSR 1 itself (Forward+ only) on the same scene looks about as sharp; its frame is lit differently by Forward+,
  so no number is given.

Not measured here: GPU time. On the phone, switch `scaling_3d_mode` between 0 and 1 on the same build
(`debug/sys_toggle.gd` and `perf_probe` already do) and compare GPU ms.
