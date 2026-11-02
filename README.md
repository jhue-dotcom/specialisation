# Replication package

This directory contains the Stata code, experimental records, intermediate datasets, and generated tables and figures for the associated study. The package was assembled on 1st Nov 2026.

## Contents

| Location | Contents |
|---|---|
| `raw_data/` | 18 original z-Tree Excel exports (`.xls`) used as the source data. |
| `cleaneddata/` | Intermediate and analysis-ready Stata datasets (`.dta`), plus the project-specific `estpost_clustered_diff.ado`. |
| `outputv2/` | 32 generated LaTeX table fragments (`.tex`). |
| `figuresv2/` | 20 generated PNG figures. |
| `01-gendatav4.do` | Imports the z-Tree Excel exports and creates merged intermediate datasets. |
| `02-cleandata.do` | Cleans the merged data and creates `cleaneddata/data_full.dta`. |
| `03-main_analysisv3.do` | Produces the main-analysis tables and figures. |
| `04-Supplementaryv2.do` | Produces supplementary tables and figures. |
| `genFMM.do`, `genFMMplot.do` | Estimates and plots the finite-mixture-model analysis. |
| `genSimpleTypes.do`, `genSimpleTypesplot.do` | Creates and plots the minimum-distance type classification. |

The supplied outputs are the pre-generated files in `outputv2/` and `figuresv2/`. The source tree contains 18 raw `.xls` files, 14 `.dta` files, 8 `.do` files, one `.ado` file, 32 `.tex` files, and 20 `.png` files.

## Software requirements

Replication requires Stata and the following user-written commands:

- `ztree2stata` (to import the z-Tree exports)
- `estout` (provides `eststo`, `estpost`, and `esttab`)
- `reghdfe`
- `xlincom`
- `grc1leg`

The scripts also invoke the `stcolor` graphics scheme. Install the required commands/scheme in Stata before running the code, using the version appropriate to your Stata installation. The package includes the project-specific `cleaneddata/estpost_clustered_diff.ado`; retain it in that location or add its directory to Stata's adopath.

## Reproducing the analyses

1. Copy the entire directory to a writable local location. Keep the folder structure unchanged.
2. Start one Stata session from the project root. The scripts share Stata globals and stored estimates, so do not run them in separate fresh sessions.
3. Run the scripts in this order:

```stata
cd "<absolute path to folder>"
do 01-gendatav4.do

cd "<absolute path to folder>"
do 02-cleandata.do

cd "<absolute path to folder>"
do 03-main_analysisv3.do

cd "<absolute path to folder>"
do 04-Supplementaryv2.do
```

`01-gendatav4.do` imports the raw z-Tree exports and writes intermediate datasets to `cleaneddata/`; `02-cleandata.do` creates `cleaneddata/data_full.dta`. The analysis scripts overwrite their named table and figure outputs in `outputv2/` and `figuresv2/`.

## Notes on reproducibility

- The package does **not** include a master runner, package-version lockfile, or automated test suite. Execution therefore depends on the installed Stata version and user-written package versions.
- The generated LaTeX files are table fragments rather than standalone compilable documents.

## Citation and contact

Please cite the associated paper when using this package.
