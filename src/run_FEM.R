# FEM orchestration script

# configure run parameters ------------------------------------------------

param_input_path = "data_input" # folder where farm data is located
param_input_data_format = "csv" # csv or json
param_output_path = "data_output" # this will be created if it doesn't exist
param_output_data_format = "csv" # csv or json

param_saveout_granular_calculation_data = FALSE # TRUE or FALSE
param_summarise_mode = "highLevel-only" # off / detailed-only / highLevel-only / all
param_saveout_summary_data = TRUE # TRUE or FALSE (TRUE requires an active param_summarise_mode)

# load R env --------------------------------------------------------------

library(assertthat)
library(dplyr)
library(jsonlite)
library(lubridate)
library(purrr)
library(readr)
library(stringr)
library(tidyr)

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
# - as configured by run parameters

source(file.path("src", "model_pipeline", "4_summary_outputs.R"))

# Step 5: Saveout results
# - as configured by run parameters

source(file.path("src", "model_pipeline", "5_saveout.R"))