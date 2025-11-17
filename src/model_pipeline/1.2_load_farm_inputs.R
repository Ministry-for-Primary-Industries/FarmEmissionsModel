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
    SupplementName = "character",
    Dry_Matter_t = "numeric"
  ),
  SuppFeed_SectoralAllocation = list(
    Entity_ID = "character",
    Period_End = "Date",
    Sector = "character",
    SuppFeed_Allocation = "numeric"
  ),
  Dairy_Production = list(
    Entity_ID = "character",
    Period_End = "Date",
    Month = "integer",
    Milk_Yield_Herd_L = "numeric",
    Milk_Fat_Herd_kg = "numeric",
    Milk_Protein_Herd_kg = "numeric"
  ),
  Effluent_Management = list(
    Entity_ID = "character",
    Period_End = "Date",
    Month = "integer",
    Dairy_Shed_hr = "numeric",
    Other_Structures_hr = "numeric"
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

# helper function to convert JSON dataframes using typeset_input_cols
convert_json_df <- function(df_data, df_specs, df_name) {
  converted_df <- as_tibble(df_data) %>%
    mutate(across(
      .cols = names(df_specs),
      .fns = ~ typeset_input_cols(.x, df_specs[[cur_column()]], cur_column(), df_name)
    ))
  
  return(converted_df)
}

# validate param_input_data_format
if (!param_input_data_format %in% c("csv", "json")) {
  stop("Invalid input data format. Choose either 'csv' or 'json'.")
}

# validate param_input_path
if (!dir.exists(param_input_path)) {
  stop("The specified input path does not exist: ", param_input_path)
}

# main data loading Logic
if (param_input_data_format == "csv") {
  
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
  FarmYear_df <- read_and_convert_csv("FarmYear.csv", input_cols_type_list$FarmYear, "FarmYear")
  
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
  
  SuppFeed_SectoralAllocation_df <- read_and_convert_csv(
    "SuppFeed_SectoralAllocation.csv",
    input_cols_type_list$SuppFeed_SectoralAllocation,
    "SuppFeed_SectoralAllocation"
  )
  
  Dairy_Production_df <- read_and_convert_csv(
    "Dairy_Production.csv",
    input_cols_type_list$Dairy_Production,
    "Dairy_Production"
  )
  
  Effluent_Management_df <- read_and_convert_csv(
    "Effluent_Management.csv",
    input_cols_type_list$Effluent_Management,
    "Effluent_Management"
  )
  
  Fertiliser_df <- read_and_convert_csv("Fertiliser.csv",
                                        input_cols_type_list$Fertiliser,
                                        "Fertiliser")
  
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
  
} else if (param_input_data_format == "json") {
  # define JSON file name
  json_file <- file.path(param_input_path, "Farm_Data.json")
  
  # check if JSON file exists
  if (!file.exists(json_file)) {
    stop("JSON file not found: ", json_file)
  }
  
  # Read JSON file
  combined_data <- tryCatch({
    fromJSON(json_file)
  }, error = function(e) {
    stop("FAILED reading JSON file of farm data: ", e$message)
  })
  
  # list of dfs expected in JSON
  expected_json_dfs <- names(input_cols_type_list)
  
  # check if all expected df are present in JSON
  missing_json_dfs <- expected_json_dfs[!expected_json_dfs %in% names(combined_data)]
  if (length(missing_json_dfs) > 0) {
    stop(
      "The following dataframes are missing in the JSON file: ",
      paste(missing_json_dfs, collapse = ", ")
    )
  }
  
  # convert each df from JSON using col specs
  FarmYear_df <- convert_json_df(combined_data$FarmYear,
                                 input_cols_type_list$FarmYear,
                                 "FarmYear")
  
  StockRec_BirthsDeaths_df <- convert_json_df(
    combined_data$StockRec_BirthsDeaths,
    input_cols_type_list$StockRec_BirthsDeaths,
    "StockRec_BirthsDeaths"
  )
  
  StockRec_Movements_df <- convert_json_df(
    combined_data$StockRec_Movements,
    input_cols_type_list$StockRec_Movements,
    "StockRec_Movements"
  )
  
  StockRec_OpeningBalance_df <- convert_json_df(
    combined_data$StockRec_OpeningBalance,
    input_cols_type_list$StockRec_OpeningBalance,
    "StockRec_OpeningBalance"
  )
  
  SuppFeed_DryMatter_df <- convert_json_df(
    combined_data$SuppFeed_DryMatter,
    input_cols_type_list$SuppFeed_DryMatter,
    "SuppFeed_DryMatter"
  )
  
  SuppFeed_SectoralAllocation_df <- convert_json_df(
    combined_data$SuppFeed_SectoralAllocation,
    input_cols_type_list$SuppFeed_SectoralAllocation,
    "SuppFeed_SectoralAllocation"
  )
  
  Dairy_Production_df <- convert_json_df(
    combined_data$Dairy_Production,
    input_cols_type_list$Dairy_Production,
    "Dairy_Production"
  )
  
  Effluent_Management_df <- convert_json_df(
    combined_data$Effluent_Management,
    input_cols_type_list$Effluent_Management,
    "Effluent_Management"
  )
  
  Fertiliser_df <- convert_json_df(combined_data$Fertiliser,
                                   input_cols_type_list$Fertiliser,
                                   "Fertiliser")
  
  BreedingValues_df <- convert_json_df(
    combined_data$BreedingValues,
    input_cols_type_list$BreedingValues,
    "BreedingValues"
  )
  
  Breed_Allocation_df <- convert_json_df(
    combined_data$Breed_Allocation,
    input_cols_type_list$Breed_Allocation,
    "Breed_Allocation"
  )
  
}
