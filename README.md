[![MPI Logo](https://www.mpi.govt.nz/assets/themes/mpi_logo_green.png)](https://www.mpi.govt.nz/)

---

# Farm Emissions Model (FEM)

A farm emissions model for New Zealand.

## Introduction

This is the reference R implementation of the Farm Emissions Model (FEM) for estimating on-farm GHG emissions. The methodology is defined in the technical paper available from the MPI website's [Estimating On-Farm Emissions landing page](https://www.mpi.govt.nz/funding-rural-support/environment-and-natural-resources/estimating-on-farm-emissions).

The FEM methodology describes a process for estimating methane, nitrous oxide and carbon dioxide emissions from both livestock (cattle, deer and sheep) and synthetic nitrogenous fertiliser. It has been tailored to specific characteristics found in NZ agriculture.

It closely follows the Ministry for Primary Industries' national Agricultural GHG Inventory Methodology.

## How to run the FEM

### 1. Download the latest release

We recommend starting with the latest final release for the latest available year from the [releases page](https://github.com/Ministry-for-Primary-Industries/FarmEmissionsModel/releases).

### 2. Install R Environment

This codebase is built with and intended to be run on R v4.4.3. The R environment is managed with [renv](https://rstudio.github.io/renv/).

- Install R v4.4.3
- (Optional) Install RStudio and launch via `FarmEmissionsModel.Rproj`
- Run the following in the R console to install dependencies:
    ```R
    install.packages("renv")
    renv::restore()
    ```
- Note an apppropriate version of Rtools may be required to compile libraries specified in the renv lockfile. 

### 3. Add Farm Data

Farm data inputs must conform to the FEM data specification, available for download as an asset with the associated release on the [releases page](https://github.com/Ministry-for-Primary-Industries/FarmEmissionsModel/releases). A supporting data dictionary is also available here providing detailed data definitions.

Add conformant CSV or JSON data into an appropriate folder (default location: `FarmEmissionsModel/data_input/`).

We recommend starting with the example data available in `FarmEmissionsModel/data_input_example/`. This is supplied in both CSV and JSON formats.

*Note there is currently limited validation performed on input data in FEM. It is the users responsibility to apply the validation rules contained in the FEM data specification, prior to passing data through FEM.*

### 4. Run Pipeline

Run `src/run_FEM.R`

At the head of this script are configurable run parameters for setting:
- input/output folder locations and file format (CSV/JSON)
- output tables to saveout via `param_saveout_emission_tables` and `param_saveout_mitign_delta_tables`
    - if no saved outputs are desired these can be set to `FALSE` or an empty vector `c()`
    - the full lists of savable outputs are:
    ```R
    # emission tables including impacts of mitigations
    param_saveout_emission_tables = c(
        # granular, per module
        "livestock_results_granular",
        "fertiliser_results_granular",
        # summary - detailed, per module
        "smry_livestock_monthly_by_StockClass",
        "smry_livestock_monthly_by_Sector",
        "smry_livestock_annual_by_Sector",
        "smry_livestock_annual",
        "smry_fertiliser_annual",
        # summary - high level, all modules
        "smry_all_annual_by_emission_type",
        "smry_all_annual_by_gas"
        )
    
    # tables showing impacts of mitigations (difference between mitigated and unmitigated emissions)
    param_saveout_mitign_delta_tables = c(
        # granular, per module
        "livestock_results_granular_mitign_delta",
        "fertiliser_results_granular_mitign_delta",
        # summary - detailed, per module
        "smry_livestock_monthly_by_StockClass_mitign_delta",
        "smry_livestock_monthly_by_Sector_mitign_delta",
        "smry_livestock_annual_by_Sector_mitign_delta",
        "smry_livestock_annual_mitign_delta",
        "smry_fertiliser_annual_mitign_delta",
        # summary - high level, all modules
        "smry_all_annual_by_emission_type_mitign_delta",
        "smry_all_annual_by_gas_mitign_delta"
        )
    ```

    Note if a given `Entity_ID` and `Period_End` has no farm data inputs for a specific module (e.g. fertiliser or livestock), it will have no output rows in the per module tables. It will have output rows of zeros in the high level all-module summaries.

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

## Versioning

FEM's explicit versioning approach is outlined in [VERSIONING.md](https://github.com/Ministry-for-Primary-Industries/FarmEmissionsModel/blob/main/VERSIONING.md)

## License

Use or distribution of this software in any way or form indicates your acceptance of the terms and conditions set out in the included `LICENSE.txt` file.