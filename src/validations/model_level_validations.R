
# Verify daily stock rec is never negative
# this occurs when input data for a farm has a stock outflow transaction (sale, death etc.) which exceeds current stock count. 

stockrec_stockcount_not_negative <- function() {
  
  if (nrow(StockLedger_df > 0)) {
    
    StockLedger_agg_altadjusted_df <- StockLedger_df %>% 
      # derive new stock ledger with newborns alternatively adjusted as below:
      # create new Transaction_Date_altadj which simply sets births to first day of month
      # these alternatively adjusted births are referenced from Transaction_Date (farm birth date) rather than adjusted birthdate in the StockLedger_df
      # this catches scenarios not caught by the standard adjustment e.g.: first newborn transaction in StockLedger is a sale before any births occur
      # while permitting situations like: first 2 transactions for a stockclass as e.g.: 100 births in August and selling 100 before mid August
      # note in pre-processing, standard adjustment transfers all birthed newborn births/deaths/movements dates before Farm_Birthdate_max to Farm_Birthdate_mean
      mutate(Transaction_Date_adj = case_when(StockClass %in% stockClassList_newborns ~ Transaction_Date,
                                              TRUE ~ Transaction_Date_adj),
             Transaction_Date_adj = case_when(StockClass %in% stockClassList_newborns & Transaction_Type == "Births" ~ floor_date(Transaction_Date, unit = "month"),
                                              TRUE ~ Transaction_Date_adj)) %>% 
      group_by(Entity__PeriodEnd, StockClass, Date = Transaction_Date_adj) %>%
      summarise(Stock_Change = sum(Stock_Count), .groups = "drop") 
    
    # create daily stock rec
    negative_stockcount_newborns_altadjusted_df <- StockLedger_agg_altadjusted_df %>% 
      select(Entity__PeriodEnd, StockClass) %>%
      distinct() %>% 
      left_join(FarmYear_dates_df %>% select(Entity__PeriodEnd, Date),
                by = "Entity__PeriodEnd") %>%
      unnest(Date) %>%
      left_join(StockLedger_agg_altadjusted_df,
                by = c("Entity__PeriodEnd", "StockClass", "Date")) %>%
      mutate(Stock_Change = replace_na(Stock_Change, 0)) %>%
      group_by(Entity__PeriodEnd, StockClass) %>%
      mutate(StockCount_day = cumsum(Stock_Change)) %>% 
      # find the first offending row
      filter(StockCount_day < 0) %>%
      slice(1) %>% 
      mutate(Entity__PeriodEnd__StockClass__Date = paste0(Entity__PeriodEnd, " (on ", Date, " for ", StockClass, ")"))
    
    if(nrow(negative_stockcount_newborns_altadjusted_df) > 0) {
      stop(paste0("Derived daily Stock Rec negative on the following farms, first observed for the specified StockClass: ",
                  paste(negative_stockcount_newborns_altadjusted_df$Entity__PeriodEnd__StockClass__Date, collapse = ", "), 
                  ". Stock outflows (e.g. sales, deaths) on this date exceed stock on farm."))
    }
    
  }
  
}


# Verify Milking Cows are present in all months dairy milk is produced

dairy_production_cows_present <- function() {
  
  if(any(Dairy_Production_df$Milk_Yield_Herd_L > 0, na.rm = TRUE)) {
    
    months_milk_produced_no_cows_df <- setdiff(Dairy_Production_df %>%
                                                 filter(Milk_Yield_Herd_L > 0) %>%
                                                 select(Entity__PeriodEnd, Month), 
                                               StockRec_monthly_df %>%
                                                 filter(StockClass == "Milking Cows Mature",
                                                        StockCount_mean > 0) %>%
                                                 select(Entity__PeriodEnd, Month)) %>% 
      group_by(Entity__PeriodEnd) %>% 
      summarise(Month = paste(Month, collapse = ", "),
                .groups = "drop") %>% 
      mutate(Entity__PeriodEnd__Month = paste0(Entity__PeriodEnd, " (Month ", Month, ")"))
    
    if(nrow(months_milk_produced_no_cows_df) > 0) {
      stop(paste0("Milking Cows not present on the following farms in the calendar months dairy milk was produced: ", 
                  paste(months_milk_produced_no_cows_df$Entity__PeriodEnd__Month, collapse = ", ")))
    }
    
  }
  
}


# Verify that effluent structures are used (or a 0 input is provided) if there are milking cows on the farm for a particular month

structure_use_month_complete <- function() {
  
  if(any(StockRec_monthly_df[which(StockRec_monthly_df$StockClass == "Milking Cows Mature"), ]$StockCount_mean > 0, na.rm = TRUE)) {
    
    months_cows_present_no_structures_df <- setdiff(StockRec_monthly_df %>%
                                                      filter(StockClass == "Milking Cows Mature",
                                                             StockCount_mean > 0) %>%
                                                      select(Entity__PeriodEnd, Month),
                                                    Effluent_Structure_Use_df %>%
                                                      select(Entity__PeriodEnd, Month)) %>%
      group_by(Entity__PeriodEnd) %>% 
      summarise(Month = paste(Month, collapse = ", "),
                .groups = "drop") %>% 
      mutate(Entity__PeriodEnd__Month = paste0(Entity__PeriodEnd, " (Month ", Month, ")"))
    
    if(nrow(months_cows_present_no_structures_df) > 0) {
      stop((paste0("No effluent structure use input (including 0s) on some months on the following farms where Milking Cows were present: ", 
                   paste(months_cows_present_no_structures_df$Entity__PeriodEnd__Month, collapse = ", "))))
    }
    
  }
  
}


# Verify that effluent structures are not used (0 input or not provided) if there are no milking cows on the farm for a particular month
# prerequisite input-level validations: Effluent_Structure_Use_df$Month is unique within Entity_ID and Period_End and is an element of c(1:12)

structure_use_cows_present <- function() {
  
  if(any(Effluent_Structure_Use_df$Structures_hrs_day > 0, na.rm = TRUE)) {
    
    months_structure_used_no_cows_df <- setdiff(Effluent_Structure_Use_df %>%
                                                  filter(Structures_hrs_day > 0) %>% 
                                                  select(Entity__PeriodEnd, Month),
                                                StockRec_monthly_df %>%
                                                  filter(StockClass == "Milking Cows Mature",
                                                         StockCount_mean > 0) %>%
                                                  select(Entity__PeriodEnd, Month)) %>%
      group_by(Entity__PeriodEnd) %>% 
      summarise(Month = paste(Month, collapse = ", "),
                .groups = "drop") %>% 
      mutate(Entity__PeriodEnd__Month = paste0(Entity__PeriodEnd, " (Month ", Month, ")"))
    
    if(nrow(months_structure_used_no_cows_df) > 0) {
      stop((paste0("Milking Cows not present on some months on the following farms where effluent structures were used: ", 
                   paste(months_structure_used_no_cows_df$Entity__PeriodEnd__Month, collapse = ", "))))
    }
    
  }
  
}


# Verify that solid separators are not used if there are no milking cows on the farm

solid_separator_use_cows_present <- function() {
  
  if(any(FarmYear_df$Solid_Separator_Use, na.rm = TRUE)) {
    
    months_solid_separator_used_no_cows <- setdiff(FarmYear_df %>%
                                                     filter(Solid_Separator_Use) %>% 
                                                     pull(Entity__PeriodEnd),
                                                   StockRec_monthly_df %>%
                                                     filter(StockClass == "Milking Cows Mature",
                                                            StockCount_mean > 0) %>%
                                                     pull(Entity__PeriodEnd) %>% 
                                                     unique())
    
    if(length(months_solid_separator_used_no_cows) > 0) {
      stop((paste0("Milking Cows not present on the following farms where solid separator was used: ", 
                   paste(months_solid_separator_used_no_cows, collapse = ", "))))
    }
    
  }
  
}


# Verify that stock is present on the farm if breeding values are provided for that StockClass

bv_stockclass_present <- function() {
  
  if(nrow(BreedingValues_df > 0)) {
    
    stockclass_with_bv_no_stock_df <- setdiff(BreedingValues_df %>% 
                                                select(Entity__PeriodEnd, StockClass),
                                              StockRec_monthly_df %>%
                                                filter(StockCount_mean > 0) %>%
                                                select(Entity__PeriodEnd, StockClass) %>% 
                                                distinct()) %>% 
      group_by(Entity__PeriodEnd) %>% 
      summarise(StockClass = paste(StockClass, collapse = ", "),
                .groups = "drop") %>% 
      mutate(Entity__PeriodEnd__StockClass = paste0(Entity__PeriodEnd, " (StockClass: ", StockClass, ")"))
    
    if(nrow(stockclass_with_bv_no_stock_df) > 0) {
      stop((paste0("BVs for some StockClass are provided but there are no stock on the following farms: ", 
                   paste(stockclass_with_bv_no_stock_df$Entity__PeriodEnd__StockClass, collapse = ", "))))
    }
    
  }
  
}


# Verify that female dairy StockClass are present on the farm if breed allocation are provided

breed_allocation_stockclass_present <- function() {
  
  if(nrow(Breed_Allocation_df > 0)) {
    
    stockclass_with_breed_allocation_no_stock_df <- setdiff(Breed_Allocation_df %>% 
                                                              select(Entity__PeriodEnd, StockClass),
                                                            StockRec_monthly_df %>%
                                                              filter(StockClass %in% c("Dairy Heifers R1", "Dairy Heifers R2", "Milking Cows Mature"),
                                                                     StockCount_mean > 0) %>%
                                                              select(Entity__PeriodEnd, StockClass) %>% 
                                                              distinct()) %>% 
      group_by(Entity__PeriodEnd) %>% 
      summarise(StockClass = paste(StockClass, collapse = ", "),
                .groups = "drop") %>% 
      mutate(Entity__PeriodEnd__StockClass = paste0(Entity__PeriodEnd, " (StockClass: ", StockClass, ")"))
    
    if(nrow(stockclass_with_breed_allocation_no_stock_df) > 0) {
      stop((paste0("Breed allocation for some StockClass are provided but there are no stock on the following farms (or StockClass provided is not a female dairy StockClass): ", 
                   paste(stockclass_with_breed_allocation_no_stock_df$Entity__PeriodEnd__StockClass, collapse = ", "))))
    }
    
  }
  
}


# Verify stock for a given sector is present for any allocated supplementary feed

suppfeed_sector_present <-function() {
  
  if(any(SuppFeed_DryMatter_df$Dry_Matter_t > 0, na.rm=TRUE)) {
    
    sectors_fed_supps_without_stock_df <- setdiff(SuppFeed_DryMatter_df %>%
                                                    select(Entity__PeriodEnd, 4:7) %>% 
                                                    gather(key = "Sector", value = "Allocation", 2:5) %>% 
                                                    mutate(Sector = gsub('.{11}$', '', Sector)) %>% 
                                                    group_by(Entity__PeriodEnd, Sector) %>% 
                                                    summarise(Allocation = sum(Allocation),
                                                              .groups = "drop") %>% 
                                                    filter(Allocation > 0) %>%
                                                    select(Entity__PeriodEnd, Sector), 
                                                  livestock_precalc_df %>%
                                                    select(Entity__PeriodEnd, Sector) %>%
                                                    distinct()) %>% 
      group_by(Entity__PeriodEnd) %>% 
      summarise(Sector = paste(Sector, collapse = ", "),
                .groups = "drop") %>% 
      mutate(Entity__PeriodEnd__Sector = paste0(Entity__PeriodEnd, " (", Sector, ")"))
    
    if(nrow(sectors_fed_supps_without_stock_df) > 0) {
      stop(paste0("The following farms have sectors with supplementary feed allocated but no stock present: ", 
                  paste(sectors_fed_supps_without_stock_df$Entity__PeriodEnd__Sector, collapse = ", ")))
    }
    
  }
  
}