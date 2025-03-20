run_SynthFert_module <- function(Fertiliser_df, excl_mitigations = FALSE, max_mitigations = FALSE) {
  
  # synthetic fertiliser emissions [FEM ch8]
  
  calc_fert_df <- Fertiliser_df %>%
    mutate(
      # N2O Emissions
      N2O_SynthFert_Direct_t = eq_fem8_N2O_SynthFert_Direct_t(
        N_Urea_Uncoated_t = N_Urea_Uncoated_t,
        N_Urea_Coated_t = N_Urea_Coated_t,
        N_NonUrea_SyntheticFert_t = N_NonUrea_SyntheticFert_t
      ),
      
      N2O_SynthFert_Leach_t = eq_fem8_N2O_SynthFert_Leach_t(
        N_Urea_Uncoated_t = N_Urea_Uncoated_t,
        N_Urea_Coated_t = N_Urea_Coated_t,
        N_NonUrea_SyntheticFert_t = N_NonUrea_SyntheticFert_t
      ),
      
      N2O_SynthFert_Volat_t = eq_fem8_N2O_SynthFert_Volat_t(
        N_Urea_Uncoated_t = N_Urea_Uncoated_t,
        N_Urea_Coated_t = N_Urea_Coated_t,
        N_NonUrea_SyntheticFert_t = N_NonUrea_SyntheticFert_t
      ),
      # CO2 Emissions (Urea only)
      CO2_SynthFert_t = eq_fem8_CO2_SynthFert_t(
        N_Urea_Uncoated_t = N_Urea_Uncoated_t,
        N_Urea_Coated_t = N_Urea_Coated_t
      )
    )
  
  if (excl_mitigations == TRUE) {
    calc_fert_df <- calc_fert_df %>% 
      mutate(N2O_SynthFert_Volat_t = eq_fem8_N2O_SynthFert_Volat_t(N_Urea_Uncoated_t = N_Urea_Uncoated_t,
                                                                   N_Urea_Coated_t = N_Urea_Coated_t,
                                                                   N_NonUrea_SyntheticFert_t = N_NonUrea_SyntheticFert_t,
                                                                   frac_gasf_coated = 0.1))
  }
  
  if (max_mitigations == TRUE) {
    calc_fert_df <- calc_fert_df %>% 
      mutate(N2O_SynthFert_Volat_t = eq_fem8_N2O_SynthFert_Volat_t(N_Urea_Uncoated_t = N_Urea_Uncoated_t,
                                                                   N_Urea_Coated_t = N_Urea_Coated_t,
                                                                   N_NonUrea_SyntheticFert_t = N_NonUrea_SyntheticFert_t,
                                                                   frac_gasf_uncoated = 0.055))
  }
  
  return(calc_fert_df)
  
}

fertiliser_results_granular_df <- run_SynthFert_module(Fertiliser_df = Fertiliser_df)



if (param_saveout_mitigations_delta == TRUE) {
  # excluding mitigation impact from UI
  fertiliser_results_granular_df_excl_mitigation <- run_SynthFert_module(Fertiliser_df = Fertiliser_df, excl_mitigations = TRUE)
  # including maximum potential mitigation impact from UI (i.e., using 100% UI coated urea)
  fertiliser_results_granular_df_max_mitigation <- run_SynthFert_module(Fertiliser_df = Fertiliser_df, max_mitigations = TRUE)
}

