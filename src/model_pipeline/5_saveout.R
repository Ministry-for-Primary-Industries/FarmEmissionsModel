# parse system datetime for appending to output filenames

sys_datetime <- format(Sys.time(), "%Y-%m-%d_%H%M%S")

# Section 1: Granular calculation data -----------------------------------

if (param_saveout_granular_calculation_data == TRUE) {
  # Create output directory if it doesn't exist
  if (!dir.exists(param_output_path)) {
    dir.create(param_output_path, recursive = TRUE)
  }
  
  if (param_output_data_format == "csv") {
    # Livestock
    write_csv(livestock_results_granular_df,
              file.path(
                param_output_path,
                paste0("livestock_results_granular_", sys_datetime, ".csv")
              ))
    
    # Fertiliser
    write_csv(fertiliser_results_granular_df,
              file.path(
                param_output_path,
                paste0("fertiliser_results_granular_", sys_datetime, ".csv")
              ))
    
  } else if (param_output_data_format == "json") {
    # Save out granular calculation data
    
    # Livestock
    write_json(
      list(
        livestock_results_granular = livestock_results_granular_df,
        fertiliser_results_granular = fertiliser_results_granular_df
      ),
      file.path(
        param_output_path,
        paste0("results_granular_", sys_datetime, ".json")
      )
    )
    
  }
  
}

# Section 2: Summary data ------------------------------------------------

if (param_saveout_summary_data == TRUE) {
  # Create output directory if it doesn't exist
  if (!dir.exists(param_output_path)) {
    dir.create(param_output_path, recursive = TRUE)
  }
  
  # Save out summarised data
  if (param_output_data_format == "csv") {
    if (param_summarise_mode == 'detailed-only' ||
        param_summarise_mode == 'all') {
      # Detailed (per-module) summaries
      write_csv(
        smry_livestock_monthly_by_StockClass_df,
        file.path(
          param_output_path,
          paste0(
            "smry_livestock_monthly_by_StockClass_",
            sys_datetime,
            ".csv"
          )
        )
      )
      
      write_csv(smry_livestock_monthly_by_Sector_df,
                file.path(
                  param_output_path,
                  paste0(
                    "smry_livestock_monthly_by_Sector_",
                    sys_datetime,
                    ".csv"
                  )
                ))
      
      write_csv(smry_livestock_annual_by_Sector_df,
                file.path(
                  param_output_path,
                  paste0(
                    "smry_livestock_annual_by_Sector_",
                    sys_datetime,
                    ".csv"
                  )
                ))
      
      write_csv(smry_livestock_annual_df,
                file.path(
                  param_output_path,
                  paste0("smry_livestock_annual_", sys_datetime, ".csv")
                ))
      
      write_csv(smry_fertiliser_annual_df,
                file.path(
                  param_output_path,
                  paste0("smry_fertiliser_annual_", sys_datetime, ".csv")
                ))
      
    }
    
    if (param_summarise_mode == 'highLevel-only' ||
        param_summarise_mode == "all") {
      # High level summaries (all farms)
      write_csv(smry_all_annual_by_emission_type_df,
                file.path(
                  param_output_path,
                  paste0(
                    "smry_all_annual_by_emission_type_",
                    sys_datetime,
                    ".csv"
                  )
                ))
      
      write_csv(smry_all_annual_by_gas_df,
                file.path(
                  param_output_path,
                  paste0("smry_all_annual_by_gas_", sys_datetime, ".csv")
                ))
      
    }
    
  } else if (param_output_data_format == "json") {
    if (param_summarise_mode == "detailed-only" ||
        param_summarise_mode == "all") {
      write_json(
        list(
          smry_livestock_monthly_by_StockClass = smry_livestock_monthly_by_StockClass_df,
          smry_livestock_monthly_by_Sector = smry_livestock_monthly_by_Sector_df,
          smry_livestock_annual_by_Sector = smry_livestock_annual_by_Sector_df,
          smry_livestock_annual = smry_livestock_annual_df,
          smry_fertiliser_annual = smry_fertiliser_annual_df
        ),
        file.path(
          param_output_path,
          paste0("smry_detailed_", sys_datetime, ".json")
        )
      )
      
    }
    
    if (param_summarise_mode == "highLevel-only" ||
        param_summarise_mode == "all") {
      write_json(
        list(
          smry_all_annual_by_emission_type = smry_all_annual_by_emission_type_df,
          smry_all_annual_by_gas = smry_all_annual_by_gas_df
        ),
        file.path(
          param_output_path,
          paste0("smry_highLevel_", sys_datetime, ".json")
        )
      )
      
    }
    
  }
  
}
