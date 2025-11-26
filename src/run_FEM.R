# FEM orchestration script

# configure run parameters ------------------------------------------------

param_input_path = "data_input" # folder where farm data is located
param_input_data_format = "csv" # csv or json
param_output_path = "data_output" # this will be created if it doesn't exist
param_output_data_format = "csv" # csv or json

# set output tables to saveout, refer to README
param_saveout_emission_tables = c(
  "smry_livestock_annual",
  "smry_all_annual_by_emission_type",
  "smry_all_annual_by_gas"
)
param_saveout_mitign_delta_tables = c(
  "smry_livestock_annual_mitign_delta",
  "smry_all_annual_by_emission_type_mitign_delta",
  "smry_all_annual_by_gas_mitign_delta"
)
param_saveout_tables = c(param_saveout_emission_tables, param_saveout_mitign_delta_tables)

# load R env --------------------------------------------------------------

suppressPackageStartupMessages(library(assertthat))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(lubridate))
suppressPackageStartupMessages(library(purrr))
suppressPackageStartupMessages(library(readr))
suppressPackageStartupMessages(library(tidyr))

# run pipeline -------------------------------------------------------------

# Step 1: Load farm data conforming to FEM data spec and static inputs (equations and lookup tables)
# - validates all tables are fed to the model
# - and all columns have correct names and data types
# - further validation to come (single column rules as per data spec)

source(file.path("src", "model_pipeline", "1.1_load_static_inputs.R"))
source(file.path("src", "model_pipeline", "1.2_load_farm_inputs.R"))

# Step 2: Prepare farm data for ingestion by emissions modules
# - validates derived daily stock rec does not contain negative values
# - further validation to come (complex rules as per data spec)

source(file.path("src", "model_pipeline", "2_preprocessing.R"))

# Step 3: Run modules and produce granular outputs

source(file.path("src", "model_pipeline", "3.1_livestock.R"))
source(file.path("src", "model_pipeline", "3.2_fertiliser.R"))

# Step 4: Summarise outputs

source(file.path("src", "model_pipeline", "4_summary_outputs.R"))

# Step 5: Saveout results
# - as configured by run parameters

source(file.path("src", "model_pipeline", "5_saveout.R"))