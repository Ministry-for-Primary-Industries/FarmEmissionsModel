[![MPI Logo](https://www.mpi.govt.nz/assets/themes/mpi_logo_green.png)](https://www.mpi.govt.nz/)

---

# Farm Emissions Model (FEM)

A farm emissions model for New Zealand.

## Introduction

This is the reference R implementation of the Farm Emissions Model (FEM) for estimating on-farm GHG emissions. The methodology is defined in the technical paper available from the MPI website's [Estimating On-Farm Emissions landing page](https://www.mpi.govt.nz/funding-rural-support/environment-and-natural-resources/estimating-on-farm-emissions).

The FEM methodology describes a process for estimating methane, nitrous oxide and carbon dioxide emissions from both livestock (cattle, deer and sheep) and synthetic nitrogenous fertiliser. It has been tailored to specific characteristics found in NZ agriculture.

It closely follows the Ministry for Primary Industries' national [Agricultural GHG Inventory Methodology](https://www.mpi.govt.nz/dmsdocument/13906/direct) (currently v10 2024-04).

## How to run the FEM

### 1. Clone this Repository

Refer to GitHub documentation if required.

### 2. Install R Environment

This codebase is built with and intended to be run on R v4.4.2. The R environment is managed with [renv](https://rstudio.github.io/renv/).

- Install R v4.4.2
- (Optional) Install RStudio and launch via `FarmEmissionsModel.Rproj`
- Run the following in the R console to install dependencies:
    ```R
    install.packages("renv")
    renv::restore()
    ```

### 3. Add Lookup Tables

Static lookup tables containing parameter values used by FEM are provided on the [MPI website in a zip archive](https://www.mpi.govt.nz/dmsdocument/66681) "Click to download lookup tables").

Extract the archive into the repository's root directory such that filepaths follow a structure of: `FarmEmissionsModel/FEM_lookups/{version}/lookup_{x}.csv`.

### 4. Add Farm Data

Farm data inputs must conform to the [FEM data specification](https://www.mpi.govt.nz/dmsdocument/67533).

Add conformant CSV or JSON data into an appropriate folder (default location: `FarmEmissionsModel/data_input/`).

We recommend initially starting with our [example data](https://www.mpi.govt.nz/dmsdocument/67536).

*Note there is currently limited validation performed on input data but the majority of anticipated logic is described in the Data Specification. In future we intend for run_FEM.R to perform this validation and output error logs.*

### 5. Run Pipeline

Run `src/run_FEM.R`

At the head of this script are configurable run parameters for setting:
- input/output folder locations and file format (CSV/JSON)
- whether granular results are saved in the output folder
- whether summary results are saved to the output folder and the level of summarisation

## FEM Equations

Scientific audiences may be particularly interested in the R code that implements the equations prescribed in the FEM methodology.

To cover all use cases we supply this in 3 formats:

1.  `FEM_equations.Rmd` is the **original** format, containing the R code with helpful markdown commentary throughout. This is the format we recommend for exploring via IDE.
2.  [`FEM_equations.md` renders appropriately in a web browser](https://github.com/Ministry-for-Primary-Industries/FarmEmissionsModel/blob/main/FEM_equations.md). **This is the format we recommend for exploring via github.com**.
3.  `src/FEM_equations.R` is markdown-stripped and intended for **production use**. This is the format called by `src/run_FEM.R`.

*The R code is the same across all formats with the .md and .R files generated from the .Rmd.*

## Contributing

We encourage raising any code issues via Github and welcome community pull requests to address any discovered code quality issues. In time we will provide guidelines for contributing.

Science or policy questions concerning the methodology should be directed to [info@mpi.govt.nz](mailto:info@mpi.govt.nz?subject=Farm%20Emissions%20Method%20question).

## License

Use or distribution of this software in any way or form indicates your acceptance of the terms and conditions set out in the included `LICENSE.txt` file.