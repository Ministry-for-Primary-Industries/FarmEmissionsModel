run_livestock_module <- function(
    livestock_precalc_df,
     # remaining args are only passed to eq_fem4_derive_farm_diet_parameters:
     SuppFeed_DryMatter_df,
     lookup_nutrientProfile_supplements_df,
     lookup_nutrientProfile_pasture_df) {
  
  # livestock emissions part 1: energy requirements [FEM ch3]
  
  # split milking cows into separate df:
  
  livestock_precalc_df_milkingCows <- livestock_precalc_df %>%
    filter(StockClass == "Milking Cows Mature")
  
  livestock_precalc_df_nonMilkingCows <- livestock_precalc_df %>%
    filter(StockClass != "Milking Cows Mature")
  
  livestock_calc_df1 <- livestock_precalc_df_milkingCows %>%
    mutate(
      
      # dairy production calculations:
      
      Milk_Yield_Herd_kg = eq_fem3_Milk_Yield_Herd_kg(Milk_Yield_Herd_L = Milk_Yield_Herd_L),
      
      Milk_Fat_pct = eq_fem3_Milk_Fat_pct(
        Milk_Fat_Herd_kg = Milk_Fat_Herd_kg,
        Milk_Yield_Herd_kg = Milk_Yield_Herd_kg
      ),
      
      Milk_Protein_pct = eq_fem3_Milk_Protein_pct(
        Milk_Protein_Herd_kg = Milk_Protein_Herd_kg,
        Milk_Yield_Herd_kg = Milk_Yield_Herd_kg
      ),
      
      Milk_Yield_kg = eq_fem3_Milk_Yield_kg(
        Milk_Yield_Herd_kg = Milk_Yield_Herd_kg,
        StockCount_mean = StockCount_mean)
    ) %>% 
  
  # bind other stock classes back in:
  
    bind_rows(livestock_precalc_df_nonMilkingCows) %>% 
  
  # continue calculations on all stock classes:
  
    mutate(
      
      # calculate subcomponents of ME_p:
      
      Q_m = eq_fem3_Q_m(ME_Diet_AIM = ME_Diet_AIM),
      
      k_l = eq_fem3_k_l(
        Sector = Sector,
        StockClass = StockClass,
        Q_m = Q_m,
        ME_Diet_AIM = ME_Diet_AIM
      ),
      
      GE_Milk = eq_fem3_GE_Milk(
        Sector = Sector,
        StockClass = StockClass,
        Milk_Fat_pct = Milk_Fat_pct,
        Milk_Protein_pct = Milk_Protein_pct,
        Milk_Yield_kg = Milk_Yield_kg,
        Milk_Mother_kg = Milk_Mother_kg,
        Milk_Newborn_kg = Milk_Newborn_kg,
        MilkPowder_Newborn_kg = MilkPowder_Newborn_kg
      ),
      
      ME_l = eq_fem3_ME_l(
        StockClass = StockClass,
        Milk_Yield_kg = Milk_Yield_kg,
        Milk_Mother_kg = Milk_Mother_kg,
        GE_Milk = GE_Milk,
        k_l = k_l,
        Reproduction_Rate = Reproduction_Rate
      ),
      
      ME_Velvet = eq_fem3_ME_Velvet(Velvet_Yield_kg = Velvet_Yield_kg),
      
      ME_Wool = eq_fem3_ME_Wool(
        Wool_Yield_kg = Wool_Yield_kg,
        MonthDays = MonthDays
      ),
      
      ME_LWG = eq_fem3_ME_LWG(
        SRW_kg = SRW_kg,
        LW_kg = LW_kg,
        LWG_kg = LWG_kg,
        ME_Diet_AIM = ME_Diet_AIM,
        MonthDays = MonthDays
      ),
      
      # calculate ME_p:
      
      ME_p = eq_fem3_ME_p(
        ME_l = ME_l,
        ME_LWG = ME_LWG,
        ME_Velvet = ME_Velvet,
        ME_Wool = ME_Wool
      ),
      
      # calculate other components of ME_total:
      
      k_m = eq_fem3_k_m(Sector, Q_m = Q_m),
      
      ME_m = eq_fem3_ME_m(
        Sector = Sector,
        Sex = Sex,
        Age = Age,
        LW_kg = LW_kg,
        k_m = k_m,
        ME_p = ME_p,
        MonthDays = MonthDays
      ),
      
      ME_c = eq_fem3_ME_c(
        Sector = Sector,
        LW_kg = LW_kg,
        Days_Pregnant = Days_Pregnant,
        Trimester_Factor = Trimester_Factor,
        Reproduction_Rate = Reproduction_Rate,
        MonthDays = MonthDays,
        BW_kg = BW_kg
      ),
      
      ME_Z1 = eq_fem3_ME_Z1(
        StockClass = StockClass,
        Milk_Newborn_kg = Milk_Newborn_kg,
        MilkPowder_Newborn_kg = MilkPowder_Newborn_kg,
        GE_Milk = GE_Milk,
        k_l = k_l
      ),
      
      ME_Graze = eq_fem3_ME_Graze(
        Sector = Sector,
        DMD_pct_Diet_AIM = DMD_pct_Diet_AIM,
        ME_m = ME_m,
        ME_p = ME_p,
        ME_Z1 = ME_Z1,
        LW_kg = LW_kg,
        k_m = k_m,
        ME_Diet_AIM = ME_Diet_AIM,
        ME_c = ME_c,
        MonthDays = MonthDays
      ),
      
      # calculate ME_total:
      
      ME_total_pre_ME_Z = eq_fem3_ME_total_pre_ME_Z(
        ME_m = ME_m,
        ME_Graze = ME_Graze,
        ME_c = ME_c,
        ME_p = ME_p
      ),
      
      ME_total = eq_fem3_ME_total(
        ME_total_pre_ME_Z = ME_total_pre_ME_Z,
        ME_Z0_pct = ME_Z0_pct,
        ME_Z1 = ME_Z1
      )
    )
  
  # livestock emissions part 2: farm diet (ME_Diet, DMD_pct_Diet, N_pct_Diet) and DMI [FEM ch4]
  
  # if no livestock, init farm diet cols:
  
  if (nrow(livestock_precalc_df) == 0) {
    livestock_calc_df2 <- livestock_calc_df1 %>%
      mutate(ME_Diet = NA,
             DMD_pct_Diet = NA,
             N_pct_Diet = NA)
    
  } else {
    livestock_calc_df2 <- unique(livestock_calc_df1$Sector) %>%
      map_df(
        ~ eq_fem4_derive_farm_diet_parameters(
          in_df = livestock_calc_df1 %>% filter(Sector == .x),
          SuppFeed_DryMatter_df = SuppFeed_DryMatter_df,
          lookup_nutrientProfile_supplements_df = lookup_nutrientProfile_supplements_df,
          lookup_nutrientProfile_pasture_df = lookup_nutrientProfile_pasture_df
        )
      )
    
  }
  
  # calculate DMI_kg:
  
  livestock_calc_df2 <- livestock_calc_df2 %>%
    mutate(DMI_kg = eq_fem4_DMI_kg(
      ME_total = ME_total,
      ME_Diet = ME_Diet
    )
  ) %>% 
  
  # livestock emissions part 3: nitrogen excretion [FEM ch5]
  
    mutate(
      
      # calculate N_Intake_kg:
      
      N_Intake_kg = eq_fem5_N_Intake_kg(
        Sector = Sector,
        StockClass = StockClass,
        DMI_kg = DMI_kg,
        N_pct_Diet = N_pct_Diet,
        Milk_Newborn_kg = Milk_Newborn_kg,
        Milk_Protein_pct = Milk_Protein_pct,
        MilkPowder_Newborn_kg = MilkPowder_Newborn_kg,
        MilkPowder_Protein_pct = MilkPowder_Protein_pct
      ),
      
      # calculate transferred (non-emitted) Nitrogen:
      
      N_Retained_Milk_kg = eq_fem5_N_Retained_Milk_kg(
        Sector = Sector,
        StockClass = StockClass,
        Milk_Yield_kg = Milk_Yield_kg,
        Milk_Mother_kg = Milk_Mother_kg,
        Milk_Protein_pct = Milk_Protein_pct,
        Reproduction_Rate = Reproduction_Rate
      ),
      
      N_Retained_LWG_kg = eq_fem5_N_Retained_LWG_kg(
        Sector = Sector,
        LWG_kg = LWG_kg
      ),
      
      N_Retained_FWG_kg = eq_fem5_N_Retained_FWG_kg(
        Sector = Sector,
        FWG_kg = FWG_kg,
        Reproduction_Rate = Reproduction_Rate
      ),
      
      N_Retained_Velvet_kg = eq_fem5_N_Retained_Velvet_kg(Velvet_Yield_kg = Velvet_Yield_kg),
      
      N_Retained_Wool_kg = eq_fem5_N_Retained_Wool_kg(Wool_Yield_kg = Wool_Yield_kg),
      
      # calculate N_Excretion_kg:
      
      N_Excretion_kg = eq_fem5_N_Excretion_kg(
        N_Intake_kg = N_Intake_kg,
        N_Retained_Milk_kg = N_Retained_Milk_kg,
        N_Retained_LWG_kg = N_Retained_LWG_kg,
        N_Retained_FWG_kg = N_Retained_FWG_kg,
        N_Retained_Velvet_kg = N_Retained_Velvet_kg,
        N_Retained_Wool_kg = N_Retained_Wool_kg
      ),
      
      # breakdown N_Excretion_kg into subcomponents:
      
      N_Dung_kg = eq_fem5_N_Dung_kg(
        Sector = Sector,
        N_pct_Diet = N_pct_Diet,
        DMI_kg = DMI_kg,
        N_Intake_kg = N_Intake_kg,
        MonthDays = MonthDays
      ),
      
      N_Urine_kg = eq_fem5_N_Urine_kg(
        N_Excretion_kg = N_Excretion_kg,
        N_Dung_kg = N_Dung_kg
      )
    ) %>% 
  
  # livestock emissions part 4: enteric fermentation [FEM ch6]
  
  mutate(
    CH4_Enteric_kg = eq_fem6_CH4_Enteric_kg(
      Sector = Sector,
      StockClass = StockClass,
      DMI_kg = DMI_kg,
      ME_Diet = ME_Diet,
      MonthDays = MonthDays,
      BV_aCH4 = BV_aCH4
    )
  ) %>% 
  
  # livestock emissions part 5: excretion [FEM ch7]
  
    mutate(
      
      # calculate FDM_kg:
      
      FDM_kg = eq_fem7_FDM_kg(DMI_kg = DMI_kg, DMD_pct_Diet = DMD_pct_Diet),
      
      # allocate excretion to lagoon and pasture:
      
      DungUrine_to_Lagoon_pct = eq_fem7_DungUrine_to_Lagoon_pct(
        StockClass = StockClass,
        Milk_Yield_kg = Milk_Yield_kg
      ),
      
      DungUrine_to_Pasture_pct = eq_fem7_DungUrine_to_Pasture_pct(DungUrine_to_Lagoon_pct = DungUrine_to_Lagoon_pct),
      
      # calculate pasture emissions:
      
      # pasture CH4
      
      CH4_Pasture_Dung_kg = eq_fem7_CH4_Pasture_Dung_kg(
        Sector = Sector,
        DungUrine_to_Pasture_pct = DungUrine_to_Pasture_pct,
        FDM_kg = FDM_kg
      ),
      
      # pasture direct N2O
      
      N2O_Pasture_Urine_Direct_kg = eq_fem7_N2O_Pasture_Urine_Direct_kg(
        Sector = Sector,
        StockClass = StockClass,
        N_Urine_kg = N_Urine_kg,
        DungUrine_to_Pasture_pct = DungUrine_to_Pasture_pct,
        N_Urine_Flattish_pct = N_Urine_Flattish_pct,
        N_Urine_Steep_pct = N_Urine_Steep_pct
      ),
      
      N2O_Pasture_Dung_Direct_kg = eq_fem7_N2O_Pasture_Dung_Direct_kg(
        N_Dung_kg = N_Dung_kg,
        DungUrine_to_Pasture_pct = DungUrine_to_Pasture_pct
      ),
      
      # pasture indirect N2O: leached
      
      N2O_Pasture_Urine_Leach_kg = eq_fem7_N2O_Pasture_Urine_Leach_kg(
        N_Urine_kg = N_Urine_kg,
        DungUrine_to_Pasture_pct = DungUrine_to_Pasture_pct
      ),
      
      N2O_Pasture_Dung_Leach_kg = eq_fem7_N2O_Pasture_Dung_Leach_kg(
        N_Dung_kg = N_Dung_kg,
        DungUrine_to_Pasture_pct = DungUrine_to_Pasture_pct
      ),
      
      # pasture indirect N2O: volatilised
      
      N2O_Pasture_Urine_Volat_kg = eq_fem7_N2O_Pasture_Urine_Volat_kg(
        N_Urine_kg = N_Urine_kg,
        DungUrine_to_Pasture_pct = DungUrine_to_Pasture_pct
      ),
      
      N2O_Pasture_Dung_Volat_kg = eq_fem7_N2O_Pasture_Dung_Volat_kg(
        N_Dung_kg = N_Dung_kg,
        DungUrine_to_Pasture_pct = DungUrine_to_Pasture_pct
      ),
      
      # calculate (mature milking cow) effluent emissions:
      
      CH4_Effluent_Lagoon_kg = eq_fem7_CH4_Effluent_Lagoon_kg(
        StockClass = StockClass,
        DungUrine_to_Lagoon_pct = DungUrine_to_Lagoon_pct,
        FDM_kg = FDM_kg
      ),
      
      N2O_Effluent_Lagoon_Volat_kg = eq_fem7_N2O_Effluent_Lagoon_Volat_kg(
        StockClass = StockClass,
        DungUrine_to_Lagoon_pct = DungUrine_to_Lagoon_pct,
        N_Excretion_kg = N_Excretion_kg
      ),
      
      # calculate (milking cow) effluent spread on pasture as organic fert N2O:
      
      N_Effluent_Spread_kg = eq_fem7_N_Effluent_Spread_kg(
        N_Excretion_kg = N_Excretion_kg,
        DungUrine_to_Lagoon_pct = DungUrine_to_Lagoon_pct
      ),
      
      N2O_Effluent_Spread_Direct_kg = eq_fem7_N2O_Effluent_Spread_Direct_kg(N_Effluent_Spread_kg = N_Effluent_Spread_kg),
      
      N2O_Effluent_Spread_Leach_kg = eq_fem7_N2O_Effluent_Spread_Leach_kg(N_Effluent_Spread_kg = N_Effluent_Spread_kg),
      
      N2O_Effluent_Spread_Volat_kg = eq_fem7_N2O_Effluent_Spread_Volat_kg(N_Effluent_Spread_kg = N_Effluent_Spread_kg)
    )
  
  return(livestock_calc_df2)
  
}

livestock_results_granular_df <- run_livestock_module(
  livestock_precalc_df,
  SuppFeed_DryMatter_df,
  lookup_nutrientProfile_supplements_df,
  lookup_nutrientProfile_pasture_df
)