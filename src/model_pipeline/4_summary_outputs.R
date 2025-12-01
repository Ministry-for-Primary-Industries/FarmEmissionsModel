# Section 1: Detailed Summaries -------------------------------------------

# note summary outputs are not per animal but to the level of granularity,
# - e.g. monthly_by_StockClass

summarise_livestock_monthly_by_StockClass <- function(df, calc_delta) {
  
  if(calc_delta) {
    out_df <- df %>%
      mutate(
        CH4_Digestion_kg = CH4_Enteric_kg * StockCount_mean,
        CH4_Effluent_kg = (CH4_Effluent_Lagoon_kg + CH4_Effluent_SolidS_kg) * StockCount_mean,
        CH4_Digestion_excl_lm_genes_kg = CH4_Enteric_excl_lm_genes_kg * StockCount_mean,
        CH4_Effluent_excl_solids_kg = CH4_Effluent_Lagoon_excl_solids_kg * StockCount_mean,
        CH4_Effluent_excl_ecopond_kg = (CH4_Effluent_Lagoon_excl_ecopond_kg + CH4_Effluent_SolidS_kg) * StockCount_mean,
        CH4_Digestion_LMGenes_delta_kg = CH4_Digestion_kg - CH4_Digestion_excl_lm_genes_kg,
        CH4_Effluent_SolidSep_delta_kg = CH4_Effluent_kg - CH4_Effluent_excl_solids_kg,
        CH4_Effluent_EcoPond_delta_kg = CH4_Effluent_kg - CH4_Effluent_excl_ecopond_kg
      ) %>% 
      select(
        Entity__PeriodEnd,
        YearMonth,
        Sector,
        StockClass,
        StockCount_mean,
        CH4_Digestion_LMGenes_delta_kg,
        CH4_Effluent_SolidSep_delta_kg,
        CH4_Effluent_EcoPond_delta_kg
      )
  } else {
    out_df <- df %>%
      mutate(
        # calculate farmer-targeted emission categories
        CH4_Digestion_kg = CH4_Enteric_kg * StockCount_mean,
        CH4_DungUrine_kg = CH4_Pasture_Dung_kg * StockCount_mean,
        CH4_Effluent_kg = (CH4_Effluent_Lagoon_kg + CH4_Effluent_SolidS_kg) * StockCount_mean,
        N2O_DungUrine_kg = (
          N2O_Pasture_Urine_Direct_kg + N2O_Pasture_Dung_Direct_kg +
            N2O_Pasture_Urine_Leach_kg + N2O_Pasture_Dung_Leach_kg +
            N2O_Pasture_Urine_Volat_kg + N2O_Pasture_Dung_Volat_kg
        ) * StockCount_mean,
        N2O_Effluent_kg = ( # note we include spread on pasture with N2O_Effluent_kg
          N2O_Effluent_Lagoon_Volat_kg + 
            N2O_Effluent_SolidS_Direct_kg + N2O_Effluent_SolidS_Leach_kg + N2O_Effluent_SolidS_Volat_kg +
            N2O_Effluent_Spread_Direct_kg + N2O_Effluent_Spread_Leach_kg + N2O_Effluent_Spread_Volat_kg
        ) * StockCount_mean
      ) %>% select(
        Entity__PeriodEnd,
        YearMonth,
        Sector,
        StockClass,
        StockCount_mean,
        CH4_Digestion_kg,
        CH4_DungUrine_kg,
        CH4_Effluent_kg,
        N2O_DungUrine_kg,
        N2O_Effluent_kg
      )
  }
  
  return(out_df)
  
}

summarise_livestock_monthly_by_Sector <- function(df, calc_delta) {
  
  if(calc_delta) {
    out_df <- df %>%
      group_by(Entity__PeriodEnd, YearMonth, Sector) %>%
      summarise(
        CH4_Digestion_LMGenes_delta_kg = sum(CH4_Digestion_LMGenes_delta_kg),
        CH4_Effluent_SolidSep_delta_kg = sum(CH4_Effluent_SolidSep_delta_kg),
        CH4_Effluent_EcoPond_delta_kg = sum(CH4_Effluent_EcoPond_delta_kg),
        .groups = "drop"
      )
  } else {
    out_df <- df %>%
      group_by(Entity__PeriodEnd, YearMonth, Sector) %>%
      summarise(
        CH4_Digestion_kg = sum(CH4_Digestion_kg),
        CH4_DungUrine_kg = sum(CH4_DungUrine_kg),
        CH4_Effluent_kg = sum(CH4_Effluent_kg),
        N2O_DungUrine_kg = sum(N2O_DungUrine_kg),
        N2O_Effluent_kg = sum(N2O_Effluent_kg),
        .groups = "drop"
      )
  }
  
  return(out_df)
  
}

summarise_livestock_annual_by_Sector <- function(df, calc_delta) {
  
  if(calc_delta) {
    out_df <- df %>%
      group_by(Entity__PeriodEnd, Sector) %>%
      summarise(
        CH4_Digestion_LMGenes_delta_kg = sum(CH4_Digestion_LMGenes_delta_kg),
        CH4_Effluent_SolidSep_delta_kg = sum(CH4_Effluent_SolidSep_delta_kg),
        CH4_Effluent_EcoPond_delta_kg = sum(CH4_Effluent_EcoPond_delta_kg),
        .groups = "drop"
      )
  } else {
    out_df <- df %>%
      group_by(Entity__PeriodEnd, Sector) %>%
      summarise(
        CH4_Digestion_kg = sum(CH4_Digestion_kg),
        CH4_DungUrine_kg = sum(CH4_DungUrine_kg),
        CH4_Effluent_kg = sum(CH4_Effluent_kg),
        N2O_DungUrine_kg = sum(N2O_DungUrine_kg),
        N2O_Effluent_kg = sum(N2O_Effluent_kg),
        .groups = "drop"
      )
  }
  
  
  return(out_df)
  
}

summarise_livestock_annual <- function(df, calc_delta) {
  
  if(calc_delta) {
    out_df <- df %>%
      group_by(Entity__PeriodEnd) %>%
      summarise(
        CH4_Digestion_LMGenes_delta_kg = sum(CH4_Digestion_LMGenes_delta_kg),
        CH4_Effluent_SolidSep_delta_kg = sum(CH4_Effluent_SolidSep_delta_kg),
        CH4_Effluent_EcoPond_delta_kg = sum(CH4_Effluent_EcoPond_delta_kg),
        .groups = "drop"
      )
  } else {
    out_df <- df %>%
      group_by(Entity__PeriodEnd) %>%
      summarise(
        CH4_Digestion_kg = sum(CH4_Digestion_kg),
        CH4_DungUrine_kg = sum(CH4_DungUrine_kg),
        CH4_Effluent_kg = sum(CH4_Effluent_kg),
        N2O_DungUrine_kg = sum(N2O_DungUrine_kg),
        N2O_Effluent_kg = sum(N2O_Effluent_kg),
        .groups = "drop"
      )
  }
  
  return(out_df)
  
}

summarise_fertiliser_annual <- function(df, calc_delta) {
  
  if(calc_delta) {
    out_df <- df %>%
      mutate(
        N2O_SynthFert_kg = (
          N2O_SynthFert_Direct_t + N2O_SynthFert_Leach_t + N2O_SynthFert_Volat_t
        ) * 1000,
        N2O_SynthFert_excl_ui_kg = (
          N2O_SynthFert_Direct_t + N2O_SynthFert_Leach_t + N2O_SynthFert_Volat_excl_ui_t
        ) * 1000,
        N2O_SynthFert_UI_delta_kg = N2O_SynthFert_kg - N2O_SynthFert_excl_ui_kg
      ) %>%
      select(Entity__PeriodEnd, N2O_SynthFert_UI_delta_kg)
  } else {
    out_df <- df %>%
      mutate(
        N2O_SynthFert_kg = (
          N2O_SynthFert_Direct_t + N2O_SynthFert_Leach_t + N2O_SynthFert_Volat_t
        ) * 1000,
        CO2_SynthFert_kg = CO2_SynthFert_t * 1000,
        N2O_OrganicFert_Direct_kg = N2O_OrganicFert_Direct_t * 1000,
        CO2_Lime_kg = CO2_Lime_t * 1000,
        CO2_Dolomite_kg = CO2_Dolomite_t * 1000
      ) %>%
      select(Entity__PeriodEnd, N2O_SynthFert_kg, CO2_SynthFert_kg, N2O_OrganicFert_Direct_kg, CO2_Lime_kg, CO2_Dolomite_kg)
  }
  
}

# Section 2: High-level Summaries -----------------------------------------

summarise_all_annual_by_emission_type <- function(livestock_df, fertiliser_df) {
  
  # full join and replace NAs with zeros => any farms that are livestock or fertiliser only are still present,
  # with zero emissions where relevant
  out_df <- livestock_df %>%
    full_join(
      fertiliser_df %>% filter(Entity__PeriodEnd %in% FarmYear_df$Entity__PeriodEnd),
      by = "Entity__PeriodEnd"
    ) %>%
    mutate_all(replace_na, 0)
  
  return(out_df)
  
}

summarise_all_annual_by_gas <- function(df, calc_delta) {
  
  if(calc_delta) {
    out_df <- df %>%
      group_by(Entity__PeriodEnd) %>%
      summarise(
        CH4_total_kg = sum(CH4_Digestion_LMGenes_delta_kg + CH4_Effluent_SolidSep_delta_kg + CH4_Effluent_EcoPond_delta_kg),
        N2O_total_kg = sum(N2O_SynthFert_UI_delta_kg),
        .groups = "drop"
      )
  } else {
    out_df <- df %>%
      group_by(Entity__PeriodEnd) %>%
      summarise(
        CH4_total_kg = sum(CH4_Digestion_kg + CH4_DungUrine_kg + CH4_Effluent_kg),
        N2O_total_kg = sum(N2O_DungUrine_kg + N2O_Effluent_kg + N2O_SynthFert_kg + N2O_OrganicFert_Direct_kg),
        CO2_total_kg = sum(CO2_SynthFert_kg + CO2_Lime_kg + CO2_Dolomite_kg),
        .groups = "drop"
      )
  }
  
  
  return(out_df)
  
}

# Section 3: Gen Summaries ------------------------------------------------
  
# detailed (per-module) summaries (only farms with input data for relevant module)
smry_livestock_monthly_by_StockClass_df <- summarise_livestock_monthly_by_StockClass(livestock_results_granular_df, calc_delta = FALSE)
smry_livestock_monthly_by_Sector_df <- summarise_livestock_monthly_by_Sector(smry_livestock_monthly_by_StockClass_df, calc_delta = FALSE)
smry_livestock_annual_by_Sector_df <- summarise_livestock_annual_by_Sector(smry_livestock_monthly_by_StockClass_df, calc_delta = FALSE)
smry_livestock_annual_df <- summarise_livestock_annual(smry_livestock_annual_by_Sector_df, calc_delta = FALSE)
smry_fertiliser_annual_df <- summarise_fertiliser_annual(fertiliser_results_granular_df, calc_delta = FALSE)
# high level summaries (all farms)
smry_all_annual_by_emission_type_df <- summarise_all_annual_by_emission_type(smry_livestock_annual_df, smry_fertiliser_annual_df)
smry_all_annual_by_gas_df <- summarise_all_annual_by_gas(smry_all_annual_by_emission_type_df, calc_delta = FALSE)

# mitigation deltas are only calculated if specified
if(length(param_saveout_mitign_delta_tables) > 0) {
  # detailed (per-module) summaries (only farms with input data for relevant module)
  smry_livestock_monthly_by_StockClass_mitign_delta_df <- summarise_livestock_monthly_by_StockClass(livestock_results_granular_df, calc_delta = TRUE)
  smry_livestock_monthly_by_Sector_mitign_delta_df <- summarise_livestock_monthly_by_Sector(smry_livestock_monthly_by_StockClass_mitign_delta_df, calc_delta = TRUE)
  smry_livestock_annual_by_Sector_mitign_delta_df <- summarise_livestock_annual_by_Sector(smry_livestock_monthly_by_StockClass_mitign_delta_df, calc_delta = TRUE)
  smry_livestock_annual_mitign_delta_df <- summarise_livestock_annual(smry_livestock_annual_by_Sector_mitign_delta_df, calc_delta = TRUE)
  smry_fertiliser_annual_mitign_delta_df <- summarise_fertiliser_annual(fertiliser_results_granular_df, calc_delta = TRUE)
  # high level summaries (all farms)
  smry_all_annual_by_emission_type_mitign_delta_df <- summarise_all_annual_by_emission_type(smry_livestock_annual_mitign_delta_df, smry_fertiliser_annual_mitign_delta_df)
  smry_all_annual_by_gas_mitign_delta_df <- summarise_all_annual_by_gas(smry_all_annual_by_emission_type_mitign_delta_df, calc_delta = TRUE)
  # select columns for granular output
  livestock_results_granular_mitign_delta_df <- livestock_results_granular_df %>% select(1:12, 99:106)
  fertiliser_results_granular_mitign_delta_df <- fertiliser_results_granular_df %>% select(1, 15)
}

# select columns for granular output
livestock_results_granular_df <- livestock_results_granular_df %>% select(1:98)
fertiliser_results_granular_df <- fertiliser_results_granular_df %>% select(1:14)

# Section 4: Format Outputs -----------------------------------------------

deconcat_join_key <- function(df) {
  
  out_df <- df %>%
    ungroup() %>%
    mutate(
      Entity_ID = substr(Entity__PeriodEnd, 1, nchar(Entity__PeriodEnd) - 12),
      Period_End = substr(Entity__PeriodEnd, nchar(Entity__PeriodEnd) - 9, nchar(Entity__PeriodEnd))
    ) %>%
    select(
      Entity_ID,
      Period_End,
      everything(),
      -Entity__PeriodEnd
    )
  
  return(out_df)
  
}

# granular (per-module) outputs
livestock_results_granular_df <- deconcat_join_key(livestock_results_granular_df)
fertiliser_results_granular_df <- deconcat_join_key(fertiliser_results_granular_df)
# detailed (per-module) summaries
smry_livestock_monthly_by_StockClass_df <- deconcat_join_key(smry_livestock_monthly_by_StockClass_df)
smry_livestock_monthly_by_Sector_df <- deconcat_join_key(smry_livestock_monthly_by_Sector_df)
smry_livestock_annual_by_Sector_df <- deconcat_join_key(smry_livestock_annual_by_Sector_df)
smry_livestock_annual_df <- deconcat_join_key(smry_livestock_annual_df)
smry_fertiliser_annual_df <- deconcat_join_key(smry_fertiliser_annual_df)
# high level summaries
smry_all_annual_by_emission_type_df <- deconcat_join_key(smry_all_annual_by_emission_type_df)
smry_all_annual_by_gas_df <- deconcat_join_key(smry_all_annual_by_gas_df)

# format mitigation delta tables
if(length(param_saveout_mitign_delta_tables) > 0) {
  # granular (per-module) outputs
  livestock_results_granular_mitign_delta_df <- deconcat_join_key(livestock_results_granular_mitign_delta_df)
  fertiliser_results_granular_mitign_delta_df <- deconcat_join_key(fertiliser_results_granular_mitign_delta_df)
  # detailed (per-module) summaries
  smry_livestock_monthly_by_StockClass_mitign_delta_df <- deconcat_join_key(smry_livestock_monthly_by_StockClass_mitign_delta_df)
  smry_livestock_monthly_by_Sector_mitign_delta_df <- deconcat_join_key(smry_livestock_monthly_by_Sector_mitign_delta_df)
  smry_livestock_annual_by_Sector_mitign_delta_df <- deconcat_join_key(smry_livestock_annual_by_Sector_mitign_delta_df)
  smry_livestock_annual_mitign_delta_df <- deconcat_join_key(smry_livestock_annual_mitign_delta_df)
  smry_fertiliser_annual_mitign_delta_df <- deconcat_join_key(smry_fertiliser_annual_mitign_delta_df)
  # high level summaries
  smry_all_annual_by_emission_type_mitign_delta_df <- deconcat_join_key(smry_all_annual_by_emission_type_mitign_delta_df)
  smry_all_annual_by_gas_mitign_delta_df <- deconcat_join_key(smry_all_annual_by_gas_mitign_delta_df)
}