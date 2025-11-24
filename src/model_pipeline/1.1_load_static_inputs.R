# load equations

source(file.path("src", "FEM_equations.R"))

# load lookup tables

lookup_assumedParameters_df <- read_csv(file.path(
  "src",
  "lookups",
  "lookup_assumedParameters.csv"
),
  col_types=list(
    Month = col_integer(),
    Sector = col_character(),
    StockClass = col_character(),
    Age = col_double(),
    Sex = col_character(),
    SRW_kg = col_double(),
    LW_kg = col_double(),
    LWG_kg = col_double(),
    Velvet_Yield_kg = col_double(),
    Wool_Yield_kg = col_double(),
    Days_Pregnant = col_double(),
    Trimester_Factor = col_double(),
    Reproduction_Rate = col_double(),
    FWG_kg = col_double(),
    Days_Newborn_Fed_Milk = col_double(),
    Milk_Mother_kg = col_double(),
    Milk_Newborn_kg = col_double(),
    MilkPowder_Newborn_kg = col_double(),
    Milk_Fat_pct = col_double(),
    Milk_Protein_pct = col_double(),
    MilkPowder_Protein_pct = col_double(),
    ME_Diet_AIM = col_double(),
    DMD_pct_Diet_AIM = col_double(),
    N_pct_Diet_AIM = col_double()
  )
)

lookup_nutrientProfile_pasture_df <- read_csv(file.path(
  "src",
  "lookups",
  "lookup_nutrientProfile_pasture.csv"
),
  col_types = list(
    Pasture_Region = col_character(),
    Month = col_integer(),
    Sector = col_character(),
    ME_Pasture = col_double(),
    DMD_pct_Pasture = col_double(),
    N_pct_Pasture = col_double()
  )
)

lookup_nutrientProfile_supplements_df <- read_csv(file.path(
  "src",
  "lookups",
  "lookup_nutrientProfile_supplements.csv"
),
  col_types = list(
    Supplement = col_character(),
    ME_Supp = col_double(),
    DMD_pct_Supp = col_double(),
    N_pct_Supp = col_double(),
    Feed_Utilisation_pct = col_double()
  )
)

lookup_newborn_daily_LWG_profiles_df <- read_csv(file.path(
  "src",
  "lookups",
  "lookup_newborn_daily_LWG_profiles.csv"
),
  col_types = list(
    Sector = col_character(),
    StockClass = col_character(),
    BW_kg = col_double(),
    LWG_kg_day = col_double()
  )
)

lookup_newborn_birthdate_milk_df <- read_csv(file.path(
  "src",
  "lookups",
  "lookup_newborn_birthdate_milk.csv"
),
  col_types = list(
    Sector = col_character(),
    BirthMonth_National = col_integer(),
    BirthDay_National = col_integer(),
    Days_Newborn_Fed_OnlyMilk_annual = col_integer(),
    Days_Newborn_Fed_Milk_annual = col_integer(),
    Milk_Newborn_kg_annual = col_double(),
    MilkPowder_Newborn_kg_annual = col_double(),
    Milk_Fat_pct = col_double(),
    Milk_Protein_pct = col_double(),
    MilkPowder_Protein_pct = col_double()
  )
)

lookup_slopeFactors_df <- read_csv(file.path(
  "src",
  "lookups",
  "lookup_slopeFactors.csv"
),
  col_types = list(
    Production_Region = col_character(),
    Primary_Farm_Class = col_character(),
    N_Urine_Flattish_pct = col_double(),
    N_Urine_Steep_pct = col_double()
  )
)

lookup_location_mapping_df <- read_csv(
  file.path(
    "src",
    "lookups",
    "lookup_location_mapping.csv"
  ),
  col_select = c("Territory", "Pasture_Region", "Production_Region"),
  col_types = list(
    Territory = col_character(),
    Pasture_Region = col_character(),
    Production_Region = col_character()
  )
)

lookup_breed_lw_factor_df <- read_csv(
  file.path(
    "src",
    "lookups",
    "lookup_breed_lw_factors.csv"
  ),
  col_select = c("Breed", "Breed_LW_factor"),
  col_types = list(
    Breed = col_character(),
    Breed_LW_factor = col_double()
  )
)
