[![MPI Logo](https://www.mpi.govt.nz/assets/themes/mpi-dark-logo.png)](https://www.mpi.govt.nz/)

---

# Farm Emissions Model (FEM)

A farm emissions model for New Zealand.

## Features

This is the reference R implementation of the Farm Emissions Model (FEM) for estimating on-farm GHG emissions. The methodology is defined in the technical paper available from the MPI website's [Estimating On-Farm Emissions landing page](https://www.mpi.govt.nz/funding-rural-support/environment-and-natural-resources/estimating-on-farm-emissions).

The FEM methodology describes a process for estimating methane, nitrous oxide and carbon dioxide emissions from both livestock (cattle, deer and sheep) and synthetic nitrogenous fertiliser. It has been tailored to specific characteristics found in NZ agriculture.

It closely follows the Ministry for Primary Industries' national [Agricultural GHG Inventory Methodology](https://www.mpi.govt.nz/dmsdocument/13906/direct) (currently v10 2024-04).

## Getting Started

### FEM Equations

The primary component of our initial release is FEM_equations. This is made available in three formats:

1.  `FEM_equations.Rmd` is the **original** format, containing the R code with helpful markdown commentary throughout. This is the format we recommend for exploring via IDE.
2.  `FEM_equations.md` renders the above for the web. **This is the format we recommend for exploring via github.com**.
3.  `src/FEM_equations.R` is markdown-stripped and intended to be called by other scripts in an appropriate R environment. This is the format we recommend for **production use**.

*The R code is the same across all formats with the .md and .R files generated from the .Rmd.*

The current iteration of the codebase does not contain scripts to ingest farm data inputs to execute calculations. This is under development. More specifically:

`FEM_equations.R` is intended to be used together with `run_FEM.R` [under development] which:

-   reads in farm-level input data conforming to the FEM farm data specification [under development].

-   reads in various lookup tables contained in `FEM_lookups/` (see [Lookup Tables](#Lookup-Tables)).

-   calls the various functions contained in `FEM_equations.R`, adding their outputs to columns of a dataframe.

### Lookup Tables

Static lookup tables containing parameter values used by FEM are provided on the [MPI website in a zip archive](https://www.mpi.govt.nz/dmsdocument/66681-Farm-Emissions-Model-Zip-file "Click to download lookup tables"). After cloning this repository, extract the archive into the repository's root directory such that filepaths follow a structure of: `FarmEmissionsModel/FEM_lookups/{version}/lookup_{x}.csv`.

### R Environment

This codebase is built with and intended to be run on R v4.4.2.

The R environment is managed with [renv](https://rstudio.github.io/renv/) and can be restored from the lockfile with `renv::restore()`.

## Contributing

We encourage raising any code issues via Github and welcome community pull requests to address any discovered code quality issues. In time we will provide guidelines for contributing.

Science or policy questions concerning the methodology should be directed to [info@mpi.govt.nz](mailto:info@mpi.govt.nz?subject=Farm%20Emissions%20Method%20question).

## License

Use or distribution of this software in any way or form indicates your acceptance of the terms and conditions set out in the included `LICENSE.txt` file.
