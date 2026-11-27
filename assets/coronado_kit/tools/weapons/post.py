"""post.py <work> <atlas_dir>: raw bakes (linear float, .npy) -> page G maps.
props_g_color_clean.png 1024 (sRGB, AO multiplied in), props_g_normal.png 512, props_g_orm.png 256 (R AO, G rough, B metal).
Texels outside the islands are filled by repeated dilation so mips never bleed black into the edges."""
import sys, os, numpy as np
from PIL import Image, ImageFilter
W, A = sys.argv[1], sys.argv[2]
L = lambda n: np.load(os.path.join(W, n + '.npy'))
col, nor, ao, ro, me = (L(k) for k in ('color', 'normal', 'ao', 'rough', 'metal'))
# coverage: the normal bake writes (0.5,0.5,1)-ish everywhere inside islands; outside it stays 0 (no clear colour)
cov = L('mask')[..., 0] > 0.5
print('coverage %.1f %%' % (100 * cov.mean()))
ao1 = ao[..., 0]
AOK = 0.80   # how much of the AO goes into the colour (spec: AO baked into the base colour)
c = col[..., :3] * (1 - AOK + AOK * ao1[..., None])
def srgb(x):
    x = np.clip(x, 0, 1)
    return np.where(x <= 0.0031308, 12.92 * x, 1.055 * np.power(x, 1 / 2.4) - 0.055)
def dilate(img, mask, n=64):
    img = img.copy(); m = mask.copy()
    for _ in range(n):
        if m.all(): break
        acc = np.zeros_like(img); cnt = np.zeros(m.shape, np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            sm = np.roll(np.roll(m, dy, 0), dx, 1); si = np.roll(np.roll(img, dy, 0), dx, 1)
            acc += si * sm[..., None]; cnt += sm
        new = (~m) & (cnt > 0)
        img[new] = acc[new] / cnt[new][..., None]; m = m | new
    if not m.all():
        img[~m] = img[m].mean(0)
    return img
def save(arr, size, path, normal=False):
    im = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8))
    im = im.resize((size, size), Image.LANCZOS)
    if normal:
        a = np.asarray(im).astype(np.float32) / 255 * 2 - 1
        a /= np.maximum(np.linalg.norm(a, axis=-1, keepdims=True), 1e-6)
        im = Image.fromarray(((a * 0.5 + 0.5) * 255 + 0.5).astype(np.uint8))
    im.save(path, optimize=True)
    print('wrote', path, im.size, os.path.getsize(path))
c = dilate(srgb(c), cov)
n = dilate(nor[..., :3], cov)
orm = dilate(np.stack([ao1, ro[..., 0], me[..., 0]], -1), cov)
save(c, 1024, os.path.join(A, 'props_g_color_clean.png'))
save(n, 512, os.path.join(A, 'props_g_normal.png'), normal=True)
save(orm, 256, os.path.join(A, 'props_g_orm.png'))
np.save(os.path.join(W, 'coverage.npy'), cov)
