run_SynthFert_module <- function(Fertiliser_df) {
  
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
  
  return(calc_fert_df)
  
}

fertiliser_results_granular_df <- run_SynthFert_module(Fertiliser_df = Fertiliser_df)
