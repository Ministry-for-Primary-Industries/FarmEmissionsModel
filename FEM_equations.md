------------------------------------------------------------------------

# Introduction

This file contains an accessible and ordinal library of R functions that
perform the equations prescribed by the Farm Emission Model methodology
(available
[here](https://www.mpi.govt.nz/funding-rural-support/environment-and-natural-resources/estimating-on-farm-emissions)).
Standalone it does not complete a farm-level emissions estimation

This system of R functions are:

-   separated into self-contained modules, currently covering livestock
    and synthetic fertiliser emissions

-   named in the form `eq_femD_X()` where digit `D` refers to the
    relevant chapter in the FEM methodology and string `X` refers to the
    output of the equation being calculated

    -   a single function may wrap multiple intermediate equations found
        in the methodology as it calculates the output `X`

    -   if child functions exist within the above, they handle
        conditional logic. For instance: sectoral variation in the
        calculation of X. These are prefixed `feq` and suffixed with a
        simple description of the condition(s) that apply
        e.g. `feq_deer()` applies to deer

As this model is adapted from Ministry for Primary Industries’ national
[Agricultural GHG Inventory
Methodology](https://www.mpi.govt.nz/dmsdocument/13906/direct) (**AIM**)
we note that:

-   any algebra typically follows the format of the AIM equations
    (referenced in the FEM methodology). In some cases refactoring has
    been done for clarity and/or to enable generalisation of multiple
    AIM equations into a single function

-   equation parameter names generally mirror those in AIM

We place a high priority on parameter consistency. The equations and
their parameters are modified from AIM where necessary to ensure
consistent timeframes, units and representation of
percentages/allocations/weights/proportions such that they are:

-   defined in per animal terms unless explicitly noted

-   for parameters defined in terms of a time period, we use monthly
    unless explicitly noted

-   explicitly note unit of mass. Our default is kg where appropriate

-   all percentage and allocation parameters explicitly contain this in
    their names and are always in decimal form e.g. 5% = 0.05

Examples:

-   `DMI_kg` is the dry matter intake (of the farm-level diet) in kg,
    per animal, of a given StockClass, in a given Month
-   `N_pct_Diet` is the Nitrogen percentage of the diet, for a given
    StockClass, in a given Month

# Global Helper Lists

Helper lists used in multiple equations across the system are defined
here:

``` r
stockClassList_newborns <- c(
  # beef
  "Bulls R1", "Heifers R1", "Steers R1",
  # dairy
  "Dairy Heifers R1", "Dairy Bulls R1",
  # deer
  "Hinds R1", "Stags R1", 
  # sheep
  "Lambs"
) # used by: eq_fem3_ME_Z1 and preprocessing

stockClassList_lactatingMothers <- c(
  # beef
  "Heifers R3", "Cows Mature",
  # dairy
  "Milking Cows Mature",
  # deer
  "Hinds Mature",
  # sheep
  "Ewe Hoggets", "Ewes Mature"
) # used by: eq_fem3_ME_l, eq_fem5_N_Retained_Milk_kg

stockClassList_newborns_lactatingMothers <- append(
  stockClassList_newborns,
  stockClassList_lactatingMothers
) # used by: eq_fem3_k_l
```

# Module 1: Livestock Emissions

## Components of ME_total:

### Q_m

The ratio of metabolisable to gross energy for feed. An intermediate
output necessary for ME_l and ME_m calculations via k_l and k_m
respectively

``` r
eq_fem3_Q_m <- function(
    ME_Diet_AIM, # assumedParameters lookup
    GE_Diet=18.45 # AIM sets 18.45 in all cases
    ) {
  
  # ref FEM equation 3.1
  
  Q_m <- ME_Diet_AIM / GE_Diet
  
  return(Q_m)
  
}
```

### ME_l

Calculates the metabolisable energy required for lactation in relevant
mother stock classes

#### ME_l Part 1: Dairy production - Mature Milking Dairy Cows only

This prepares farm data inputs on:

-   Milk Yield from L/herd to kg/animal

-   Milk solids content from kg/herd to percentage terms \[on a
    mass:mass percentage basis, consistent with the academic literature
    and how percentages are usually prescribed, but notably different
    from the mass:volume basis form (i.e. kg milk solid / L milk) that
    milk solid percentages are generally communicated to a farmer by
    milk processors\]

``` r
eq_fem3_Milk_Yield_Herd_kg <- function(
    Milk_Yield_Herd_L # farm data input
) {
  
  # ref FEM equation 3.2
  
  # convert farm input of dairy herd milk yield in volume (L) to mass (kg)
  
  Milk_Yield_Herd_kg = Milk_Yield_Herd_L * 1.03
  
  return(Milk_Yield_Herd_kg)
  
}

eq_fem3_Milk_Fat_pct <- function(
    Milk_Fat_Herd_kg, # farm data input
    Milk_Yield_Herd_kg # farm data input
) {
  
  # ref FEM equation 3.3
  
  Milk_Fat_pct = Milk_Fat_Herd_kg / Milk_Yield_Herd_kg
  
  return(Milk_Fat_pct)
  
}

eq_fem3_Milk_Protein_pct <- function(
    Milk_Protein_Herd_kg, # farm data input
    Milk_Yield_Herd_kg # calculated in system
) {
  
  # ref FEM equation 3.4
  
  Milk_Protein_pct = Milk_Protein_Herd_kg / Milk_Yield_Herd_kg
  
  return(Milk_Protein_pct)
  
}

eq_fem3_Milk_Yield_kg <- function(
    Milk_Yield_Herd_kg, # farm data input
    StockCount_mean # farm data input. Mean StockCount of given StockClass in a given month
) {
  
  # ref FEM equation 3.5
  
  # convert herd Milk Yield to per animal terms
  
  # set NAs to 0
  Milk_Yield_Herd_kg <- replace_na(Milk_Yield_Herd_kg, 0)
  
  Milk_Yield_kg = Milk_Yield_Herd_kg / StockCount_mean
  
  return(Milk_Yield_kg)
  
}
```

#### ME_l Part 2: All stock classes

``` r
eq_fem3_k_l <- function(
    Sector, # sectoral variation
    StockClass, # only applies to newborn/mother stock classes
    Q_m, # calculated in system
    ME_Diet_AIM # assumedParameters lookup
) {
  
  # ref FEM equations 3.6a - 3.6b
  
  # calculate efficiency of utilisation of ME for milk production, k_l
  
  feq_cattle_sheep <- function() {
    
    k_l = 0.35 * Q_m + 0.42
    
    return(k_l)
    
  }
  
  feq_deer <- function() {
    
    k_l = 0.64 
    
    return(k_l)
    
  }
  
  case_when(
    !StockClass %in% stockClassList_newborns_lactatingMothers ~ 0, # zero if not newborn or mother
    Sector %in% c("Beef", "Dairy", "Sheep") ~ feq_cattle_sheep(),
    Sector == "Deer" ~ feq_deer()
  )
  
}

eq_fem3_GE_Milk <- function(
    Sector, # sectoral variation
    StockClass, # only applies to newborn/mother stock classes
    Milk_Fat_pct, # calculated in system
    Milk_Protein_pct, # calculated in system
    Milk_Yield_kg, # calculated in system
    Milk_Mother_kg, # assumedParameters lookup
    Milk_Newborn_kg, # derived in preproc from farm data / AIM assumptions
    MilkPowder_Newborn_kg # derived in preproc from farm data / AIM assumptions
) {
  
  # ref FEM equations 3.7a - 3.7c
  
  # calculate gross energy content of milk, GE_Milk
  
  # set NAs to 0
  Milk_Fat_pct <- replace_na(Milk_Fat_pct, 0)
  Milk_Protein_pct <- replace_na(Milk_Protein_pct, 0)
  Milk_Yield_kg <- replace_na(Milk_Yield_kg, 0)
  Milk_Mother_kg <- replace_na(Milk_Mother_kg, 0)
  Milk_Newborn_kg <- replace_na(Milk_Newborn_kg, 0)
  MilkPowder_Newborn_kg <- replace_na(MilkPowder_Newborn_kg, 0)
  
  # calculate Milk_combined_kg for simple case_when conditions
  
  Milk_combined_kg <- Milk_Yield_kg + Milk_Mother_kg + Milk_Newborn_kg + MilkPowder_Newborn_kg
  
  feq_cattle <- function() {
  
    GE_Milk = (0.376 * (Milk_Fat_pct * 100)) +
              (0.209 * (Milk_Protein_pct * 100)) +
              0.948
    
    return(GE_Milk)
  
  }
  
  feq_deer <- function() {
    
    GE_Milk = 5.9
    
    return(GE_Milk)
    
  }
  
  feq_sheep <- function() {
    
    GE_Milk = (0.328 * (Milk_Fat_pct * 100)) +
              0.0028 * 61 + 2.2033
    
    return(GE_Milk)
    
  }
  
  case_when(
    Milk_combined_kg == 0 ~ 0,
    Sector %in% c("Beef", "Dairy") ~ feq_cattle(),
    Sector == "Deer" ~ feq_deer(),
    Sector == "Sheep" ~ feq_sheep()
  )
  
}

eq_fem3_ME_l <- function(
    StockClass, # only applies to mother stock classes
    Milk_Yield_kg, # calculated in system
    Milk_Mother_kg, # assumedParameters lookup
    GE_Milk, # calculated in system
    k_l, # calculated in system
    Reproduction_Rate # assumedParameters lookup
) {
  
  # ref FEM equations 3.8 - 3.9
  
  # calculate energy required for milk production, ME_l
  
  feq_mothers <- function() {
    
    # set NAs to 0
    Milk_Yield_kg <- replace_na(Milk_Yield_kg, 0)
    Milk_Mother_kg <- replace_na(Milk_Mother_kg, 0)
    
    Milk_total_kg <- Milk_Yield_kg + Milk_Mother_kg
    
    ME_l <- ( (Milk_total_kg * GE_Milk) / k_l ) * Reproduction_Rate
  
    return(ME_l)
    
  }
  
  case_when(
    StockClass %in% stockClassList_lactatingMothers ~ feq_mothers(),
    TRUE ~ 0
  )
  
}
```

### ME_LWG

Calculates the metabolisable energy required for live weight gain in
relevant growing stock classes

``` r
eq_fem3_ME_LWG <- function(
  SRW_kg, # assumedParameters lookup
  LW_kg, # assumedParameters lookup
  LWG_kg, # assumedParameters lookup
  ME_Diet_AIM, # assumedParameters lookup
  MonthDays
) {
    
  # ref FEM equations 3.10 - 3.16
  
  LWG_kg_day = LWG_kg / MonthDays
  
  EBC = 0.92 * LWG_kg_day
  
  R = EBC / (4 * (SRW_kg ^ 0.75)) - 1
  
  P_LW = pmin(LW_kg / SRW_kg, 1) # according to CSIRO (2007), LW_kg should not exceed SRW_kg in this eqn => set ceiling of 1
  
  k_gnl = 0.042 * ME_Diet_AIM + 0.006
  
  ME_LWG_day = ((
    (6.7 + R) + (20.3 - R) / (1 + exp(-6 * (P_LW - 0.4)))
  ) / k_gnl
  ) * LWG_kg_day * 0.921
  
  ME_LWG = ME_LWG_day * MonthDays
  
  return(ME_LWG)
  
}
```

### ME_Velvet and ME_Wool

Calculates the metabolisable energy required for the production of
velvet and wool in relevant deer and sheep stock classes.

``` r
eq_fem3_ME_Velvet <- function(
    Velvet_Yield_kg, # assumedParameters lookup
    Velvet_Yield_annual_kg=4, # set by AIM
    ME_Velvet_daily = 0.5, # MJ, set by AIM
    Velvet_Production_annual_days=65 # set by AIM, from 1st September to 4th November
) {
  
  # ref FEM equation 3.17
  
  ME_Velvet = ME_Velvet_daily * (Velvet_Yield_kg / Velvet_Yield_annual_kg) * Velvet_Production_annual_days
  
}

eq_fem3_ME_Wool <- function(
    Wool_Yield_kg, # assumedParameters lookup
    MonthDays
) {
  
  # ref FEM equations 3.18 - 3.20
  
  # calculate ME required for wool production (beyond 6g/day which is already accounted for in ME_m)
  
  Wool_Yield_g_day = Wool_Yield_kg * 1000 / MonthDays
  
  ME_Wool_day = 0.13 * (Wool_Yield_g_day - 6)
  
  ME_Wool = pmax(ME_Wool_day * MonthDays, 0) # pmax sets floor of 0, explanation in CSIRO
  
  return(ME_Wool)
  
}
```

### ME_p

The ME for production is simply the sum of all ME components related to
production: ME_l, ME_LWG, ME_Velvet, ME_Wool

``` r
eq_fem3_ME_p <- function(
    ME_l, # calculated in system
    ME_LWG, # calculated in system
    ME_Velvet, # calculated in system
    ME_Wool # calculated in system
) {
  
  # ref FEM equation 3.21
  
  # set NAs to 0:
  
  ME_l <- replace_na(ME_l, 0)
  ME_LWG <- replace_na(ME_LWG, 0)
  ME_Velvet <- replace_na(ME_Velvet, 0)
  ME_Wool <- replace_na(ME_Wool, 0)
  
  ME_p = ME_l + ME_LWG + ME_Velvet + ME_Wool
  
  return(ME_p)
  
}
```

### ME_m

The metabolisable energy required for basal maintenance i.e. to maintain
animal weight

``` r
eq_fem3_k_m <- function(
    Sector, # sectoral variation
    Q_m # calculated in system
    ) {
  
  # ref FEM equations 3.22a - 3.22b
  
  # calculation of efficiency of utilisation for maintenance, k_m
  
  feq_cattle_sheep <- function() {
    
    k_m <- 0.35 * Q_m + 0.503
  
    return(k_m)
    
  }
  
  feq_deer <- function() {
    
    k_m <- 0.2 * Q_m + 0.503
  
    return(k_m)
    
  }
  
  case_when(
    Sector %in% c("Beef", "Dairy", "Sheep") ~ feq_cattle_sheep(),
    Sector == "Deer" ~ feq_deer()
  )
  
}

eq_fem3_ME_m <- function(
  Sector, # sectoral variation
  Sex, # varies between males and females/castrates
  LW_kg, # assumedParameters lookup
  Age, # assumedParameters lookup
  k_m, # calculated in system
  ME_p, # calculated in system
  MonthDays
) {
  
  # ref FEM equations 3.23 - 3.24
  
  feq_all <- function(K, S) {
    
    ME_m_day <- K * S * ((0.28 * LW_kg^0.75 * exp(-0.03 * Age)) / k_m) + (0.1 * ME_p/MonthDays)
    
    ME_m <- ME_m_day * MonthDays
    
    return(ME_m)
    
  }
  
  case_when(
    Sector %in% c("Beef", "Dairy", "Deer") & Sex == "Male" ~ feq_all(K=1.4, S=1.15),
    Sector %in% c("Beef", "Dairy", "Deer") & Sex %in% c("Female", "Castrate") ~ feq_all(K=1.4, S=1),
    Sector == "Sheep" & Sex == "Male" ~ feq_all(K=1, S=1.15),
    Sector == "Sheep" & Sex %in% c("Female", "Castrate") ~ feq_all(K=1, S=1),
    Sector == "Sheep" & Sex == "Mixed" ~ feq_all(K=1, S=1.075), # assumption of 1.075
    TRUE ~ NA
  )
  
}
```

### ME_c

The metabolisable energy required for conceptus (i.e. gestation) in
relevant mother stock classes

``` r
eq_fem3_ME_c <- function(
    Sector, # sectoral variation
    LW_kg, # assumedParameters lookup
    Days_Pregnant, # assumedParameters lookup
    Trimester_Factor, # assumedParameters lookup
    Reproduction_Rate, # assumedParameters lookup
    k_c=0.133, # set by AIM
    MonthDays,
    BW_kg # assumedParameters lookup
) {
  
    # ref FEM equations 3.25 - 3.32
  
    feq_dairy <- function() {
      
      BW_kg = 0.095 * LW_kg
    
      E_t = 10 ** (151.665 - 151.64 * exp(-5.76e-05 * Days_Pregnant))
      
      ME_c_day = 0.025 * BW_kg * (
        ((0.0201 * E_t) * exp(-5.76e-05 * Days_Pregnant)) / k_c
      )
      
      ME_c = ME_c_day * MonthDays * Reproduction_Rate
      
      return(ME_c)
    
    }
    
    feq_beef <- function() {
      
      E_t = 10 ** (151.665 - 151.64 * exp(-5.76e-05 * Days_Pregnant))
      
      ME_c_day = 0.025 * BW_kg * (
        ((0.0201 * E_t) * exp(-5.76e-05 * Days_Pregnant)) / k_c
      )
      
      ME_c = ME_c_day * MonthDays * Reproduction_Rate
      
      return(ME_c)
      
    }
  
    feq_deer <- function() {
      
      ME_c_day = 0.7 * Trimester_Factor * LW_kg^0.75
      
      ME_c = ME_c_day * MonthDays * Reproduction_Rate
      
      return(ME_c)
      
    }
  
    feq_sheep <- function() {
        
      BW_kg = 0.09 * LW_kg
    
      E_t = 10 ** (3.322 - 4.979*exp(-6.43e-03 * Days_Pregnant))
      
      ME_c_day = 0.25 * BW_kg * (
        ((0.07372 * E_t) * exp(-6.43e-03 * Days_Pregnant)) / k_c
      )
      
      ME_c = ME_c_day * MonthDays * Reproduction_Rate
    
      return(ME_c)
      
    }
      
    
    case_when(
      Sector == "Dairy" & Days_Pregnant > 0 ~ feq_dairy(),
      Sector == "Beef" & Days_Pregnant > 0 ~ feq_beef(),
      Sector == "Deer" & Trimester_Factor > 0 ~ feq_deer(),
      Sector == "Sheep" & Days_Pregnant > 0 ~ feq_sheep(),
      TRUE ~ 0 # zero when not pregnant
    )  
  
}
```

### ME_Z1

The metabolisable energy received from milk consumed, in relevant
newborn stock classes while weaning off

``` r
eq_fem3_ME_Z1 <- function(
    StockClass, # only applies to newborns
    Milk_Newborn_kg, # derived in preproc from farm data / AIM assumptions
    MilkPowder_Newborn_kg, # derived in preproc from farm data / AIM assumptions
    GE_Milk, # calculated in system
    k_l # calculated in system
) {
  
  # ref FEM equation 3.34
  
  # set NAs to zero
  
  Milk_Newborn_kg <- replace_na(Milk_Newborn_kg, 0)
  MilkPowder_Newborn_kg <- replace_na(MilkPowder_Newborn_kg, 0)
  
  feq_newborns <- function() {
    
    ME_Z1 = (Milk_Newborn_kg + MilkPowder_Newborn_kg) * GE_Milk / k_l
    
    return(ME_Z1)
    
  }
  
  case_when(
    StockClass %in% stockClassList_newborns ~ feq_newborns(),
    TRUE ~ 0
  )
  
}
```

### ME_Graze

The metabolisable energy required to roam for grazing. Applies to cattle
and sheep

``` r
eq_fem3_ME_Graze <- function(
    Sector, # sectoral variation
    DMD_pct_Diet_AIM, # calculated in system.
    ME_m, # calculated in system
    ME_p, # calculated in system
    ME_Z1, # calculated in system
    LW_kg, # assumedParameters lookup
    k_m, # calculated in system
    ME_Diet_AIM, # assumedParameters lookup
    ME_c, # calculated in system
    MonthDays
) {
  
  # ref FEM equations 3.35 - 3.36
  
  feq_cattle_sheep <- function(C, GF, T) {
    
    ME_Graze_day = (
      (C * (0.9 - DMD_pct_Diet_AIM)) * (ME_m + ME_p + ME_c - ME_Z1) / MonthDays + 
      (0.05 * T / (GF + 3)) * ME_Diet_AIM) * LW_kg / (
          k_m * ME_Diet_AIM - C * LW_kg * (0.9 - DMD_pct_Diet_AIM)
    )
    
    ME_Graze = ME_Graze_day * MonthDays
    
  return(ME_Graze)
    
  }
    
  case_when(
    Sector == "Beef" ~ feq_cattle_sheep(C=0.006, GF=3.5, T=1.5),
    Sector == "Dairy" ~ feq_cattle_sheep(C=0.006, GF=3.5, T=1),
    Sector == "Sheep" ~ feq_cattle_sheep(C=0.05, GF=2.5, T=1.5),
    Sector == "Deer" ~ 0 # AIM: ME_Graze does not apply to Deer
  )
  
}
```

## ME_total

The individual components of ME sum to give ME_total_pre_ME_Z: the
amount of metabolisable energy used (i.e. required) by an animal in a
given month

This is then adjusted for ME_Z to give ME_total: the amount of
metabolisable energy to be satisfied by dry matter intake (i.e. the
farm-level diet which excludes milk)

The latter value is used in subsequent equations

``` r
eq_fem3_ME_total_pre_ME_Z <- function(
    # base ME components: all stock classes
    ME_m, # calculated in system
    # graze/conceptus/production ME components: specific stock classes
    ME_Graze, # calculated in system
    ME_c, # calculated in system
    ME_p # calculated in system
) {
  
  # ref FEM equation 3.37
  
  # calculation of total metabolisable energy, before adjustments for ME_Z
  
  ME_total_pre_ME_Z <- ME_m + ME_p + ME_Graze + ME_c
  
  return(ME_total_pre_ME_Z)
  
}

eq_fem3_ME_total <- function(
    ME_total_pre_ME_Z, # calculated in system
    ME_Z0_pct, # calculated in system
    ME_Z1 # calculated in system
) {
  
  # ref FEM equation 3.38
  
  # calculation of total metabolisable energy, after adjustments for ME_Z
  
  # set NAs to 0
  ME_Z0_pct = replace_na(ME_Z0_pct, 0)
  
  ME_total <- pmax((ME_total_pre_ME_Z - ME_Z1) * (1 - ME_Z0_pct), 0)
  
  return(ME_total)
  
}
```

## Farm-level Diet

This is a relatively complex function within the system. Parts 1 and 3
of the function handle pre and post processing respectively. Related
equations are split into five sequentially numbered sections in Part 2.
Uniquely this function **ingests multiple dataframes** and **outputs
multiple values**, the farm-level diet parameters:

-   ME_Diet
-   DMD_pct_Diet
-   N_pct_Diet

``` r
eq_fem4_derive_farm_diet_parameters <- function(
    in_df, # livestock module intermediate calc_df after ME_totals have been calculated
    SuppFeed_DryMatter_df, # farm data input of supplementary feed purchased
    SuppFeed_SectoralAllocation_df, # farm data input of the % of supplementary feed purchased is relevant to sector being calculated
    lookup_nutrientProfile_supplements_df, # lookup table of supplementary feed nutritional profiles
    lookup_nutrientProfile_pasture_df # lookup table of pasture nutritional profiles
) {
  
  # ref FEM equations 4.1 - 4.18
  
  # Part 1: Data Prep
  
  # pasture nutritional profiles are different for dairy vs. non-dairy: find relevant sector from in_df
  pastureSector = case_when(
    in_df$Sector[1] == "Dairy" ~ "Dairy",
    TRUE ~ "NonDairy"
  )
  
  # apply sectoral allocation to supplementary feed
  supps_df <- SuppFeed_DryMatter_df %>%
    inner_join(
      SuppFeed_SectoralAllocation_df,
      by="Entity__PeriodEnd"
    ) %>%
    mutate(
      SuppFeed_Allocation = replace_na(SuppFeed_Allocation, 0),
      Supp_t_annual = Dry_Matter_t * SuppFeed_Allocation
    ) %>%
    select(-SuppFeed_Allocation)
  
  # Part 2: Calculation to derive farm-level diet parameters
  
  # Part 2.1: Combined supplements diet (excl. pasture) nutritional profile
  
  supps_df <- supps_df %>% 
    inner_join(
      lookup_nutrientProfile_supplements_df,
      by="SupplementName"
    ) %>%
    select(Entity__PeriodEnd, SupplementName, ME_Supp, DMD_pct_Supp, N_pct_Supp, Supp_t_annual) %>%
    group_by(Entity__PeriodEnd) %>%
    mutate(
      AllSupps_t_annual = sum(Supp_t_annual),
      Supp_allocation = Supp_t_annual / AllSupps_t_annual
    ) %>%
    ungroup()
  
  supps_df_agg <- supps_df %>%
    summarise(
      .by = Entity__PeriodEnd,
      ME_AllSupps = sum(ME_Supp * Supp_allocation),
      DMD_pct_AllSupps = sum(DMD_pct_Supp * Supp_allocation),
      N_pct_AllSupps = sum(N_pct_Supp * Supp_allocation),
      AllSupps_t_annual = first(AllSupps_t_annual),
    )
  
  # Part 2.2: Energy Requirements (per month of all animals in sector)
  
  farm_stockEnergy_df <- in_df %>%
    mutate(
      ME_total_StockClassTotal = ME_total * StockCount_mean
    )
  
  farm_diet_df1 <- farm_stockEnergy_df %>%
    summarise(
      .by = c(Entity__PeriodEnd, Month, Pasture_Region),
      ME_total_SectorTotal = sum(ME_total_StockClassTotal)
    ) %>%
    group_by(Entity__PeriodEnd) %>%
    mutate(
      ME_total_allocation = ME_total_SectorTotal / sum(ME_total_SectorTotal)
    ) %>%
    ungroup() %>%
    left_join(supps_df_agg, by="Entity__PeriodEnd") # left_join req'd
  
  # Part 2.3: Determine tonnages and energy contribution of supplements and pasture:
  
  farm_diet_df2 <- farm_diet_df1 %>%
    mutate(
      AllSupps_t = AllSupps_t_annual * ME_total_allocation,
      AllSupps_ME_contribution_SectorTotal = pmin(
        (AllSupps_t * 1000 * ME_AllSupps),
        ME_total_SectorTotal
        # pmin ensures AllSupps_ME_contribution_SectorTotal is not greater than ME_total_SectorTotal,
        # to handle edge cases where farm data inputs of supplementary feed exceed energy requirements
      )
    ) %>% mutate_all(
      ~replace_na(., 0)
    ) %>%
    mutate(Pasture_ME_contribution_SectorTotal = ME_total_SectorTotal - AllSupps_ME_contribution_SectorTotal)
  
  # Part 2.4: Calculate total tonnages and proportion of supplements and pasture in overall diet:
  
  farm_diet_df3 <- farm_diet_df2 %>%
    inner_join(
      lookup_nutrientProfile_pasture_df %>% filter(Sector == pastureSector),
      by=c("Month", "Pasture_Region")
    ) %>%
    filter(Sector == pastureSector) %>%
    select(-Sector) %>%
    mutate(
      Pasture_t = Pasture_ME_contribution_SectorTotal / (1000 * ME_Pasture),
      Diet_t = AllSupps_t + Pasture_t,
      AllSupps_allocation = AllSupps_t / Diet_t,
      Pasture_allocation = Pasture_t / Diet_t
    )
  
  # Part 2.5: Derive nutrient profile of overall diet:
  
  farm_diet_df4 <- farm_diet_df3 %>%
    mutate(
      ME_Diet = AllSupps_allocation * ME_AllSupps + Pasture_allocation * ME_Pasture,
      DMD_pct_Diet = AllSupps_allocation * DMD_pct_AllSupps + Pasture_allocation * DMD_pct_Pasture,
      N_pct_Diet = AllSupps_allocation * N_pct_AllSupps + Pasture_allocation * N_pct_Pasture
    )
  
  # Part 3: Output formatting
  
  # select final output columns from Part 2 outputs
  output_cols_df <- farm_diet_df4 %>%
    select(
      Entity__PeriodEnd, Month,
      ME_Diet, DMD_pct_Diet, N_pct_Diet,
      ME_Pasture, DMD_pct_Pasture, N_pct_Pasture # used as helpers
    )
  
  out_df <- in_df %>%
    inner_join(
      output_cols_df,
      by=c("Entity__PeriodEnd", "Month")
    ) %>% 
    mutate(
      # coalesce any NA results (e.g. if no supplementary feed data input) to pasture values
      ME_Diet = coalesce(ME_Diet, ME_Pasture),
      DMD_pct_Diet = coalesce(DMD_pct_Diet, DMD_pct_Pasture),
      N_pct_Diet = coalesce(N_pct_Diet, N_pct_Pasture)
    ) %>%
    select(-ME_Pasture, -DMD_pct_Pasture, -N_pct_Pasture) # remove helper cols
    
    return(out_df)
  
}
```

## Dry Matter Intake

Mass of diet consumed based on energy requirements (ME_total) and energy
content of diet (ME_Diet)

``` r
eq_fem4_DMI_kg <- function(
    ME_total, # calculated in system
    ME_Diet # calculated in system
    ) {
  
  # ref FEM equation 4.19

  DMI_kg <- ME_total / ME_Diet
  
  return(DMI_kg)

}
```

## Nitrogen Intake and Excretion

### Nitrogen Intake

The mass of Nitrogen consumed by the animal from dry matter intake
(and/or milk for newborn stock classes)

``` r
eq_fem5_N_Intake_kg <- function(
    Sector, # sectoral variation
    StockClass, # StockClass variation
    Milk_Newborn_kg=0, # derived in preproc from farm data / AIM assumptions
    Milk_Protein_pct=0, # assumedParameters lookup, or for mature milking cows: farm data inputs
    MilkPowder_Newborn_kg=0, # derived in preproc from farm data / AIM assumptions
    MilkPowder_Protein_pct=0, # assumedParameters lookup
    DMI_kg, # calculated in system
    N_pct_Diet, # calculated in system
    N_Protein_pct=0.16 # set by AIM
    ) {
  
  # ref FEM equations 5.1 - 5.2
  
  # set NAs to 0:
  Milk_Newborn_kg <- replace_na(Milk_Newborn_kg, 0)
  Milk_Protein_pct <- replace_na(Milk_Protein_pct, 0)
  MilkPowder_Newborn_kg <- replace_na(MilkPowder_Newborn_kg, 0)
  MilkPowder_Protein_pct <- replace_na(MilkPowder_Protein_pct, 0)
  
  # calculate nitrogen intake from milk ingested, Z3:
  
  Z3 <- (Milk_Newborn_kg * Milk_Protein_pct + MilkPowder_Newborn_kg * MilkPowder_Protein_pct) * N_Protein_pct
  
  # calculate total nitrogen intake:
  
  N_Intake_kg <- DMI_kg * N_pct_Diet + Z3
  
  return(N_Intake_kg)
  
}
```

### Nitrogen Retained

Depending on Sector and StockClass, some Nitrogen intake is used for
production (and therefore non-excretion) use. These uses are:

-   Milk

-   Live Weight Gain

-   Fetal Weight Gain

-   Wool

-   Velvet

The Nitrogen utilised for the above is subtracted from Nitrogen intake
to find Nitrogen excreted

``` r
eq_fem5_N_Retained_Milk_kg <- function(
    Sector, # varies between dairy and non-dairy
    StockClass, # only applied to breeding mother stock classes
    Milk_Yield_kg=0, # calculated in system (from farmer input) for milking cows only
    Milk_Mother_kg=0, # assumedParameters lookup, used for non-dairy sector milking mothers
    Milk_Protein_pct, # calculated in system for mature milking cows, ingested for other stock classes
    Reproduction_Rate=1, # assumedParameters lookup
    N_Protein_pct=0.16
) {
  
  # ref FEM equations 5.3a - 5.3b
  
  # set NAs to 1
  Reproduction_Rate <- replace_na(Reproduction_Rate, 1)
  
  # for dairy we use milk for production: Milk_Yield_kg and exclude Reproduction_Rate
  
  feq_dairy_milkingCows <- function() {
    
    N_Retained_Milk_kg <- Milk_Yield_kg * Milk_Protein_pct * N_Protein_pct
      
    # for other sectors we use milk for newborn: Milk_Mother_kg Note this excludes MilkPowder which sits in it's own parameter:
      
    }
    
    feq_nonDairy_milkingMothers <- function() {
      
      N_Retained_Milk_kg <- Milk_Mother_kg * Milk_Protein_pct * N_Protein_pct * Reproduction_Rate
    
     return(N_Retained_Milk_kg)
  }
  
  case_when(
    Sector == "Dairy" & StockClass %in% stockClassList_lactatingMothers & Milk_Yield_kg > 0 ~ feq_dairy_milkingCows(),
    Sector != "Dairy" & StockClass %in% stockClassList_lactatingMothers & Milk_Mother_kg > 0 ~ feq_nonDairy_milkingMothers(),
    TRUE ~ 0
  )
  
}

eq_fem5_N_Retained_LWG_kg <- function(
    Sector, # sectoral variation
    LWG_kg # assumedParameters lookup
    ) {
  
  # ref FEM equation 5.4
  
  N_bodyTissue_pct_cattle = 0.0326
  N_bodyTissue_pct_deer = 0.0371
  N_bodyTissue_pct_sheep = 0.026
  
  feq_all <- function(N_bodyTissue_pct){
    
    N_Retained_LWG_kg <- LWG_kg * N_bodyTissue_pct
    
  }
  
  case_when(
    Sector %in% c("Beef", "Dairy") ~ feq_all(N_bodyTissue_pct_cattle),
    Sector == "Deer" ~ feq_all(N_bodyTissue_pct_deer),
    Sector == "Sheep" ~ feq_all(N_bodyTissue_pct_sheep),
  )
  
}

eq_fem5_N_Retained_FWG_kg <- function(
    Sector, # sectoral variation
    FWG_kg, # assumedParameters lookup
    Reproduction_Rate # assumedParameters lookup
    ) {
  
  # ref FEM equation 5.5
  
  N_bodyTissue_pct_cattle = 0.0326
  N_bodyTissue_pct_deer = 0.0371
  N_bodyTissue_pct_sheep = 0.026
  
  feq_all <- function(N_bodyTissue_pct){
    
    N_Retained_FWG_kg <- FWG_kg * N_bodyTissue_pct * Reproduction_Rate
    
  }
  
  case_when(
    Sector %in% c("Beef", "Dairy") ~ feq_all(N_bodyTissue_pct_cattle),
    Sector == "Deer" ~ feq_all(N_bodyTissue_pct_deer),
    Sector == "Sheep" ~ feq_all(N_bodyTissue_pct_sheep),
  )
  
}

# sectoral N_Retained calculations: Deer (Velvet) and Sheep (Wool)

eq_fem5_N_Retained_Velvet_kg <- function(
    Velvet_Yield_kg, # assumedParameters lookup
    N_Velvet_pct=0.09 # set by AIM
) {
  
  # ref FEM equation 5.6
  
  N_Retained_Velvet_kg = Velvet_Yield_kg * N_Velvet_pct
  
  return(N_Retained_Velvet_kg)
  
}

eq_fem5_N_Retained_Wool_kg <- function(
    Wool_Yield_kg, # assumedParameters lookup
    N_Wool_pct=0.134 # set by AIM
) {
  
  # ref FEM equation 5.7
  
  N_Retained_Wool_kg = Wool_Yield_kg * N_Wool_pct
  
  return(N_Retained_Wool_kg)
  
}
```

### Nitrogen Excreted

Various Nitrous Oxide emissions factors are calculated from the N
excreted via dung and urine respectively. First the N_Excretion_kg is
calculated and then this apportioned to an excretion pathway

``` r
eq_fem5_N_Excretion_kg <- function(
    N_Intake_kg, # calculated in system
    N_Retained_Milk_kg=0, # calculated in system
    N_Retained_LWG_kg=0, # calculated in system
    N_Retained_FWG_kg=0, # calculated in system
    N_Retained_Velvet_kg=0, # calculated in system
    N_Retained_Wool_kg=0 # calculated in system
) {
  
  # ref FEM equation 7.8
  
  # set NAs to 0
  N_Retained_Milk_kg <- replace_na(N_Retained_Milk_kg, 0)
  N_Retained_LWG_kg <- replace_na(N_Retained_LWG_kg, 0)
  N_Retained_FWG_kg <- replace_na(N_Retained_FWG_kg, 0)
  N_Retained_Velvet_kg <- replace_na(N_Retained_Velvet_kg, 0)
  N_Retained_Wool_kg <- replace_na(N_Retained_Wool_kg, 0)
  
  N_Excretion_kg <- N_Intake_kg - (N_Retained_Milk_kg + N_Retained_LWG_kg + N_Retained_FWG_kg + N_Retained_Velvet_kg + N_Retained_Wool_kg)
  
  N_Excretion_kg <- pmax(N_Excretion_kg, 0)
  
  return(N_Excretion_kg)
  
}
```

### Apportioning Nitrogen Excreted to Dung and Urine

``` r
eq_fem5_N_Dung_kg <- function(
  Sector, # sectoral variation
  N_pct_Diet, # calculated in system
  DMI_kg, # calculated in system
  N_Intake_kg, # calculated in system
  MonthDays 
  ) {
  
  # ref FEM equations 5.9 - 5.11
  
  feq_cattle_deer <- function() {
    
    N_Dung_kg_day = (-4.623 + (N_pct_Diet * 100 * 1.970) + (DMI_kg/MonthDays * 7.890)) * 0.001
    
    N_Dung_kg = pmax(N_Dung_kg_day * MonthDays, 0)
    
    return(N_Dung_kg)
    
  }

  feq_sheep <- function() {
    
    N_Intake_g_day = (N_Intake_kg * 1000) / MonthDays
  
    N_Dung_kg_day = (2.230 + (N_Intake_g_day * 0.299) + ((N_pct_Diet*100)^2 * -0.237)) * 0.001
    
    N_Dung_kg = pmax(N_Dung_kg_day * MonthDays, 0)
  
    return(N_Dung_kg)
  
  }
  
  case_when(
    Sector %in% c("Beef", "Dairy", "Deer") ~ feq_cattle_deer(),
    Sector == "Sheep" ~ feq_sheep(),
  )
  
}

eq_fem5_N_Urine_kg <- function(
  N_Excretion_kg, # calculated in system
  N_Dung_kg # calculated in system
  ) {
  
  # ref FEM equation 5.12
  
  N_Urine_kg <- pmax(N_Excretion_kg - N_Dung_kg, 0)
  
  return(N_Urine_kg)
  
}
```

## Enteric Fermentation Methane Emissions

Methane is a by-product of fermentation of food in the rumen of ruminant
animals and largely depends on dry matter intake consumed

The majority of farm-level GHG emissions (in CO2 equivalent terms)
happens here

``` r
eq_fem6_CH4_Enteric_kg <- function(
  Sector, # sectoral variation
  StockClass, # StockClass variation
  DMI_kg, # calculated in system
  ME_Diet, # calculated in system
  MonthDays
  ) {
  
  # ref FEM equations 6.1 - 6.4
  
  # set Methane Conversion Ratio for Cattle and Deer
  
  MCR_Cattle = 21.6
  MCR_Deer = 21.25
  
  feq_cattle_deer <- function(MCR) {
    
    CH4_Enteric_kg <- DMI_kg * ( MCR / 1000 )
    
    return(CH4_Enteric_kg)
    
    }
  
  feq_sheep_lambs <- function() {
    
    DMI_kg_day <- DMI_kg / MonthDays
    
    CH4_Enteric_kg_day <- (11.705 / 1000) * exp(0.05 * ME_Diet) * (DMI_kg_day)^0.734
    
    CH4_Enteric_kg <- CH4_Enteric_kg_day * MonthDays
    
    return(CH4_Enteric_kg)
    
  }
  
  feq_sheep_nonlambs <- function() {
    
    DMI_kg_day <- DMI_kg / MonthDays
    
    CH4_Enteric_kg_day <- (21.977 / 1000) * DMI_kg_day^0.765
    
    CH4_Enteric_kg <- CH4_Enteric_kg_day * MonthDays
    
    return(CH4_Enteric_kg)
    
  }
  
  case_when(
    Sector %in% c("Beef", "Dairy") ~ feq_cattle_deer(MCR=MCR_Cattle),
    Sector == "Deer" ~ feq_cattle_deer(MCR=MCR_Deer),
    Sector == "Sheep" & StockClass == "Lambs" ~ feq_sheep_lambs(),
    Sector == "Sheep" & StockClass != "Lambs" ~ feq_sheep_nonlambs(),
    TRUE ~ NA
  )
  
}
```

## Excretion Emissions

### Faecal Dry Matter

``` r
eq_fem7_FDM_kg <- function(
    DMI_kg, # calculated in system,
    DMD_pct_Diet # calculated in system
    ) {
  
  # ref FEM equation 7.1
  
  FDM_kg <- DMI_kg * (1 - DMD_pct_Diet)
  
  return(FDM_kg)
  
}
```

### Allocation of Excretion to Pasture and Lagoons

The majority of stock classes deposit all excretion to pasture. However,
mature milking dairy cows deposit 9.4% of excretion in the months
they’re milking (from “Trends in dairy effluent management (2017) p.25)

The allocation to pasture is simply all of the excretion not deposited
as effluent

``` r
eq_fem7_DungUrine_to_Lagoon_pct <- function(
    StockClass, # StockClass variation
    Milk_Yield_kg # calculated in system
    ) {
  
  # ref FEM equations 7.2a - 7.2b
  
  DungUrine_to_Lagoon_pct = case_when(
    StockClass == "Milking Cows Mature" & Milk_Yield_kg > 0 ~ 0.094,
    TRUE ~ 0
  )
  
  return(DungUrine_to_Lagoon_pct)
  
}

eq_fem7_DungUrine_to_Pasture_pct <- function(
    DungUrine_to_Lagoon_pct # calculated in system
    ) {
  
  # ref FEM equation 7.3
  
  DungUrine_to_Pasture_pct = 1 - DungUrine_to_Lagoon_pct
  
  return(DungUrine_to_Pasture_pct)
  
}
```

### Pasture Excretion Emissions

Grazing animal excretion methane emissions:

``` r
eq_fem7_CH4_Pasture_Dung_kg <- function(
    Sector, # sectoral variation
    DungUrine_to_Pasture_pct, # calculated in system
    FDM_kg # calculated in system
) {
    
    # ref FEM equation 7.2
  
    # AIM sets the following methane yields (kg CH4/kg FDM) by species:
  
    FDM_CH4_Yield_kg_Cattle = 0.00098198
    FDM_CH4_Yield_kg_Deer = 0.000914788
    FDM_CH4_Yield_kg_Sheep = 0.000691
    
    feq <- function(FDM_CH4_Yield_kg) {
      
      CH4_Pasture_Dung_kg <- FDM_kg * DungUrine_to_Pasture_pct * FDM_CH4_Yield_kg
      
      return(CH4_Pasture_Dung_kg)
      
    }
    
    case_when(
     Sector %in% c("Beef", "Dairy") ~ feq(FDM_CH4_Yield_kg_Cattle),
     Sector == "Deer" ~ feq(FDM_CH4_Yield_kg_Deer),
     Sector == "Sheep" ~ feq(FDM_CH4_Yield_kg_Sheep),
     TRUE ~ NA
   )
  
}
```

Grazing animal excretion direct nitrous oxide emissions:

*Note N2O_Pasture_Urine_Direct_kg is the only place where slope factors
come into play. These are based on the primary farm class & production
region of the farm*

``` r
eq_fem7_N2O_Pasture_Urine_Direct_kg <- function(
  Sector, # sectoral variation
  StockClass, # StockClass variation
  N_Urine_kg, # calculated in system
  DungUrine_to_Pasture_pct, # calculated in system
  N_Urine_Flattish_pct=NA, # slopeFactors lookup based on farm data inputs
  N_Urine_Steep_pct=NA # slopeFactors lookup based on farm data inputs
  ) {
  
  # ref FEM equations 7.3 - 7.5
  
  # set NAs to 0
  N_Urine_Flattish_pct <- replace_na(N_Urine_Flattish_pct, 0)
  N_Urine_Steep_pct <- replace_na(N_Urine_Steep_pct, 0)
  
  # AIM sets the following emission factors for urine based on species and steepness of land grazed on
  
  EF_3_urine_low_cattle = 0.0098
  EF_3_urine_steep_cattle = 0.0033
  
  EF_3_urine_low_deer = 0.0074
  EF_3_urine_steep_deer = 0.0020
  
  EF_3_urine_low_sheep = 0.0050
  EF_3_urine_steep_sheep = 0.0008
  
  # mature milking cows: assume all pasture excretion is on flat land
  
  feq_milkingCows <- function(EF_3_urine_low) {
    
    N2O_Pasture_Urine_Direct_kg <- 44/28 * N_Urine_kg * EF_3_urine_low * DungUrine_to_Pasture_pct
  
    return(N2O_Pasture_Urine_Direct_kg)
    
  }
  
  # all other stock classes in all sectors use a weighted slope factor based on farm region/class, excrete 100% to pasture
  
  feq_non_milkingCows <- function(EF_3_urine_low, EF_3_urine_steep) {
  
    Weighted_Slope_Factor = (N_Urine_Flattish_pct * EF_3_urine_low + N_Urine_Steep_pct * EF_3_urine_steep)
  
    N2O_Pasture_Urine_Direct_kg <- 44/28 * N_Urine_kg * Weighted_Slope_Factor
  
    return(N2O_Pasture_Urine_Direct_kg)
      
  }
  
  case_when(
    Sector == "Dairy" & StockClass == "Milking Cows Mature" ~ feq_milkingCows(EF_3_urine_low_cattle),
    Sector == "Dairy" & StockClass != "Milking Cows Mature" ~ feq_non_milkingCows(EF_3_urine_low_cattle, EF_3_urine_steep_cattle),
    Sector == "Beef" ~ feq_non_milkingCows(EF_3_urine_low_cattle, EF_3_urine_steep_cattle),
    Sector == "Deer" ~ feq_non_milkingCows(EF_3_urine_low_deer, EF_3_urine_steep_deer),
    Sector == "Sheep" ~ feq_non_milkingCows(EF_3_urine_low_sheep, EF_3_urine_steep_sheep),
    TRUE ~ NA
  ) 
  
}

eq_fem7_N2O_Pasture_Dung_Direct_kg <- function(
  N_Dung_kg, # calculated in system
  DungUrine_to_Pasture_pct, # calculated in system
  EF_3_Dung=0.0012 # set by AIM
) {
  
  # ref FEM equation 7.7
  
  N2O_Pasture_Dung_Direct_kg = 44/28 * EF_3_Dung * DungUrine_to_Pasture_pct * N_Dung_kg
  
  return(N2O_Pasture_Dung_Direct_kg)
  
}
```

Grazing animal excretion indirect leached nitrous oxide emissions:

``` r
eq_fem7_N2O_Pasture_Urine_Leach_kg <- function(
  N_Urine_kg, # calculated in system
  DungUrine_to_Pasture_pct, # calculated in system
  EF_5=0.0075, # set by AIM
  frac_leach_pasture=0.08 # set by AIM
) {
  
  # ref FEM equation 7.7
  
  N2O_Pasture_Urine_Leach_kg = 44/28 * EF_5 * frac_leach_pasture * DungUrine_to_Pasture_pct * N_Urine_kg
  
  return(N2O_Pasture_Urine_Leach_kg)
  
}

eq_fem7_N2O_Pasture_Dung_Leach_kg <- function(
  N_Dung_kg, # calculated in system
  DungUrine_to_Pasture_pct, # calculated in system
  EF_5=0.0075, # set by AIM
  frac_leach_pasture=0.08 # set by AIM
) {
  
  # ref FEM equation 7.8
  
  N2O_Pasture_Dung_Leach_kg = 44/28 * EF_5 * frac_leach_pasture * DungUrine_to_Pasture_pct * N_Dung_kg
  
  return(N2O_Pasture_Dung_Leach_kg)
  
}
```

Grazing animal excretion indirect volatilised nitrous oxide emissions:

``` r
eq_fem7_N2O_Pasture_Urine_Volat_kg <- function(
  N_Urine_kg, # calculated in system
  DungUrine_to_Pasture_pct, # calculated in system
  EF_4=0.01, # set by AIM
  frac_NOx_and_NH3=0.1 # set by AIM
) {
  
  # ref FEM equation 7.9
  
  N2O_Pasture_Urine_Volat_kg = 44/28 * EF_4 * frac_NOx_and_NH3 * DungUrine_to_Pasture_pct * N_Urine_kg
  
  return(N2O_Pasture_Urine_Volat_kg)
  
}

eq_fem7_N2O_Pasture_Dung_Volat_kg <- function(
  N_Dung_kg, # calculated in system
  DungUrine_to_Pasture_pct, # calculated in system
  EF_4=0.01, # set by AIM
  frac_NOx_and_NH3=0.1 # set by AIM
) {
  
  # ref FEM equation 7.10
  
  N2O_Pasture_Dung_Volat_kg = 44/28 * EF_4 * frac_NOx_and_NH3 * DungUrine_to_Pasture_pct * N_Dung_kg
  
  return(N2O_Pasture_Dung_Volat_kg)
  
}
```

### Effluent Excretion Emissions

CH4 and volatilised N2O emissions from excretion to Anaerobic Lagoons

*Note effluent is only relevant to mature milking cows and only for
months when milk production is occurring.*

``` r
eq_fem7_CH4_Effluent_Lagoon_kg <- function(
    StockClass, # function only applies to Mature Milking Cows, else zero
    DungUrine_to_Lagoon_pct, # calculated in system
    FDM_kg, # calculated in system
    Ash_pct=0.08, # set by AIM
    B0=0.24, # set by AIM
    MCF=0.74 # set by AIM
) {
  
  # ref FEM equation 7.11
  
   feq_milkingDairyCows <- function() {
     
     CH4_Effluent_Lagoon_kg <- FDM_kg * (1 - Ash_pct) * B0 * 0.67 * MCF * DungUrine_to_Lagoon_pct
     
     return(CH4_Effluent_Lagoon_kg)
     
   }

  case_when(
    StockClass == "Milking Cows Mature" ~ feq_milkingDairyCows(),
    TRUE ~ 0
  )
  
}

eq_fem7_N2O_Effluent_Lagoon_Volat_kg <- function(
    StockClass, # function only applies to Mature Milking Cows, else zero
    DungUrine_to_Lagoon_pct, # calculated in system
    N_Excretion_kg, # calculated in system
    EF_4=0.01, # set by AIM
    frac_gasMS_AL=0.35 # set by AIM
) {
  
  # ref FEM equation 7.12
  
  feq_milkingDairyCows <- function() {
  
    N2O_Effluent_Lagoon_Volat_kg = N_Excretion_kg * DungUrine_to_Lagoon_pct * EF_4 * frac_gasMS_AL * 44/28
    
    return(N2O_Effluent_Lagoon_Volat_kg)
    
  }
  
  case_when(
    StockClass == "Milking Cows Mature" ~ feq_milkingDairyCows(),
    TRUE ~ 0
  )
  
}
```

### Effluent Spread as Organic Fertiliser Emissions

*Note effluent here is limited to mature milking cow effluent from
lagoons spread to pasture. It only applies to mature milking cows and
only when milk production is occurring.*

``` r
eq_fem7_N_Effluent_Spread_kg <- function(
  N_Excretion_kg, # calculated in system
  DungUrine_to_Lagoon_pct # calculated in system
) {
  
  # ref FEM equation 7.13
  
  N_Effluent_Spread_kg = N_Excretion_kg * DungUrine_to_Lagoon_pct
  
  return(N_Effluent_Spread_kg)
  
}

eq_fem7_N2O_Effluent_Spread_Direct_kg <- function(
  N_Effluent_Spread_kg, # calculated in system
  frac_gasMS_AL=0.35, # set by AIM
  EF_1_Dairy=0.0025 # set by AIM
) {
  
  # ref FEM equation 7.14
  
  N2O_Effluent_Spread_Direct_kg = 44/28 * ( N_Effluent_Spread_kg * (1 - frac_gasMS_AL) * EF_1_Dairy )
  
  return(N2O_Effluent_Spread_Direct_kg)
  
}

eq_fem7_N2O_Effluent_Spread_Leach_kg <- function(
  N_Effluent_Spread_kg, # calculated in system
  frac_gasMS_AL=0.35, # set by AIM
  frac_leach_eff_spread=0.08, # set by AIM
  EF_5=0.0075 # set by AIM
) {
  
  # ref FEM equation 7.15
  
  N2O_Effluent_Spread_Leach_kg = 44/28 * ( N_Effluent_Spread_kg * (1 - frac_gasMS_AL) * frac_leach_eff_spread * EF_5 )
  
  return(N2O_Effluent_Spread_Leach_kg)
  
}

eq_fem7_N2O_Effluent_Spread_Volat_kg <- function(
  N_Effluent_Spread_kg, # calculated in system
  frac_gasMS_AL=0.35, # set by AIM
  frac_NOx_and_NH3=0.1, # set by AIM
  EF_4=0.01 # set by AIM
) {
  
  # ref FEM equation 7.16
  
  N2O_Effluent_Spread_Volat_kg = 44/28 * ( N_Effluent_Spread_kg * (1 - frac_gasMS_AL) * frac_NOx_and_NH3 * EF_4 )
  
  return(N2O_Effluent_Spread_Volat_kg)
  
}
```

# Module 2: Fertiliser Emissions

Note there are 3 types of synthetic fertiliser considered:

-   Urease-inhibitor coated Urea

-   Urea (uncoated)

-   Non-urea nitrogen-containing synthetic fertiliser (referred to in
    shorthand as otherSynthFert)

Only direct emission from organic fertiliser is considered. This does
not include dairy effluent spread onto pasture, which is described in
the previous section. There are 2 sources of organic fertiliser:

-   Manure (from swine and poultry)

-   Non-manure

Urea, lime and dolomite have direct pathways of CO2 emissions, the only
emissions of CO2 across FEM

## Synthetic Fertiliser Nitrous Oxide Emissions

``` r
eq_fem8_N2O_SynthFert_Direct_t <- function(
    N_Urea_Coated_t, # farm data input
    N_Urea_Uncoated_t, # farm data input
    N_NonUrea_SyntheticFert_t, # farm data input. Note other being "non-urea N containing synthetic fert"
    EF_1_Urea=0.0059, # set by AIM
    EF_1_OtherSynthFert=0.01 # set by AIM
    ) {
    
    # ref FEM equations 8.1 - 8.2
    
    N_Urea_all_t <- N_Urea_Coated_t + N_Urea_Uncoated_t
    
    N2O_SynthFert_Direct_t <- 44/28 * ((N_Urea_all_t * EF_1_Urea) + (N_NonUrea_SyntheticFert_t * EF_1_OtherSynthFert))
    
    return(N2O_SynthFert_Direct_t)
    
}


eq_fem8_N2O_SynthFert_Leach_t <- function(
    N_Urea_Coated_t, # farm data input
    N_Urea_Uncoated_t, # farm data input
    N_NonUrea_SyntheticFert_t, # farm data input
    EF_5=0.0075, # set by AIM
    frac_leach_synthFert=0.082 # set by AIM
    ) {
  
  # ref FEM equations 8.3 - 8.4
  
  N_synthFert_t <- N_Urea_Coated_t + N_Urea_Uncoated_t + N_NonUrea_SyntheticFert_t
  
  N2O_SynthFert_Leach_t <- 44/28 * (N_synthFert_t * EF_5 * frac_leach_synthFert)
  
  return(N2O_SynthFert_Leach_t)
  
}

eq_fem8_N2O_SynthFert_Volat_t <- function(
    N_Urea_Coated_t, # farmer input
    N_Urea_Uncoated_t, # farmer input
    N_NonUrea_SyntheticFert_t, # farmer input
    EF_4=0.01,
    frac_gasf_coated=0.055,
    frac_gasf_uncoated=0.1
) {
  
  # ref FEM equation 8.5
  
  N2O_SynthFert_Volat_t <- 44/28 * EF_4 * (
    N_Urea_Coated_t * frac_gasf_coated +
    (N_Urea_Uncoated_t + N_NonUrea_SyntheticFert_t) * frac_gasf_uncoated
    )
  
  return(N2O_SynthFert_Volat_t)
  
}
```

## Synthetic Fertiliser Carbon Dioxide Emissions

``` r
eq_fem8_CO2_SynthFert_t <- function(
    N_Urea_Coated_t, # farm data input
    N_Urea_Uncoated_t, # farm data input
    C_pct_Urea=0.2, # set by AIM
    corr_CO2=44/12 # set by AIM
    ) {
  
  # ref FEM equations 8.6 - 8.7
  
  M_urea_all_t <- (N_Urea_Coated_t + N_Urea_Uncoated_t) / 0.46
  
  CO2_SynthFert_t <- M_urea_all_t * C_pct_Urea * corr_CO2

  return(CO2_SynthFert_t)

}
```

## Organic Fertiliser Nitrous Oxide Emissions

``` r
eq_fem8_N2O_OrganicFert_Direct_t <- function(
    N_OrganicFert_t, # farm data input
    EF_1_OrganicFert = 0.006, # set by AIM
    corr_N2O = 44 / 28 # set by AIM
    ) {
  
  N2O_OrganicFert_Direct_t <- corr_N2O * N_OrganicFert_t * EF_1_OrganicFert

  return(N2O_OrganicFert_Direct_t)

}
```

## Lime and Dolomite Carbon Dioxide Emissions

``` r
eq_fem8_CO2_Lime_t <- function(
    Lime_t, # farm data input
    Lime_CaCO3_pct = 0.82, # set by AIM
    EF_Lime = 0.12, # set by AIM
    corr_CO2 = 44 / 12 # set by AIM
    ) {
  
  CO2_Lime_t <- Lime_t * Lime_CaCO3_pct * EF_Lime * corr_CO2

  return(CO2_Lime_t)

}

eq_fem8_CO2_Dolomite_t <- function(
    Dolomite_t, # farm data input
    EF_Dolomite = 0.13, # set by AIM
    corr_CO2 = 44 / 12 # set by AIM
    ) {
  
  CO2_Dolomite_t <- Dolomite_t * EF_Dolomite * corr_CO2

  return(CO2_Dolomite_t)

}
```
