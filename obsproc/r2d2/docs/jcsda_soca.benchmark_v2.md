## `jcsda_soca` `benchmark_v2`

The tables below contain descriptions of the files contained in the `jcsda_soca` `benchmark_v2` shared database on Orion.

### Insitu

| File descriptor | Variables | Processing level | Instruments | Platforms  | Time coverage | Spacial coverage | Provider | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| insitu_hgodas | T, S | L1 | Too many to list | TAO, PIRATA, RAMA, Argo, XBT, CTD | 2015-01-01 2016-12-31 | global | GODAE | superobed by CPC (Travis)|
| sst_drifter| SST (sub-skin temperature) | L2 (6 hourly interpolated) | Argos and GPS tracked | drifting buoys |  1980-01-01 2020-09-30 | global | GDP |  |

### Satellite Altimeter

| File descriptor | Variables | Processing level | Altimeter | Satellite  | Time coverage | Max. Latitude | Repeat cycle [days] | Provider | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| adt_c2 | ADT | L2 | SIRAL | Cryosat-2  | 2015-01-01 2016-12-31 | 88 | 369 exact, 30 pseudo | RADS |
| adt_j2 | ADT | L2 | Poseidon-3 | Jason-2 | 2015-01-01 2016-12-31 | 66 | 10 |RADS |
| adt_sa | ADT | L2 | ALtiKa | SARAL | 2015-01-01 2016-12-31 | 82 | 35 | RADS |
| adt_coperl4 | ADT | L4 | All | All | 2015-01-01 2016-12-30 | Global | N/A | Copernicus | Passive observations, for diagnostic only |
| icefb_gdr | sea ice freeboard | L2 | SIRAL | Cryosat-2  | 2015-01-01 2016-12-31 | 88 | 369 exact, 30 pseudo | ESA | GDR (LRM+SAR+SARIN) consolidated ice products over an orbit |

ADT: absolute dynamic topography

### Satellite MW

| File descriptor | Variables | Processing level | Instrument | Satellite  | Time coverage | Max. Latitude | Repeat cycle [days] | Provider | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| radiance_smap | brightness temperature (4 channels) | L1 | SAR L-band | GPM  | 2015-04-01 2016-12-31 |  | |  |  |
| sss_smap | SSS | L2 | SAR L-band | GPM  | 2015-04-01 2016-12-31 |  | | RSS |  |
| radiance_gmi | brightness temperature (13 channels) | L1 | GMI | GPM  | 2015-01-01 2015-12-31 |  | |  | missing 2016 |
| icec_emc | sea ice concentration | L2 | SSMI/SSMIS | F-16 F-17 F-18 | 2015-01-01 2015-12-31 | | | EMC | |


### Satellite IR

| File descriptor | Variables | Processing level | Instrument | Satellite  | Time coverage | Max. Latitude | Repeat cycle [days] | Provider | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| sst_metopa | SST | L3 | AVHRR | MetOp-A | 2015-01-01 2016-12-31 | | | GRHSST | superobed by CPC (Travis)|
| sst_noaa19 | SST | L3 | AVHRR | NOAA-19 | 2015-01-01 2016-12-31 | | | GRHSST | superobed by CPC (Travis)|
| radiance_metopa | brightness temperature (3 channels) | L1 | AVHRR | MetOp-A | 2015-04-01 2015-04-30 | | |  | prepared by Hamideh |
