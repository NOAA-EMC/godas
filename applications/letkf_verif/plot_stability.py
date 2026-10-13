#!/usr/bin/env python3
"""SSH cycling diagnostics: the 6-h tendency, in maps and in numbers.

What went wrong with altimetry in the past showed up first in the 6-h SSH
tendency -- background(t) minus the previous analysis, what the model does on
its own between two analyses -- as a large-scale pattern that reverses sign
from one cycle to the next. No per-cycle score sees a sign flip, and the
small-scale variances this script used to track never moved. So it now
draws the tendency and tracks four things:

  chg_rms        area-weighted RMS of the 6-h tendency
  chg_ls_rms     the same for its 5-deg block mean (the large-scale part);
                 a weather-driven tendency is ~1.5 cm and mostly large scale
  lag1           spatial correlation of the large-scale tendency with the one
                 6 h earlier: positive when the wind-driven adjustment carries
                 on, negative when the ocean is ringing
  incr_rms       area-weighted RMS of the SSH increment
  uv_deep_ratio  RMS of the u/v increment below --deep (m) over the RMS in the
                 top --shallow (m), from the mom6 increment: a geostrophic
                 increment decays with depth, so this is well below 1; above
                 1 the analysis is handing the model a barotropic transport

Per experiment with an ocean background and increment:

    figs/cycle_ssh_stability_<exp>.png       the four series, one line per region,
                                             dotted = fitted trend
    figs/ssh_tendency_<exp>.png              latest cycle: background, increment,
                                             6-h tendency, its 5-deg low-pass
    figs/ssh_tendency_strip_<exp>.png        low-pass tendency of the last 4 cycles
    ssh_stability_<exp>.csv / .json          every metric per cycle and region;
                                             the trend verdict

Regions: global plus the `corr_regions:` boxes. The report shows all three
figures and the verdict table in section 07.

Then, for every experiment together, the barotropic kinetic energy of the
background and of the increment against cycle, by depth zone (lv_bke.py):

    figs/cycle_bke.png                       BKE of background and increment,
                                             background BKE / KE
    bke_<exp>.csv                            per cycle, source and zone; a cache,
                                             so only new files are read

--jobs reads the cycles in parallel: the per-cycle files for the series
(the tendency chain itself stays sequential) and the BKE files.
"""

import argparse
import csv
import glob
import json
import os
import sys
import time

import numpy as np
import matplotlib

matplotlib.use('Agg')

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import cartopy.crs as ccrs  # noqa: E402
import cartopy.feature as cfeature  # noqa: E402
import matplotlib.dates as mdates  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
from netCDF4 import Dataset  # noqa: E402
import lv_bke as B  # noqa: E402
import lv_plot as P  # noqa: E402
from lv_common import (Fresh, Grid, corr_regions, load_config, parse_cycle,  # noqa: E402
                       region_box)

BLOCK = 20            # 1/4-deg cells per 5-deg block for the low-pass
STRIP = 4             # cycles in the tendency strip (24 h)
METRICS = ['chg_rms', 'chg_ls_rms', 'lag1', 'incr_rms', 'uv_deep_ratio']
# which direction of trend is bad, for the verdict
ADVERSE = {'chg_rms': +1, 'chg_ls_rms': +1, 'lag1': -1, 'incr_rms': +1,
           'uv_deep_ratio': +1}
LABELS = {'chg_rms': '6-h SSH tendency RMS (m): total, and 5$^\\circ$ low-pass (dashed)',
          'lag1': 'lag-6 h correlation of the low-pass tendency',
          'incr_rms': 'SSH increment RMS (m)',
          'uv_deep_ratio': 'u/v increment: deep RMS / surface RMS'}
LAND = '#e7e3db'
COAST = '#8d8878'


def read_level0(path, var):
    if path is None or not os.path.exists(path):
        return None
    with Dataset(path) as ds:
        if var not in ds.variables:
            return None
        v = ds[var]
        a = v[0, 0] if v.ndim == 4 else (v[0] if v.ndim == 3 else v[:])
        return np.ma.filled(a.astype('f8'), np.nan)


def forecast_file(exp, cycle, fhr):
    """This cycle's own forecast history at hour fhr (f000/f003/f006)."""
    d = exp.dir_for(cycle, exp.bkg.get('stem'), 'ocean') if exp.bkg.get(
        'stem') else os.path.join(exp.dir_for(cycle), 'ocean')
    for cand in ('gdas.t%sz.inst.f%03d.nc' % (cycle[8:10], fhr),):
        p = os.path.join(d, cand)
        if os.path.exists(p):
            return p
    return None


def mom6_increment(exp, cycle):
    """The increment MOM6 ingests, with u/v on model layers; falls back to
    the jedi increment, which carries the same fields."""
    hits = sorted(glob.glob(os.path.join(exp.dir_for(cycle), 'ocean',
                                         '*mom6_increment*.nc')))
    return hits[0] if hits else exp.increment(cycle, 'ocean')


def block_mean(a, n=BLOCK):
    """n x n block mean, NaN-aware."""
    ny, nx = a.shape
    b = a[:ny // n * n, :nx // n * n].reshape(ny // n, n, nx // n, n)
    with np.errstate(invalid='ignore'):
        return np.nanmean(np.nanmean(b, axis=3), axis=1)


def block_up(b, n, shape):
    """Block mean back on the full grid (nearest), for drawing."""
    a = np.repeat(np.repeat(b, n, axis=0), n, axis=1)
    out = np.full(shape, np.nan)
    out[:a.shape[0], :a.shape[1]] = a
    return out


def wstats(f, w, sel):
    ok = sel & np.isfinite(f)
    if not ok.any():
        return np.nan
    ww = w[ok]
    return float(np.sqrt(np.sum(ww * f[ok] ** 2) / ww.sum()))


def wcorr(a, b, w, sel):
    ok = sel & np.isfinite(a) & np.isfinite(b)
    if ok.sum() < 10:
        return np.nan
    ww = w[ok] / w[ok].sum()
    x, y = a[ok] - np.sum(ww * a[ok]), b[ok] - np.sum(ww * b[ok])
    sxx, syy, sxy = np.sum(ww * x * x), np.sum(ww * y * y), np.sum(ww * x * y)
    return float(sxy / np.sqrt(sxx * syy)) if sxx > 0 and syy > 0 else np.nan


def uv_deep_ratio(path, bkg_path, regions, shallow, deep):
    """RMS of the u/v increment below ``deep`` m over the RMS above
    ``shallow`` m, from a handful of levels each, as {region: ratio}. Each
    level is read once for all the regions (it used to be re-read per
    region, most of this stage's run time)."""
    nan = {r: np.nan for r in regions}
    if path is None or bkg_path is None or not os.path.exists(bkg_path):
        return nan
    with Dataset(bkg_path) as ds:
        if 'z_l' not in ds.variables:
            return nan
        z = np.asarray(ds['z_l'][:], dtype='f8')
    top = np.where(z <= shallow)[0]
    bot = np.where(z >= deep)[0]
    if top.size == 0 or bot.size == 0:
        return nan
    top = top[::max(1, top.size // 4)][:4]
    bot = bot[::max(1, bot.size // 4)][:4]
    with Dataset(path) as ds:
        if 'u' not in ds.variables or 'v' not in ds.variables:
            return nan

        def rms(levels):
            s = dict.fromkeys(regions, 0.0)
            for k in levels:
                for var in ('u', 'v'):
                    a2 = np.ma.filled(ds[var][0, k].astype('f8'), 0.0) ** 2
                    for r, sel in regions.items():
                        s[r] += float(np.sum(a2[sel]))
            out = {}
            for r, sel in regions.items():
                n = 2 * len(levels) * int(sel.sum())
                out[r] = np.sqrt(s[r] / n) if n else np.nan
            return out
        num, den = rms(bot), rms(top)
    return {r: num[r] / den[r] if den[r] > 0 else np.nan for r in regions}


# Set once per worker by _init_reader(): the region masks are a few MB each,
# too big to pickle into every task.
_REGIONS = {}


def _init_reader(regions):
    _REGIONS.clear()
    _REGIONS.update(regions)


def _read_cycle(task):
    """Worker: what one cycle contributes on its own -- surface background
    and increment, and the u/v ratio per region. Independent across cycles;
    only the tendency chain built from them in analyse() is sequential."""
    bkg_path, inc_path, field, shallow, deep = task
    bkg = read_level0(bkg_path, field)
    incr = read_level0(inc_path, field)
    if bkg is None or incr is None:
        return None
    return bkg, incr, uv_deep_ratio(inc_path, bkg_path, _REGIONS, shallow, deep)


def trend(y, hours_per_step=6.0):
    """(slope in % of mean per day, t statistic) of a linear fit vs time."""
    y = np.asarray(y, dtype='f8')
    ok = np.isfinite(y)
    if ok.sum() < 6:
        return np.nan, np.nan
    t = np.arange(len(y))[ok] * hours_per_step / 24.0
    yy = y[ok]
    A = np.column_stack([t, np.ones_like(t)])
    coef, res, _r, _s = np.linalg.lstsq(A, yy, rcond=None)
    dof = len(yy) - 2
    if dof < 1:
        return np.nan, np.nan
    resid = yy - A @ coef
    s2 = np.sum(resid ** 2) / dof
    var_slope = s2 / np.sum((t - t.mean()) ** 2)
    tstat = coef[0] / np.sqrt(var_slope) if var_slope > 0 else np.nan
    mean = np.mean(yy)
    pct = 100.0 * coef[0] / abs(mean) if mean != 0 else np.nan
    return float(pct), float(tstat)


def analyse(cfg, exp, cycles, grid, regions, field='ave_ssh', shallow=50.0,
            deep=1000.0, verbose=True, jobs=1):
    """Every metric for every cycle and region, plus the fields of the last
    STRIP cycles for the maps: (rows, maps) where maps is a list of
    (cycle, bkg, incr, chg, chg_ls). With jobs > 1 the per-cycle reads run
    in a process pool, in cycle order."""
    w = grid.area
    rows, maps = [], []
    prev_ana = prev_ls = None
    tasks = [(exp.background(c, 'ocean'), mom6_increment(exp, c), field, shallow, deep)
             for c in cycles]
    pool = None
    if jobs > 1 and len(tasks) > 1:
        from concurrent.futures import ProcessPoolExecutor
        pool = ProcessPoolExecutor(max_workers=min(jobs, len(tasks)),
                                   initializer=_init_reader, initargs=(regions,))
        reads = pool.map(_read_cycle, tasks)
    else:
        _init_reader(regions)
        reads = map(_read_cycle, tasks)
    try:
        for cycle, got in zip(cycles, reads):
            prev_ana, prev_ls = _chain(cycle, got, prev_ana, prev_ls, grid, w, regions,
                                       rows, maps, verbose)
            maps = maps[-STRIP:]
    finally:
        if pool is not None:
            pool.shutdown()
    return rows, maps


def _chain(cycle, got, prev_ana, prev_ls, grid, w, regions, rows, maps, verbose):
    """One link of the tendency chain: this cycle's metrics from its own
    reads and the previous analysis; appends to rows and maps, returns the
    new (prev_ana, prev_ls)."""
    if got is None:
        return None, None
    bkg, incr, uv = got
    ana = bkg + incr
    chg = None if prev_ana is None else np.where(grid.mask, bkg - prev_ana, np.nan)
    ls = None if chg is None else block_mean(chg)
    for rname, sel in regions.items():
        r = {'cycle': cycle, 'region': rname}
        r['incr_rms'] = wstats(incr, w, sel)
        r['chg_rms'] = wstats(chg, w, sel) if chg is not None else np.nan
        if ls is not None:
            sel_ls = block_mean(sel.astype('f8')) > 0.5
            r['chg_ls_rms'] = wstats(ls, np.ones(ls.shape), sel_ls)
            r['lag1'] = (wcorr(ls, prev_ls, np.ones(ls.shape), sel_ls)
                         if prev_ls is not None else np.nan)
        else:
            r['chg_ls_rms'] = r['lag1'] = np.nan
        r['uv_deep_ratio'] = uv[rname]
        rows.append(r)
    maps.append((cycle, bkg, incr, chg, ls))
    if verbose:
        g = rows[-len(regions)]
        print('    %s  incr rms %.4f  chg rms %s  low-pass %s  lag1 %s  '
              'uv deep/surf %s'
              % (cycle, g['incr_rms'],
                 '%.4f' % g['chg_rms'] if np.isfinite(g['chg_rms']) else '-',
                 '%.4f' % g['chg_ls_rms'] if np.isfinite(g['chg_ls_rms']) else '-',
                 '%+.2f' % g['lag1'] if np.isfinite(g['lag1']) else '-',
                 '%.2f' % g['uv_deep_ratio'] if np.isfinite(g['uv_deep_ratio']) else '-'),
              flush=True)
    return ana, ls


def verdict(rows, regions):
    """Trend per region and metric: % of the mean per day, t, adverse flag."""
    out = []
    for rname in regions:
        for m in METRICS:
            y = np.array([r[m] for r in rows if r['region'] == rname], dtype='f8')
            pct, tstat = trend(y)
            out.append({'region': rname, 'metric': m, 'pct_per_day': pct,
                        't': tstat, 'mean': float(np.nanmean(y)) if np.any(
                            np.isfinite(y)) else np.nan,
                        'flag': bool(np.isfinite(tstat) and abs(tstat) > 3
                                     and np.sign(pct) == ADVERSE[m])})
    return out


def figure(rows, regions, exp_name, cfg, fname):
    names = list(regions)
    col = P.color_map(names)
    panels = ['chg_rms', 'lag1', 'incr_rms', 'uv_deep_ratio']
    fig, axes = plt.subplots(2, 2, figsize=(12, 7), squeeze=False)
    axes = axes.ravel()
    drawn = sorted({r['cycle'] for r in rows})
    for ax, m in zip(axes, panels):
        for rname in names:
            y = np.array([r[m] for r in rows if r['region'] == rname], dtype='f8')
            x = np.arange(len(y))
            ax.plot(x, y, '-', lw=1.2, color=col[rname], label=rname)
            if m == 'chg_rms':
                y2 = np.array([r['chg_ls_rms'] for r in rows if r['region'] == rname],
                              dtype='f8')
                ax.plot(x, y2, '--', lw=0.9, color=col[rname])
            ok = np.isfinite(y)
            if ok.sum() >= 6:
                coef = np.polyfit(x[ok], y[ok], 1)
                ax.plot(x, np.polyval(coef, x), ':', lw=1, color=col[rname])
        ax.set_title(LABELS[m], fontsize=9.5, color=P.INK)
        ax.tick_params(labelsize=7.5)
        P.tidy(ax)
        if m == 'lag1':
            ax.axhline(0, color=P.MUTED, lw=0.8, ls=(0, (4, 3)))
        if m == 'uv_deep_ratio':
            ax.axhline(1, color=P.MUTED, lw=0.8, ls=(0, (4, 3)))
        step = max(1, len(drawn) // 8)
        ax.set_xticks(np.arange(0, len(drawn), step))
        ax.set_xticklabels([c[4:6] + '-' + c[6:8] + ' ' + c[8:10] + 'Z'
                            for c in drawn[::step]], rotation=30, fontsize=7)
    axes[0].legend(fontsize=8, frameon=False)

    def when(c):
        return '%s-%s-%s %sZ' % (c[:4], c[4:6], c[6:8], c[8:10])
    fig.suptitle('%s: SSH cycling, %s to %s (dotted: fitted trend)'
                 % (exp_name, when(drawn[0]), when(drawn[-1])),
                 fontsize=12, color=P.INK)
    fig.tight_layout(rect=[0, 0, 1, 0.96])
    return P.save(fig, cfg, fname, dpi=110, quiet=True)


def _map(ax, grid, fld, lo, hi, cmap, title, stride=2):
    lon = grid.lon180[::stride, ::stride]
    lat = grid.lat[::stride, ::stride]
    f = np.where(grid.mask, fld, np.nan)[::stride, ::stride]
    pm = ax.pcolormesh(lon, lat, np.ma.masked_invalid(f), cmap=cmap, vmin=lo,
                       vmax=hi, shading='nearest', rasterized=True,
                       transform=ccrs.PlateCarree())
    ax.add_feature(cfeature.LAND, facecolor=LAND, zorder=2)
    ax.coastlines(resolution='110m', linewidth=0.35, color=COAST, zorder=3)
    ax.set_global()
    ax.set_title(title, fontsize=9, color=P.INK)
    with np.errstate(invalid='ignore'):
        ax.text(0.01, 0.02, 'rms %.3f  max|.| %.3f' % (
            np.sqrt(np.nanmean(f ** 2)), np.nanmax(np.abs(f))),
            transform=ax.transAxes, fontsize=7, color=P.INK2,
            bbox=dict(fc='white', ec='none', alpha=0.7, pad=1.5))
    return pm


def tendency_maps(maps, grid, exp_name, cfg, fname, vmax):
    """Latest cycle: background, increment, 6-h tendency, low-pass tendency."""
    cycle, bkg, incr, chg, ls = maps[-1]
    lim = (cfg.get('map_limits') or {})
    bkg_lim = (lim.get('ocean') or {}).get('ave_ssh_k0')
    bkg_lim = tuple(bkg_lim) if bkg_lim else (-2.0, 1.0)
    proj = ccrs.PlateCarree(central_longitude=-120)
    fig, axes = plt.subplots(2, 2, figsize=(12, 6.2), squeeze=False,
                             subplot_kw=dict(projection=proj))
    axes = axes.ravel()
    panels = [(bkg, 'background SSH (m)', bkg_lim, P.SEQ_BKG),
              (incr, 'analysis increment (m)', (-vmax, vmax), P.DIVERGING),
              (chg, '6-h tendency: background minus previous analysis (m)',
               (-vmax, vmax), P.DIVERGING),
              (None if ls is None else block_up(ls, BLOCK, bkg.shape),
               '6-h tendency, 5$^\\circ$ low-pass (m)', (-vmax, vmax), P.DIVERGING)]
    for ax, (fld, title, (lo, hi), cmap) in zip(axes, panels):
        if fld is None:
            ax.set_global()
            ax.text(0.5, 0.5, 'no previous analysis', ha='center', va='center',
                    transform=ax.transAxes, fontsize=9, color=P.MUTED)
            ax.set_title(title, fontsize=9, color=P.INK)
            continue
        pm = _map(ax, grid, fld, lo, hi, cmap, title)
        cb = fig.colorbar(pm, ax=ax, fraction=0.03, pad=0.02)
        cb.outline.set_visible(False)
        cb.ax.tick_params(labelsize=6.5)
    fig.suptitle('%s: SSH at %s-%s-%s %sZ' % (exp_name, cycle[:4], cycle[4:6],
                                              cycle[6:8], cycle[8:10]),
                 fontsize=12, color=P.INK)
    fig.subplots_adjust(left=0.02, right=0.98, top=0.9, bottom=0.03,
                        wspace=0.1, hspace=0.18)
    return P.save(fig, cfg, fname, dpi=100, quiet=True)


def tendency_strip(maps, grid, exp_name, cfg, fname, vmax):
    """Low-pass 6-h tendency of the last STRIP cycles side by side: a sign
    that flips from panel to panel is the ocean ringing."""
    have = [m for m in maps if m[4] is not None]
    if not have:
        return None
    proj = ccrs.PlateCarree(central_longitude=-120)
    fig, axes = plt.subplots(1, len(have), figsize=(4.2 * len(have), 2.9),
                             squeeze=False, subplot_kw=dict(projection=proj))
    for ax, (cycle, bkg, _i, _c, ls) in zip(axes.ravel(), have):
        _map(ax, grid, block_up(ls, BLOCK, bkg.shape), -vmax, vmax, P.DIVERGING,
             '%s-%s %sZ' % (cycle[4:6], cycle[6:8], cycle[8:10]))
    fig.suptitle('%s: 5$^\\circ$ low-pass 6-h SSH tendency, last %d cycles (m, $\\pm$%.2f)'
                 % (exp_name, len(have), vmax), fontsize=11, color=P.INK)
    fig.subplots_adjust(left=0.01, right=0.99, top=0.82, bottom=0.02, wspace=0.05)
    return P.save(fig, cfg, fname, dpi=100, quiet=True)


BKE_ZONES = {'shelf': 'shelf (< %g m)' % B.SHELF,
             'slope': 'slope (%g-%g m)' % (B.SHELF, B.SLOPE),
             'deep': 'deep (> %g m)' % B.SLOPE, 'global': 'global'}
BKE_ROWS = [('background', 'bke', 'background BKE (PJ)'),
            ('increment', 'bke', 'increment BKE (PJ)'),
            ('background', 'frac', 'background BKE / KE')]


def bke_figure(cfg, caches, zones, coast_km, fname='cycle_bke.png'):
    """Rows: background BKE, increment BKE, background BKE/KE; columns: the
    zones; one line per experiment."""
    col = P.color_map([e.name for e in cfg['experiments']])
    labels = dict(BKE_ZONES, coast='within %g km of the coast' % coast_km)
    fig, axes = plt.subplots(len(BKE_ROWS), len(zones), squeeze=False, sharex=True,
                             figsize=(3.2 * len(zones), 2.5 * len(BKE_ROWS) + 0.5))
    for i, (source, what, ylabel) in enumerate(BKE_ROWS):
        for j, z in enumerate(zones):
            ax = axes[i][j]
            for name, cache in caches.items():
                pts = sorted((c, v['zones'][z]) for (c, s), v in cache.items()
                             if s == source and z in v['zones'])
                if not pts:
                    continue
                y = [b if what == 'bke' else (b / k if k > 0 else np.nan)
                     for _c, (b, k) in pts]
                ax.plot([parse_cycle(c) for c, _v in pts], y, '-', lw=1.1,
                        color=col.get(name, P.INK2), label=name)
            if i == 0:
                ax.set_title(labels[z], fontsize=9.5, color=P.INK)
            if j == 0:
                ax.set_ylabel(ylabel, fontsize=8.5, color=P.INK2)
            ax.tick_params(labelsize=7.5)
            P.tidy(ax)
    for ax in axes[-1]:
        loc = mdates.AutoDateLocator(minticks=3, maxticks=6)
        ax.xaxis.set_major_locator(loc)
        ax.xaxis.set_major_formatter(mdates.ConciseDateFormatter(loc))
    # one legend for the figure: a panel can miss an experiment (no history,
    # so no background rows)
    seen = {}
    for ax in axes.ravel():
        for h, lab in zip(*ax.get_legend_handles_labels()):
            seen.setdefault(lab, h)
    names = [n for n in col if n in seen]          # registry order
    if names:
        fig.legend([seen[n] for n in names], names, loc='upper right', ncol=len(names),
                   fontsize=8.5, frameon=False)
    fig.suptitle('Barotropic kinetic energy against cycle: the background valid at '
                 'the cycle and the increment MOM6 ingests', fontsize=12, color=P.INK,
                 x=0.01, ha='left')
    fig.tight_layout(rect=[0, 0, 1, 0.94])
    return P.save(fig, cfg, fname, dpi=110, quiet=True)


def bke_stage(cfg, exps, cycles, grid, fresh, jobs=1, coast_km=100.0, force=False):
    """Barotropic KE of every experiment's background and increment: bring the
    per-experiment caches up to date (only new or changed files are read,
    --jobs-way), then redraw the figure if any of them moved."""
    t = time.time()
    plan = {}
    for e in exps:
        files = {}
        for c in cycles:
            for source, path in (('background', e.background(c, 'ocean')),
                                 ('increment', mom6_increment(e, c))):
                if path and os.path.exists(path):
                    files[(c, source)] = path
        if files:
            plan[e.name] = (P.slug(e.name), files)
    if not plan:
        print('  barotropic KE: no ocean background or increment on disk -- skipped')
        return None
    coast = None
    if coast_km:
        coast, src = B.coast_distance(exps, cycles, grid.shape)
        print('  barotropic KE: coastal band from %s' % src if src else
              '  barotropic KE: no gridspec with distance_from_coast -- no coastal zone')
    caches = B.update(cfg, plan, grid.area, grid.mask, coast, coast_km, jobs=jobs,
                      force=force, log=lambda s: print(s, flush=True))
    inputs = [B.cache_path(cfg, slug) for slug, _f in plan.values()] + [B.__file__]
    params = {'cycles': cycles, 'experiments': list(plan),
              'coast_km': coast_km if coast is not None else None}
    if fresh.ok('bke', inputs, params):
        print('  barotropic KE: figure up to date, skipped')
        return None
    out = bke_figure(cfg, caches, B.zone_names(coast), coast_km)
    fresh.record('bke', inputs, params, [out])
    print('  barotropic KE: %s in %.0fs' % (os.path.basename(out), time.time() - t),
          flush=True)
    return out


def stability_regions(cfg, grid):
    """global + the corr_regions boxes (small, fixed, made for this)."""
    regions = {'global': grid.mask.copy()}
    for r in corr_regions(cfg):
        lat0, lat1, lon0, lon1 = region_box(r)
        sel = grid.mask & (grid.lat >= lat0) & (grid.lat < lat1)
        if lon0 is not None:
            sel &= ((grid.lon180 >= lon0) & (grid.lon180 < lon1) if lon0 <= lon1
                    else (grid.lon180 >= lon0) | (grid.lon180 < lon1))
        regions[r['name']] = sel
    return regions


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('config', nargs='?', default=None)
    ap.add_argument('--config', dest='config_opt', default=None)
    ap.add_argument('--root', default=None)
    ap.add_argument('--outdir', default=None)
    ap.add_argument('--cache', action='append', default=None)
    ap.add_argument('--experiment', action='append', default=None,
                    help='restrict to these experiments (default: every one '
                         'with an ocean background and increment)')
    ap.add_argument('--field', default='ave_ssh')
    ap.add_argument('--vmax', type=float, default=0.1,
                    help='colour range (+/- m) for the increment and tendency '
                         'maps; the increment limit in map_limits is too wide '
                         'for a tendency (default 0.1)')
    ap.add_argument('--shallow', type=float, default=50.0,
                    help='top of the column for the u/v ratio (m)')
    ap.add_argument('--deep', type=float, default=1000.0,
                    help='below this depth is "deep" for the u/v ratio (m)')
    ap.add_argument('--jobs', type=int, default=1,
                    help='processes for the per-cycle reads, and for the '
                         'barotropic-KE files (default 1)')
    ap.add_argument('--coast-km', type=float, default=100.0,
                    help='width of the coastal zone of the barotropic KE, km; '
                         '0 for none (default 100)')
    ap.add_argument('--force', action='store_true',
                    help='redraw everything and re-read every barotropic-KE file')
    a = ap.parse_args(argv)
    a.config = a.config or a.config_opt
    t_all = time.time()
    cfg = load_config(a.config, a.root, a.outdir, a.cache)
    cycles = [str(c) for c in cfg['cycles']]
    grid = Grid(cfg['grid'])
    regions = stability_regions(cfg, grid)
    os.makedirs(cfg['figs'], exist_ok=True)
    vmax = a.vmax
    fresh = Fresh(cfg, 'stability', force=a.force, script=__file__)
    exps = [e for e in cfg['experiments']
            if not a.experiment or e.name in a.experiment]
    print('SSH stability: %d cycle(s), regions %s' % (len(cycles), list(regions)),
          flush=True)
    for e in exps:
        have = [c for c in cycles if e.background(c, 'ocean')
                and e.increment(c, 'ocean')]
        if len(have) < 3:
            print('  %s: %d cycle(s) with background+increment -- skipped'
                  % (e.name, len(have)), flush=True)
            continue
        slug = P.slug(e.name)
        # The inputs are a hundred files; the last cycle's stand for them
        # all, with the cycle list as a parameter, so a new cycle or a
        # regenerated last cycle redraws and nothing else does.
        inputs = [e.background(have[-1], 'ocean'), e.increment(have[-1], 'ocean'),
                  __file__]
        params = {'cycles': have, 'field': a.field, 'vmax': vmax,
                  'shallow': a.shallow, 'deep': a.deep,
                  'regions': sorted(regions)}
        if fresh.ok('exp:%s' % e.name, inputs, params):
            print('  %s: up to date, skipped' % e.name, flush=True)
            continue
        t = time.time()
        print('  %s: %d cycle(s)' % (e.name, len(have)), flush=True)
        rows, maps = analyse(cfg, e, have, grid, regions, a.field, a.shallow, a.deep,
                             jobs=a.jobs)
        if not rows:
            fresh.record('exp:%s' % e.name, inputs, params, [])
            continue
        csv_path = os.path.join(cfg['outdir'], 'ssh_stability_%s.csv' % slug)
        with open(csv_path, 'w', newline='') as fh:
            wr = csv.DictWriter(fh, fieldnames=['cycle', 'region'] + METRICS)
            wr.writeheader()
            wr.writerows(rows)
        v = verdict(rows, regions)
        json_path = os.path.join(cfg['outdir'], 'ssh_stability_%s.json' % slug)
        clean = [{k: (None if isinstance(x, float) and not np.isfinite(x)
                      else x) for k, x in row.items()} for row in v]
        with open(json_path, 'w') as fh:
            json.dump({'experiment': e.name, 'cycles': have, 'field': a.field,
                       'verdict': clean}, fh, indent=1)
        outs = [figure(rows, regions, e.name, cfg, 'cycle_ssh_stability_%s.png' % slug),
                tendency_maps(maps, grid, e.name, cfg, 'ssh_tendency_%s.png' % slug, vmax),
                tendency_strip(maps, grid, e.name, cfg,
                               'ssh_tendency_strip_%s.png' % slug, vmax),
                csv_path, json_path]
        fresh.record('exp:%s' % e.name, inputs, params, [o for o in outs if o])
        flagged = [x for x in v if x['flag']]
        print('  %s: 3 figures, %d flagged trend(s)%s in %.0fs'
              % (e.name, len(flagged),
                 ' (%s)' % ', '.join('%s/%s' % (x['region'], x['metric'])
                                     for x in flagged[:6]) if flagged else '',
                 time.time() - t), flush=True)
    bke_stage(cfg, exps, cycles, grid, fresh, jobs=a.jobs, coast_km=a.coast_km,
              force=a.force)
    fresh.save()
    print('done in %.0fs' % (time.time() - t_all), flush=True)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
