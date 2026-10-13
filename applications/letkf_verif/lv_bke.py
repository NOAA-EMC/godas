"""Barotropic kinetic energy of the ocean background and of its increment.

The slow build-up of barotropic energy -- coastally trapped waves the
altimetry keeps re-exciting, a linear instability starting -- does not show
in any per-cycle score. Its integral does. On MOM6's C grid, with h averaged
to the velocity faces (zero where either neighbour is land),

    U   = sum_k h_k u_k             transport per unit width (and V on v-faces)
    BKE = 1/2 rho0 (U^2 + V^2) / H  barotropic KE per unit area, H = sum_k h_k
    KE  = 1/2 rho0 sum_k h_k (u_k^2 + v_k^2)

integrated over the tracer-cell area of each zone. Zones come from the depth
H of the file itself: shelf (< 200 m), slope (200-1000 m), deep (> 1000 m),
global, and a coastal band (< coast_km of the coast) where a gridspec with
distance_from_coast is at hand. The u/v grid-frame rotation does not matter:
|u|^2 is invariant under it.

Two sources per cycle: the background valid at the cycle (the history file
the experiment's background pattern resolves to) and the increment MOM6
ingests (its u/v, with its own h -- the target thickness, not an increment).

Every (cycle, source) is ~1.4 GB to read and independent of every other, so
``update()`` farms them out to a process pool and keeps the results in a CSV
per experiment, keyed on the input path and mtime: a rerun computes only new
or regenerated files.
"""

import csv
import os

import numpy as np
from netCDF4 import Dataset

RHO0 = 1035.0                        # kg m-3
PJ = 1e15
SHELF, SLOPE = 200.0, 1000.0         # m
SOURCES = ('background', 'increment')
FIELDS = ['cycle', 'source', 'path', 'mtime', 'zone', 'bke_PJ', 'ke_PJ']
NONE = 'none'                        # zone of a row for a file with no u/v/h

# Set once per worker by _init(): the grid arrays are ~40 MB, too big to
# pickle into every task.
_GRID = {}


def zone_names(coast):
    return ['shelf', 'slope', 'deep', 'global'] + (['coast'] if coast is not None else [])


def _level(v, k):
    """Level ``k`` of a (time, z, y, x) variable, missing/fill as 0."""
    return np.ma.filled(v[0, k], 0.0).astype('f8')


def _face_thickness(h):
    """h on u-faces (east, periodic in x) and v-faces (north; the last row
    is kept as is at the tripolar fold); zero unless both sides are wet."""
    he = np.roll(h, -1, axis=1)
    hu = np.where((h > 0) & (he > 0), 0.5 * (h + he), 0.0)
    hn = np.vstack([h[1:], h[-1:]])
    hv = np.where((h > 0) & (hn > 0), 0.5 * (h + hn), 0.0)
    return hu, hv


def energy_maps(path):
    """(BKE, KE) in J m-2 and the depth H in m on the tracer grid, or None
    when the file lacks u, v or h. Reads one level at a time, so memory stays
    at a few 2-D fields."""
    with Dataset(path) as ds:
        if not all(n in ds.variables for n in ('u', 'v', 'h')):
            return None
        u, v, h = ds['u'], ds['v'], ds['h']
        shape = h.shape[2:]
        Ut, Vt, Hu, Hv, ke, H = (np.zeros(shape) for _ in range(6))
        for k in range(h.shape[1]):
            hk = _level(h, k)
            uk, vk = _level(u, k), _level(v, k)
            hu, hv = _face_thickness(hk)
            Ut += hu * uk
            Vt += hv * vk
            Hu += hu
            Hv += hv
            ke += hu * uk ** 2 + hv * vk ** 2
            H += hk
    with np.errstate(invalid='ignore', divide='ignore'):
        bke = (np.where(Hu > 0, Ut ** 2 / Hu, 0.0)
               + np.where(Hv > 0, Vt ** 2 / Hv, 0.0))
    return 0.5 * RHO0 * bke, 0.5 * RHO0 * ke, H


def _zones(H, wet, coast, coast_km):
    out = [('shelf', wet & (H > 0) & (H < SHELF)),
           ('slope', wet & (H >= SHELF) & (H < SLOPE)),
           ('deep', wet & (H >= SLOPE)),
           ('global', wet & (H > 0))]
    if coast is not None:
        out.append(('coast', wet & (H > 0) & (coast < coast_km)))
    return out


def _init(area, wet, coast, coast_km):
    _GRID.update(area=area, wet=wet, coast=coast, coast_km=coast_km)


def _integrate(task):
    """Worker: (exp, cycle, source, path, mtime) -> (task, [(zone, bke, ke)])
    in PJ; [] when the file has no u/v/h."""
    path = task[3]
    maps = energy_maps(path)
    if maps is None:
        return task, []
    bke, ke, H = maps
    a = _GRID['area']
    return task, [(z, float(np.sum(bke[m] * a[m])) / PJ, float(np.sum(ke[m] * a[m])) / PJ)
                  for z, m in _zones(H, _GRID['wet'], _GRID['coast'], _GRID['coast_km'])]


def coast_distance(exps, cycles, shape):
    """distance_from_coast (km) from the first MOM6 gridspec found beside an
    analysis, or None. The slimmed lv_grid.nc does not carry it."""
    import glob
    for e in exps:
        for c in cycles:
            for g in sorted(glob.glob(os.path.join(e.dir_for(c), 'ocean', '*gridspec*.nc'))):
                with Dataset(g) as ds:
                    if 'distance_from_coast' not in ds.variables:
                        continue
                    v = ds['distance_from_coast']
                    d = np.asarray(v[0] if v.ndim == 3 else v[:], dtype='f8')
                if d.shape == tuple(shape):
                    return d / 1e3, g
    return None, None


def cache_path(cfg, slug):
    return os.path.join(cfg['outdir'], 'bke_%s.csv' % slug)


def load(path):
    """{(cycle, source): {'path', 'mtime', 'zones': {zone: (bke, ke)}}}."""
    out = {}
    if not os.path.exists(path):
        return out
    with open(path) as f:
        for r in csv.DictReader(f):
            e = out.setdefault((r['cycle'], r['source']),
                               {'path': r['path'], 'mtime': r['mtime'], 'zones': {}})
            if r['zone'] != NONE:
                e['zones'][r['zone']] = (float(r['bke_PJ']), float(r['ke_PJ']))
    return out


def _save(path, entries):
    tmp = path + '.tmp'
    with open(tmp, 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(FIELDS)
        for (cycle, source), e in sorted(entries.items()):
            rows = sorted(e['zones'].items()) or [(NONE, (np.nan, np.nan))]
            for z, (b, k) in rows:
                w.writerow([cycle, source, e['path'], e['mtime'], z, '%.6g' % b, '%.6g' % k])
    os.replace(tmp, path)


def _mtime(p):
    return '%.3f' % os.path.getmtime(p)


def update(cfg, plan, area, wet, coast, coast_km, jobs=1, force=False, log=print):
    """Bring every experiment's cache up to date and return the caches.

    ``plan`` is {exp name: (slug, {(cycle, source): path})}. A (cycle,
    source) is computed when it is not cached, its file changed (path or
    mtime), or its cached zones are not the ones asked for now; a file with
    no u/v/h is cached as such and not retried. ``force`` re-reads all."""
    want = set(zone_names(coast))
    caches, todo, dirty = {}, [], set()
    for name, (slug, files) in plan.items():
        cache = load(cache_path(cfg, slug))
        # drop entries for files no longer resolved (cycle window moved)
        kept = {k: v for k, v in cache.items() if k in files}
        if len(kept) != len(cache):
            dirty.add(name)
        caches[name] = cache = kept
        for (cycle, source), path in sorted(files.items()):
            e = cache.get((cycle, source))
            mt = _mtime(path)
            if (not force and e is not None and e['path'] == path and e['mtime'] == mt
                    and (not e['zones'] or set(e['zones']) == want)):
                continue
            todo.append((name, cycle, source, path, mt))
    log('  barotropic KE: %d file(s) to read, %d cached'
        % (len(todo), sum(len(f) for _s, f in plan.values()) - len(todo)))

    def take(task, zones):
        name, cycle, source, path, mt = task
        caches[name][(cycle, source)] = {
            'path': path, 'mtime': mt, 'zones': {z: (b, k) for z, b, k in zones}}
        dirty.add(name)

    if todo and jobs > 1:
        from concurrent.futures import ProcessPoolExecutor
        with ProcessPoolExecutor(max_workers=min(jobs, len(todo)), initializer=_init,
                                 initargs=(area, wet, coast, coast_km)) as ex:
            for i, (task, zones) in enumerate(ex.map(_integrate, todo), 1):
                take(task, zones)
                if i % 25 == 0 or i == len(todo):
                    log('    %d/%d' % (i, len(todo)))
    elif todo:
        _init(area, wet, coast, coast_km)
        for i, task in enumerate(todo, 1):
            take(*_integrate(task))
            if i % 25 == 0 or i == len(todo):
                log('    %d/%d' % (i, len(todo)))
    # rewritten only when it changed: its mtime is what the figure's
    # freshness check reads
    for name in dirty:
        _save(cache_path(cfg, plan[name][0]), caches[name])
    return caches
