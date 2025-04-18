# Section 1: General Preproc ----------------------------------------------

# Note Fertiliser_df is ready for pipeline step 3.2 by end of this section

# add primary key to all farm data tables, and strip source cols where possible

parse_Entity__PeriodEnd <- function(in_df, retain_Period_End) {
  
  out_df <- in_df %>%
    mutate(Entity__PeriodEnd = paste(Entity_ID, Period_End, sep = "__")) %>%
    select(Entity__PeriodEnd, everything())
  
  if (retain_Period_End == TRUE) {
    
    out_df <- out_df %>%
      select(-Entity_ID)
    
  } else {
    
    out_df <- out_df %>%
      select(-Entity_ID, -Period_End)
    
  }
  
}

# core and stock rec tables require Period_End col for date processing, others do not

FarmYear_df <- parse_Entity__PeriodEnd(FarmYear_df, retain_Period_End = TRUE)
StockRec_BirthsDeaths_df <- parse_Entity__PeriodEnd(StockRec_BirthsDeaths_df, retain_Period_End = TRUE)
StockRec_Movements_df <- parse_Entity__PeriodEnd(StockRec_Movements_df, retain_Period_End = TRUE)
StockRec_OpeningBalance_df <- parse_Entity__PeriodEnd(StockRec_OpeningBalance_df, retain_Period_End = TRUE)

Fertiliser_df <- parse_Entity__PeriodEnd(Fertiliser_df, retain_Period_End = FALSE)
Dairy_Production_df <- parse_Entity__PeriodEnd(Dairy_Production_df, retain_Period_End = FALSE)
SuppFeed_DryMatter_df <- parse_Entity__PeriodEnd(SuppFeed_DryMatter_df, retain_Period_End = FALSE)
SuppFeed_SectoralAllocation_df <- parse_Entity__PeriodEnd(SuppFeed_SectoralAllocation_df, retain_Period_End = FALSE)

# general prep of FarmYear_df

FarmYear_df <- FarmYear_df %>%
  # lookup Pasture_Region and Primary_Production_Region into FarmYear_df
  inner_join(lookup_location_mapping_df, by = "Territory")

# Section 2: Livestock preproc and additional farm data validation --------

helper_StockClass_by_Sector_df <- lookup_assumedParameters_df %>%
  select(Sector, StockClass) %>%
  distinct()

# livestock-specific prep of FarmYear_df

FarmYear_df <- FarmYear_df %>%
  # add lookup slope factors
  left_join(lookup_slopeFactors_df,
            by = c("Production_Region", "Primary_Farm_Class")) %>%
  # force slope to flat for dairy & horticultural farm classes
  mutate(
    N_Urine_Flattish_pct = case_when(
      Primary_Farm_Class %in% c("Dairy", "Cropping", "Orchard", "Vineyard") ~ 1,
      TRUE ~ N_Urine_Flattish_pct
    ),
    N_Urine_Steep_pct = case_when(
      Primary_Farm_Class %in% c("Dairy", "Cropping", "Orchard", "Vineyard") ~ 0,
      TRUE ~ N_Urine_Steep_pct
    )
  )

# prep Dairy_Production_df

Dairy_Production_df <- Dairy_Production_df %>%
  mutate(StockClass = "Milking Cows Mature")

# Create StockLedger

parse_StockLedger <- function() {
  
  # transforms Opening_Balance and Births_Deaths df structures to mirror Movements,
  # to combine and use as a foundation for creating the Entity__PeriodEnd's stock rec
  
  OpeningBalance_as_Movements_df <- StockRec_OpeningBalance_df %>%
    select(everything(), Stock_Count = Opening_Balance) %>%
    inner_join(
      FarmYear_df %>% select(Entity__PeriodEnd, Period_Start),
      by ="Entity__PeriodEnd"
    ) %>%
    mutate(Transaction_Type = "Opening Balance", Transaction_Date = Period_Start) %>% select(
      "Entity__PeriodEnd",
      "Period_End",
      "Transaction_Date",
      "StockClass",
      "Transaction_Type",
      "Stock_Count"
    )
  
  # convert monthly inputs of births and deaths into mid-month transactions
  
  BirthsDeaths_as_Movements_df <- StockRec_BirthsDeaths_df %>%
    mutate(
      Year = case_when(
        Month <= month(Period_End) ~ year(Period_End),
        TRUE ~ year(Period_End) - 1
      ),
      MonthDays = days_in_month(make_date(Year, Month, 1))
    ) %>% pivot_longer(
      cols = c(Births, Deaths),
      names_to = "Transaction_Type",
      values_to = "Stock_Count"
    ) %>% mutate(
      # map births to mid-month, deaths to month-end
      Transaction_Date = case_when(
        Transaction_Type == "Births" ~ make_date(Year, Month, MonthDays / 2),
        Transaction_Type == "Deaths" ~ make_date(Year, Month, MonthDays),
        TRUE ~ NA_Date_
      )
    ) %>%
    select(
      "Entity__PeriodEnd",
      "Period_End",
      "Transaction_Date",
      "StockClass",
      "Transaction_Type",
      "Stock_Count"
    ) %>% filter(
      Stock_Count > 0 # may be able to remove filter once input validation improved
    )
  
  # define negative stock rec movements:
  
  negative_movements_list <- c("Sale", "Deaths", "Transfer Out")
  
  # combine all stock rec dfs:
  
  out_df <- bind_rows(
    StockRec_Movements_df,
    BirthsDeaths_as_Movements_df,
    OpeningBalance_as_Movements_df
  ) %>%
    mutate(
      Stock_Count = case_when(
        Transaction_Type %in% negative_movements_list ~ -Stock_Count,
        TRUE ~ Stock_Count
      )
    )
  
  return(out_df)
  
}

StockLedger_df <- parse_StockLedger()

# national avg birthdates by farm by stockclasses present on farm

newborn_stockclasses_by_entity_df <- StockLedger_df %>%
  filter(StockClass %in% stockClassList_newborns) %>%
  select(Entity__PeriodEnd, Period_End, StockClass) %>%
  distinct() %>%
  mutate(
    AnnualPeriod_Start = Period_End - years(1) + days(1) # must force annual period
  ) %>%
  inner_join(helper_StockClass_by_Sector_df, by = "StockClass") %>%
  inner_join(
    lookup_newborn_birthdate_milk_df %>% select(Sector, BirthMonth_National, BirthDay_National),
    by = "Sector"
  ) %>%
  mutate(
    BirthYear = case_when(
      BirthMonth_National <= month(Period_End) ~ year(Period_End),
      TRUE ~ year(Period_End) - 1
    ),
    BirthDate_National = make_date(BirthYear, BirthMonth_National, BirthDay_National)
  )

# newborns: derive birthdates

# newborns: derive birthdates - part 1: StockClasses with on-farm births (birthed)

birthdates_birthed_df <- StockLedger_df %>%
  filter(Transaction_Type == "Births") %>%
  group_by(Entity__PeriodEnd, StockClass)

# warning is raised in summarise below if the above filter resolves to no rows. Results test fine. Suppressing:
birthdates_birthed_df <- suppressWarnings(
  birthdates_birthed_df %>%
  summarise(
    BirthDate_Farm_mean = round_date(as_date(
      sum(as.numeric(Transaction_Date) * Stock_Count) / sum(Stock_Count)
    ), unit = "day"),
    BirthDate_Farm_max = max(Transaction_Date),
    Stock_Count = sum(Stock_Count),
    .groups = "drop"
  )
)

# transfer all birthed newborn births/deaths/movements dates before Farm_Birthdate_max to Farm_Birthdate_mean

StockLedger_df <- StockLedger_df %>%
  left_join(
    birthdates_birthed_df %>% select(-Stock_Count),
    by = c("Entity__PeriodEnd", "StockClass")
  ) %>%
  arrange(Entity__PeriodEnd, StockClass, Transaction_Date) %>%
  mutate(
    Transaction_Date_adj = case_when(
      Transaction_Date <= BirthDate_Farm_max ~ BirthDate_Farm_mean,
      TRUE ~ Transaction_Date
    ),
  )

# newborns: derive birthdates - part 2: StockClasses without on-farm births (i.e. purchased or transferred in)

birthdates_birthless_df <- StockLedger_df %>%
  filter(StockClass %in% stockClassList_newborns &
           is.na(BirthDate_Farm_mean)) %>%
  group_by(Entity__PeriodEnd, StockClass)

# warning is raised in summarise below if the above filter resolves to no rows. Results test fine. Suppressing:
birthdates_birthless_df <- suppressWarnings(
  birthdates_birthless_df %>%
  summarise(Birthless_Date_min = min(Transaction_Date),
            .groups = "drop", .)
)

birthdates_birthless_df <- birthdates_birthless_df %>%
  inner_join(
    newborn_stockclasses_by_entity_df %>% select(Entity__PeriodEnd, StockClass, BirthDate_National),
    by = c("Entity__PeriodEnd", "StockClass")
  ) %>%
  mutate(
    BirthDate_Farm_mean = case_when(
      Birthless_Date_min < BirthDate_National ~ Birthless_Date_min,
      TRUE ~ BirthDate_National
    )
  )

# combine birthed and birthless newborn birthdates

birthdates_all_df <- bind_rows(birthdates_birthed_df, birthdates_birthless_df) %>%
  select(Entity__PeriodEnd, StockClass, BirthDate_Farm_mean)

StockLedger_agg_df <- StockLedger_df %>%
  group_by(Entity__PeriodEnd, StockClass, Date = Transaction_Date_adj) %>%
  summarise(Stock_Change = sum(Stock_Count), .groups = "drop")

# Create Daily Stock Rec

FarmYear_dates_df <- FarmYear_df %>%
  select(Entity__PeriodEnd, Period_Start, Period_End) %>%
  rowwise() %>%
  mutate(Date = list(seq(
    from = Period_Start, to = Period_End, by = "day"
  )))

# for each unique Entity__PeriodEnd and StockClass in StockLedger_agg_df, create a daily stock rec:

StockRec_daily_df <- StockLedger_agg_df %>%
  select(Entity__PeriodEnd, StockClass) %>%
  distinct() %>%
  left_join(
    FarmYear_dates_df %>% select(Entity__PeriodEnd, Date),
    by = "Entity__PeriodEnd"
  ) %>%
  unnest(Date) %>%
  left_join(StockLedger_agg_df,
            by = c("Entity__PeriodEnd", "StockClass", "Date")) %>%
  mutate(Stock_Change = replace_na(Stock_Change, 0)) %>%
  group_by(Entity__PeriodEnd, StockClass) %>%
  mutate(StockCount_day = cumsum(Stock_Change))

# basic validation check for negative stock counts
# this occurs when input data for a farm has a stock outflow transaction (sale, death etc.) which
# exceeds current stock count. If this occurs, fix your input data

assert_that(
  all(StockRec_daily_df$StockCount_day >= 0),
  msg = (
    "Negative stock counts detected in StockRec_daily_df. To troubleshoot run: StockRec_daily_df %>% filter(StockCount_day < 0)"
  )
)

StockRec_monthly_df <- StockRec_daily_df %>%
  mutate(YearMonth = floor_date(Date, unit = "month"), ) %>%
  # calculate monthly average StockCount
  group_by(Entity__PeriodEnd, YearMonth, StockClass) %>%
  summarise(
    StockCount_mean = mean(StockCount_day),
    .groups = "drop"
    ) %>% mutate(
      Month = month(YearMonth),
      MonthDays = days_in_month(YearMonth)
    ) %>% filter(
      # we needed zero counts (if present) to calculate StockCount_mean above, now they can be removed
      StockCount_mean > 0 
    )

# preprocessing: newborns

# run only if newborns present on farm, check via birthdates_all_df

if (nrow(birthdates_all_df) > 0) {
  newborn_LW_LWG_milk_daily_df <- birthdates_all_df %>%
    mutate(Period_End = ymd(substr(
      Entity__PeriodEnd,
      nchar(Entity__PeriodEnd) - 9,
      nchar(Entity__PeriodEnd)
    ))) %>% rowwise() %>%
    mutate(Date = list(seq(BirthDate_Farm_mean, Period_End, by = "day"))) %>%
    unnest(Date) %>%
    inner_join(lookup_newborn_daily_LWG_profiles_df, by = "StockClass") %>%
    inner_join(
      lookup_newborn_birthdate_milk_df %>% select(-BirthMonth_National, -BirthDay_National),
      by = "Sector"
    ) %>% mutate(
      day_of_life = as.numeric(1 + Date - BirthDate_Farm_mean),
      # handle lambs stage2 growth rate (half from 174 days, ref AIM):
      LWG_kg_day = case_when(
        StockClass == "Lambs" & day_of_life > 173 ~ 0.5 * LWG_kg_day,
        TRUE ~ LWG_kg_day
      ),
      Days_Newborn_Fed_OnlyMilk = case_when(
        day_of_life <= Days_Newborn_Fed_OnlyMilk_annual ~ 1,
        TRUE ~ 0
      ),
      Days_Newborn_Fed_Milk = case_when(
        day_of_life <= Days_Newborn_Fed_Milk_annual ~ 1,
        TRUE ~ 0
      ),
      Milk_Newborn_kg = case_when(
        Days_Newborn_Fed_Milk == 1 ~ Milk_Newborn_kg_annual / Days_Newborn_Fed_Milk_annual,
        TRUE ~ 0
      ),
      MilkPowder_Newborn_kg = case_when(
        Days_Newborn_Fed_Milk == 1 ~ MilkPowder_Newborn_kg_annual / Days_Newborn_Fed_Milk_annual,
        TRUE ~ 0
      )
    ) %>% group_by(Entity__PeriodEnd, StockClass) %>% mutate(
      Cumulative_LWG_kg = cumsum(LWG_kg_day),
      LW_kg_day = BW_kg + Cumulative_LWG_kg
    ) %>% ungroup() %>% select(-Sector)
  
  newborn_LW_LWG_milk_monthly_df <- newborn_LW_LWG_milk_daily_df %>%
    mutate(Month = month(Date), MonthDays = days_in_month(Date)) %>%
    group_by(Entity__PeriodEnd, StockClass, Month) %>%
    summarise(
      LW_start_kg = first(LW_kg_day),
      LW_end_kg = last(LW_kg_day),
      LW_kg = mean(c(LW_start_kg, LW_end_kg)),
      LWG_kg = sum(LWG_kg_day),
      Days_Newborn_Fed_OnlyMilk = sum(Days_Newborn_Fed_OnlyMilk),
      ME_Z0_pct = Days_Newborn_Fed_OnlyMilk / min(MonthDays, max(day_of_life)),
      Days_Newborn_Fed_Milk = sum(Days_Newborn_Fed_Milk),
      Milk_Newborn_kg = sum(Milk_Newborn_kg),
      MilkPowder_Newborn_kg = sum(MilkPowder_Newborn_kg),
      Milk_Fat_pct = max(Milk_Fat_pct),
      Milk_Protein_pct = max(Milk_Protein_pct),
      MilkPowder_Protein_pct = max(MilkPowder_Protein_pct),
      .groups = "drop"
    ) %>%
    mutate(
      Milk_Fat_pct = case_when(
        Days_Newborn_Fed_Milk > 0 ~ Milk_Fat_pct,
        TRUE ~ NA
      ),
      Milk_Protein_pct = case_when(
        Days_Newborn_Fed_Milk > 0 ~ Milk_Protein_pct,
        TRUE ~ NA
      )
    ) %>%
    select(-LW_start_kg, -LW_end_kg)
  
} else {
  
  # if no newborns, init empty newborn_LW_LWG_milk_monthly_df
  newborn_LW_LWG_milk_monthly_df <- tibble(
    Entity__PeriodEnd = character(),
    StockClass = character(),
    Month = integer(),
    LW_kg = double(),
    LWG_kg = double(),
    Days_Newborn_Fed_OnlyMilk = double(),
    ME_Z0_pct = double(),
    Days_Newborn_Fed_Milk = double(),
    Milk_Newborn_kg = double(),
    MilkPowder_Newborn_kg = double(),
    Milk_Fat_pct = double(),
    Milk_Protein_pct = double(),
    MilkPowder_Protein_pct = double()
  )
  
}

livestock_precalc_df <- StockRec_monthly_df %>%
  inner_join(
    FarmYear_df %>% select(
      Entity__PeriodEnd,
      Production_Region,
      Pasture_Region,
      Primary_Farm_Class,
      N_Urine_Flattish_pct,
      N_Urine_Steep_pct
    ),
    by = "Entity__PeriodEnd"
  ) %>%
  inner_join(lookup_assumedParameters_df, by = c("StockClass", "Month")) %>%
  left_join(
    # left join req'd as right df only contains newborns
    newborn_LW_LWG_milk_monthly_df,
    by = c("Entity__PeriodEnd", "Month", "StockClass"),
    # prioritize non-NA values from newborn_LW_LWG_milk_monthly_df:
    suffix = c("", ".y")
  ) %>% mutate(
    LW_kg = case_when(
      is.na(LW_kg.y) ~ LW_kg,
      TRUE ~ LW_kg.y
    ),
    LWG_kg = case_when(
      is.na(LWG_kg.y) ~ LWG_kg,
      TRUE ~ LWG_kg.y
    ),
    Milk_Newborn_kg = case_when(
      is.na(Milk_Newborn_kg.y) ~ Milk_Newborn_kg,
      TRUE ~ Milk_Newborn_kg.y
    ),
    MilkPowder_Newborn_kg = case_when(
      is.na(MilkPowder_Newborn_kg.y) ~ MilkPowder_Newborn_kg,
      TRUE ~ MilkPowder_Newborn_kg.y
    ),
    Days_Newborn_Fed_Milk = case_when(
      is.na(Days_Newborn_Fed_Milk.y) ~ Days_Newborn_Fed_Milk,
      TRUE ~ Days_Newborn_Fed_Milk.y
    ),
    Milk_Fat_pct = case_when(
      is.na(Milk_Fat_pct.y) ~ Milk_Fat_pct,
      TRUE ~ Milk_Fat_pct.y
    ),
    Milk_Protein_pct = case_when(
      is.na(Milk_Protein_pct.y) ~ Milk_Protein_pct,
      TRUE ~ Milk_Protein_pct.y
    ),
    MilkPowder_Protein_pct = case_when(
      is.na(MilkPowder_Protein_pct.y) ~ MilkPowder_Protein_pct,
      TRUE ~ MilkPowder_Protein_pct.y
    )
  ) %>% # drop all cols ending in .y:
  select(-ends_with(".y")) %>% # left join dairy production
  left_join(
    Dairy_Production_df %>% select(
      Entity__PeriodEnd,
      Month,
      StockClass,
      Milk_Yield_Herd_L,
      Milk_Fat_Herd_kg,
      Milk_Protein_Herd_kg
    ),
    by = c("Entity__PeriodEnd", "Month", "StockClass")
  ) %>% # force slope to flat for mature milking cows (for edge case farms where Primary_Farm_Class is not Dairy)
  mutate(
    N_Urine_Flattish_pct = case_when(
      StockClass == "Milking Cows Mature" ~ 1,
      TRUE ~ N_Urine_Flattish_pct
    ),
    N_Urine_Steep_pct = case_when(
      StockClass == "Milking Cows Mature" ~ 0,
      TRUE ~ N_Urine_Steep_pct
    )
  ) %>% # final select for re-ordering of cols
  select(
    # core
    "Entity__PeriodEnd",
    "Production_Region",
    "Pasture_Region",
    "Primary_Farm_Class",
    # time
    "YearMonth",
    "Month",
    "MonthDays",
    # basic stock info
    "Sector",
    "StockClass",
    "StockCount_mean",
    # common params
    "Age",
    "Sex",
    "SRW_kg",
    "LW_kg",
    "LWG_kg",
    # other production
    "Velvet_Yield_kg",
    "Wool_Yield_kg",
    # pregnancy
    "Days_Pregnant",
    "Trimester_Factor",
    "Reproduction_Rate",
    "FWG_kg",
    "Milk_Mother_kg",
    # newborn milk related
    "Days_Newborn_Fed_Milk",
    "Days_Newborn_Fed_OnlyMilk",
    "ME_Z0_pct",
    "Milk_Newborn_kg",
    "MilkPowder_Newborn_kg",
    "Milk_Fat_pct",
    "Milk_Protein_pct",
    "MilkPowder_Protein_pct",
    # national avg diet
    "ME_Diet_AIM",
    "DMD_pct_Diet_AIM",
    "N_pct_Diet_AIM",
    # slope
    "N_Urine_Flattish_pct",
    "N_Urine_Steep_pct",
    # dairy production
    "Milk_Yield_Herd_L",
    "Milk_Fat_Herd_kg",
    "Milk_Protein_Herd_kg"
  )