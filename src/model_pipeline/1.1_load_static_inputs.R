# load equations

source(file.path("src", "FEM_equations.R"))

# load lookup tables

lookup_assumedParameters_df <- read_csv(file.path(
  "FEM_lookups",
  "lookup_assumedParameters.csv"
))

lookup_nutrientProfile_pasture_df <- read_csv(file.path(
  "FEM_lookups",
  "lookup_nutrientProfile_pasture.csv"
))

lookup_nutrientProfile_supplements_df <- read_csv(file.path(
  "FEM_lookups",
  "lookup_nutrientProfile_supplements.csv"
))

lookup_newborn_daily_LWG_profiles_df <- read_csv(file.path(
  "FEM_lookups",
  "lookup_newborn_daily_LWG_profiles.csv"
))

lookup_newborn_birthdate_milk_df <- read_csv(file.path(
  "FEM_lookups",
  "lookup_newborn_birthdate_milk.csv"
))

lookup_slopeFactors_df <- read_csv(file.path(
  "FEM_lookups",
  "lookup_slopeFactors.csv"
))

lookup_location_mapping_df <- read_csv(
  file.path("FEM_lookups", "lookup_location_mapping.csv"),
  col_select = c("Territory", "Pasture_Region", "Production_Region")
)
