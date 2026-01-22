# helper function for strict type conversion
typeset_input_cols <- function(col_old, to_type, col_name, df_name) {
  
  # perform the conversion based on the desired type
  col_new <- switch(
    to_type,
    character = as.character(col_old),
    integer = as.numeric(col_old),
    numeric = as.numeric(col_old),
    Date = as.Date(col_old),
    logical = as.logical(col_old)
  )
  
  # identify where NAs were introduced during conversion (excluding original NAs)
  na_introduced <- is.na(col_new) & !is.na(col_old)
  
  if (any(na_introduced)) {
    # extract invalid values
    invalid_values <- unique(col_old[na_introduced])
    # limit the number of invalid values displayed
    max_display <- 5
    if (length(invalid_values) > max_display) {
      invalid_values <- c(invalid_values[1:max_display], "...and more")
    }
    # print informative error msg
    stop(
      paste0(
        "Type conversion error in table '",
        df_name,
        "', column '",
        col_name,
        "'. Invalid values: ",
        paste(invalid_values, collapse = ", ")
      )
    )
  }
  
  if (to_type == "integer") {
    non_integers <- ifelse(as.numeric(round(col_new, 0)) == col_new, FALSE, TRUE)
    if (any(non_integers)) {
      col_new <- as.integer(round(col_new, 0))
      message(paste0("Type conversion warning in table '",
                     df_name,
                     "', column '",
                     col_name,
                     "values coerced to integer by rounding."))
    }
    else {
      col_new <- as.integer(col_new)
    }
  }
  
  return(col_new)
}

# define column dtypes for all dfs
input_cols_type_list <- list(
  FarmYear = list(
    Entity_ID = "character",
    Period_Start = "Date",
    Period_End = "Date",
    Territory = "character",
    Primary_Farm_Class = "character",
    Solid_Separator_Use = "logical"
  ),
  StockRec_BirthsDeaths = list(
    Entity_ID = "character",
    Period_End = "Date",
    Month = "integer",
    StockClass = "character",
    Births = "integer",
    Deaths = "integer"
  ),
  StockRec_Movements = list(
    Entity_ID = "character",
    Period_End = "Date",
    Transaction_Date = "Date",
    StockClass = "character",
    Transaction_Type = "character",
    Stock_Count = "integer"
  ),
  StockRec_OpeningBalance = list(
    Entity_ID = "character",
    Period_End = "Date",
    StockClass = "character",
    Opening_Balance = "integer"
  ),
  SuppFeed_DryMatter = list(
    Entity_ID = "character",
    Period_End = "Date",
    Supplement = "character",
    Dry_Matter_t = "numeric",
    Beef_Allocation = "numeric",
    Dairy_Allocation = "numeric",
    Deer_Allocation = "numeric",
    Sheep_Allocation = "numeric"
  ),
  Dairy_Production = list(
    Entity_ID = "character",
    Period_End = "Date",
    Month = "integer",
    Milk_Yield_Herd_L = "numeric",
    Milk_Fat_Herd_kg = "numeric",
    Milk_Protein_Herd_kg = "numeric"
  ),
  Effluent_Structure_Use = list(
    Entity_ID = "character",
    Period_End = "Date",
    Month = "integer",
    Dairy_Shed_hrs_day = "numeric",
    Other_Structures_hrs_day = "numeric"
  ),
  Effluent_EcoPond_Treatments = list(
    Entity_ID = "character",
    Period_End = "Date",
    Treatment_Date = "Date"
  ),
  Fertiliser = list(
    Entity_ID = "character",
    Period_End = "Date",
    N_Urea_Coated_t = "numeric",
    N_Urea_Uncoated_t = "numeric",
    N_NonUrea_SyntheticFert_t = "numeric",
    N_OrganicFert_t = "numeric",
    Lime_t = "numeric",
    Dolomite_t = "numeric"
  ),
  BreedingValues = list(
    Entity_ID = "character",
    Period_End = "Date",
    StockClass = "character",
    BV_aCH4 = "numeric"
  ),
  Breed_Allocation = list(
    Entity_ID = "character",
    Period_End = "Date",
    Sector = "character",
    Breed = "character",
    Breed_Allocation = "numeric"
  )
)

# helper function to read CSV and apply typeset_input_cols()
read_and_convert_csv <- function(file_name, df_specs, df_name) {
  
  # read the CSV with all columns as character to preserve raw data
  df <- read_csv(
    file = file.path(param_input_path, file_name),
    col_types = cols(.default = "c")  # Read all columns as character
  )
  
  # convert each specified column using typeset_input_cols
  df_converted <- as_tibble(df) %>%
    mutate(across(
      .cols = names(df_specs),
      .fns = ~ typeset_input_cols(.x, df_specs[[cur_column()]], cur_column(), df_name)
    ))
  
  return(df_converted)
}

# validate param_input_path
if (!dir.exists(param_input_path)) {
  stop("The specified input path does not exist: ", param_input_path)
}

# main data loading Logic
# define required CSV files
required_csv_files <- names(input_cols_type_list)
required_csv_files <- paste0(required_csv_files, ".csv")

# check for missing CSV files
missing_files <- required_csv_files[!file.exists(file.path(param_input_path, required_csv_files))]
if (length(missing_files) > 0) {
  stop(
    "The following required CSV files are missing: ",
    paste(missing_files, collapse = ", ")
  )
}

# read and convert each CSV file using column specs
FarmYear_df <- read_and_convert_csv(
  "FarmYear.csv", 
  input_cols_type_list$FarmYear, 
  "FarmYear"
)

StockRec_BirthsDeaths_df <- read_and_convert_csv(
  "StockRec_BirthsDeaths.csv",
  input_cols_type_list$StockRec_BirthsDeaths,
  "StockRec_BirthsDeaths"
)

StockRec_Movements_df <- read_and_convert_csv(
  "StockRec_Movements.csv",
  input_cols_type_list$StockRec_Movements,
  "StockRec_Movements"
)

StockRec_OpeningBalance_df <- read_and_convert_csv(
  "StockRec_OpeningBalance.csv",
  input_cols_type_list$StockRec_OpeningBalance,
  "StockRec_OpeningBalance"
)

SuppFeed_DryMatter_df <- read_and_convert_csv(
  "SuppFeed_DryMatter.csv",
  input_cols_type_list$SuppFeed_DryMatter,
  "SuppFeed_DryMatter"
)

Dairy_Production_df <- read_and_convert_csv(
  "Dairy_Production.csv",
  input_cols_type_list$Dairy_Production,
  "Dairy_Production"
)

Effluent_Structure_Use_df <- read_and_convert_csv(
  "Effluent_Structure_Use.csv",
  input_cols_type_list$Effluent_Structure_Use,
  "Effluent_Structure_Use"
)

Effluent_EcoPond_Treatments_df <- read_and_convert_csv(
  "Effluent_EcoPond_Treatments.csv", 
  input_cols_type_list$Effluent_EcoPond_Treatments, 
  "Effluent_EcoPond_Treatments")

Fertiliser_df <- read_and_convert_csv(
  "Fertiliser.csv",
  input_cols_type_list$Fertiliser,
  "Fertiliser"
)

BreedingValues_df <- read_and_convert_csv(
  "BreedingValues.csv",
  input_cols_type_list$BreedingValues,
  "BreedingValues"
)

Breed_Allocation_df <- read_and_convert_csv(
  "Breed_Allocation.csv",
  input_cols_type_list$Breed_Allocation,
  "Breed_Allocation"
)