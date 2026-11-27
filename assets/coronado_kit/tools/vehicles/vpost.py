"""vpost.py <work> <tex_dir> <name>: raw bakes -> veh_<name>_color.png 1024 (sRGB, AO multiplied in, ALPHA = the
paint / glass mask of car_paint.gdshader: 1 paint, 0.5 glass, 0 own colour), veh_<name>_normal.png 512 (OpenGL),
veh_<name>_orm.png 512 (R AO, G roughness, B metal). Outside the islands: dilated."""
import sys, os, numpy as np
from PIL import Image
W, T, N = sys.argv[1:4]
L = lambda n: np.load(os.path.join(W, n + '.npy'))
col, nor, ao, ro, me, am = (L(k) for k in ('color', 'normal', 'ao', 'rough', 'metal', 'amask'))
cov = L('mask')[..., 0] > 0.5
print('coverage %.1f %%' % (100 * cov.mean()))
ao1 = ao[..., 0]
c = col[..., :3] * (0.25 + 0.75 * ao1[..., None])
def srgb(x):
    x = np.clip(x, 0, 1)
    return np.where(x <= 0.0031308, 12.92 * x, 1.055 * np.power(x, 1 / 2.4) - 0.055)
def dilate(img, mask, n=48):
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
    im = Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), mode)
    im = im.resize((size, size), Image.LANCZOS)
    if normal:
        a = np.asarray(im).astype(np.float32) / 255 * 2 - 1
        a /= np.maximum(np.linalg.norm(a, axis=-1, keepdims=True), 1e-6)
        im = Image.fromarray(((a * 0.5 + 0.5) * 255 + 0.5).astype(np.uint8))
    im.save(path, optimize=True)
    print('wrote', path, im.size, os.path.getsize(path))
rgba = np.concatenate([srgb(c), np.round(am[..., :1] * 2) / 2], -1)    # alpha snapped to 0 / 0.5 / 1
rgba = dilate(rgba, cov)
save(rgba, 1024, os.path.join(T, 'veh_%s_color.png' % N), mode='RGBA')
save(dilate(nor[..., :3], cov), 512, os.path.join(T, 'veh_%s_normal.png' % N), normal=True)
save(dilate(np.stack([ao1, ro[..., 0], me[..., 0]], -1), cov), 512, os.path.join(T, 'veh_%s_orm.png' % N))
