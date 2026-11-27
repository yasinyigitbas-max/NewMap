"""zh_post.py <bake_dir> <out_dir> <id>: zh_build.py's raw bakes -> the car's three maps for car_paint.gdshader's
map_mode 1: <id>_veh_albedo.png 1024 (sRGB, AO multiplied in; ALPHA = 1 paint (tinted), 0.5 glass, 0 own colour),
<id>_veh_normal.png 512 (OpenGL), <id>_veh_orm.png 512 (R AO, G roughness, B metal). Outside the islands: dilated."""
import sys, os, numpy as np
from PIL import Image
W, T, N = sys.argv[1:4]
L = lambda n: np.load(os.path.join(W, n + '.npy'))
col, nor, ao, ro, me, am = (L(k) for k in ('color', 'normal', 'ao', 'rough', 'metal', 'amask'))
cov = L('cover')[..., 0] > 0.5
print('coverage %.1f %%' % (100 * cov.mean()))
a = ao[..., 0]
mk = np.round(am[..., 0] * 2) / 2
paint, glass = mk > 0.75, (mk > 0.25) & (mk < 0.75)
col = col.copy(); me = me.copy()
col[..., :3][paint] = np.clip(col[..., :3][paint] / 0.8, 0, 1)    # (the paint was baked from a 0.8 grey: the game's paint colour shows true)
me[..., 0][paint | glass] = 0.0     # (car_paint.gdshader gives the paint its own clear coat; a metallic paint read black)
c = col[..., :3] * (0.3 + 0.7 * a[..., None])
def srgb(x):
    x = np.clip(x, 0, 1)
    return np.where(x <= 0.0031308, 12.92 * x, 1.055 * np.power(x, 1 / 2.4) - 0.055)
def dilate(img, mask, n=40):
    img = img.copy(); m = mask.copy()
    for _ in range(n):
        if m.all(): break
        acc = np.zeros_like(img); cnt = np.zeros(m.shape, np.float32)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            sm = np.roll(np.roll(m, dy, 0), dx, 1); si = np.roll(np.roll(img, dy, 0), dx, 1)
            acc += si * sm[..., None]; cnt += sm
        new = (~m) & (cnt > 0)
        img[new] = acc[new] / cnt[new][..., None]; m = m | new
    if not m.all():
        img[~m] = img[m].mean(0)
    return img
def save(arr, size, path, normal=False, mode='RGB'):
    im = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), mode).resize((size, size), Image.LANCZOS)
    if normal:
        v = np.asarray(im).astype(np.float32) / 255 * 2 - 1
        v /= np.maximum(np.linalg.norm(v, axis=-1, keepdims=True), 1e-6)
        im = Image.fromarray(((v * 0.5 + 0.5) * 255 + 0.5).astype(np.uint8))
    im.save(path, optimize=True)
    print('wrote', path, im.size, os.path.getsize(path))
rgba = np.concatenate([srgb(c), np.round(am[..., :1] * 2) / 2], -1)
save(dilate(rgba, cov), 1024, os.path.join(T, N + '_veh_albedo.png'), mode='RGBA')
save(dilate(nor[..., :3], cov), 512, os.path.join(T, N + '_veh_normal.png'), normal=True)
save(dilate(np.stack([a, ro[..., 0], me[..., 0]], -1), cov), 512, os.path.join(T, N + '_veh_orm.png'))
