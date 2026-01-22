# Farm Emissions Model Data Specification and Dictionary

This document provides a specification of the tables, fields,
definitions and values required to provide valid input data into the
Farm Emissions Model (FEM). This allows developers, scientists and other
technical stakeholders to effectively utilise the model to support a
robust estimation of on-farm emissions.

## Input Data Specification

### Introductory Notes

Each table below specifies the FEM input data requirements. The FarmYear
table can be thought of as the fundamental table that all other tables
join on to (by Entity_ID and Period_End). The Fertiliser table connects
to the fertiliser module of code. The remaining tables connect to the
livestock module of code. Of the livestock-related tables, we have 3
StockRec tables, a Dairy_Production table and a SuppFeed_DryMatter
table.

Each section includes two components:

- A table detailing input data requirements.
- A list of rules applied within the FEM (note that there may be
  additional rules applied as part of FEM-API documentation and the
  On-Farm Emissions Calculator).

Within the tables we supply example data for users to quickly get a
sense of the expected data format. We use 3 farms with the following
Entity_ID:

- 10001: a sheep farm which also does some beef finishing. Note in
  FarmYear we enter this across 3 separated periods to illustrate
  multiple periods for a single entity. In other tables we only enter
  data for the 2022-06-30 Period_End.
- 10002: a typical dairy farm.
- 10003-A: an arable farm with no livestock.

The example data files we supply (available from our repo README) is
consistent with the examples shown in this file. These data files are
provided in both CSV and JSON formats.

Rules that can be determined by looking at the relevant column only are
described in column rules.

Rules that can only be determined by looking at multiple columns at once
(potentially in multiple tables, or a derived table such as the monthly
stock rec) are described in complex rules.

Complex rules typically apply per row of an input table. There are
exceptions and we try to convey this through clear language. Here are
some examples of complex rules that apply to multiple rows at once, from
the table Breed_Allocation:

- Breed must be unique within Entity_ID and Period_End \[this applies to
  all rows for a given Entity_ID and Period_End\].
- Breed_Allocation must aggregate sum to 1 per Entity_ID and Period_End
  \[the **aggregate sum** refers to summing all provided rows per
  Entity_ID and Period_End\].

There are 4 data types used:

- int: Integer number (i.e. a whole number).
- float: Floating point number (a numerical data type that supports
  decimal points).
- str: String (i.e. a combination of characters). While numbers can be a
  string datatype, you can only perform numerical operations like
  multiplication on numerical datatypes like int and float.
- date str: A string following a specific date format. FEM always uses
  ISO8601 YYYY-MM-DD format
- logical: A data type that can only be TRUE or FALSE.

All specified columns within any given input table are required. No
null, NA or blank values are permitted in any column of any input data
table.

FEM does not currently implement the validation rules aside from a basic
check that the daily stock count never goes negative (e.g., from selling
more stock than are on the farm). **It is the users responsibility to
validate inputs.**

Numerical precision in R:

- R integers are by default stored as IEEE 754 double-precision floating
  points which can have a range of \[-9007199254740992,
  9007199254740992\] before losing precision.
- R floats are also stored as IEEE 754 double-precision floating points
  and begin to lose precision between 15-17 significant decimal digits.

### FarmYear

|  | Entity_ID | Period_Start | Period_End | Territory | Primary_Farm_Class | Solid_Separator_Use |
|:---|:---|:---|:---|:---|:---|:---|
| Example | 10001 | 2021-07-01 | 2022-06-30 | South Waikato District | North Island Hill Country | FALSE |
| Example | 10002 | 2022-06-01 | 2023-05-31 | Southland District | Dairy | FALSE |
| Example | 10003-A | 2022-07-01 | 2023-06-30 | Selwyn District | Cropping | FALSE |
| Data_Type | str | date str | date str | str | str | logical |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | ISO8601 YYYY-MM-DD format | Element of Territory_list | Element of Primary_Farm_Class_list | TRUE or FALSE |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must be unique |
| 2 | Period_End must be a month-end date equal to (Period_Start + 1 year - 1 day) |
| 3 | Primary_Farm_Class must exist in the Production_Region which maps to the given Territory |
| 4 | Solid_Separator_Use must be FALSE if no StockClass of Milking Cows Mature is present for the Entity_ID and Period_End |
| 5 | Solid_Separator_Use must be FALSE if the aggregate sum of Dairy_Shed_hr and Other_Structures_hr in Effluent_Structure_Use is 0 for the Entity_ID and Period_End |
| 6 | Guidance: Solid_Separator_Use must be FALSE if Effluent_EcoPond_Treatments contains records for the Entity_ID and Period_End |

### Fertiliser

|  | Entity_ID | Period_End | N_Urea_Coated_t | N_Urea_Uncoated_t | N_NonUrea_SyntheticFert_t | N_OrganicFert_t | Lime_t | Dolomite_t |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| Example | 10001 | 2022-06-30 | 0.6885 | 0 | 0 | 1.5 | 0 | 2 |
| Example | 10002 | 2023-05-31 | 3.32 | 0 | 0.87 | 0 | 5 | 0 |
| Example | 10003-A | 2023-06-30 | 8.3 | 5 | 22.32 | 5 | 0 | 0 |
| Data_Type | str | date str | float | float | float | float | float | float |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | \>= 0 | \>= 0 | \>= 0 | \>= 0 | \>= 0 | \>= 0 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must be unique and exist in FarmYear |

### StockRec_OpeningBalance

|  | Entity_ID | Period_End | StockClass | Opening_Balance |
|:---|:---|:---|:---|:---|
| Example | 10001 | 2022-06-30 | Ewe Hoggets | 160 |
| Example | 10001 | 2022-06-30 | Ram and Wether Hoggets | 20 |
| Example | 10001 | 2022-06-30 | Ewes Mature | 500 |
| Example | 10001 | 2022-06-30 | Rams Mature | 15 |
| Example | 10002 | 2023-05-31 | Milking Cows Mature | 450 |
| Example | 10002 | 2023-05-31 | Dairy Heifers R2 | 140 |
| Data_Type | str | date str | str | int |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | Element of StockClass list | \>= 1 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear |
| 2 | StockClass must be unique within Entity_ID and Period_End |
| 3 | StockClass cannot be newborn (StockClass values containing R1 or Lambs) |

### StockRec_BirthsDeaths

|  | Entity_ID | Period_End | Month | StockClass | Births | Deaths |
|:---|:---|:---|:---|:---|:---|:---|
| Example | 10001 | 2022-06-30 | 8 | Lambs | 470 | 0 |
| Example | 10001 | 2022-06-30 | 9 | Lambs | 80 | 0 |
| Example | 10001 | 2022-06-30 | 8 | Ewes Mature | 0 | 3 |
| Example | 10002 | 2023-05-31 | 8 | Dairy Heifers R1 | 150 | 0 |
| Data_Type | str | date str | int | str | int | int |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | Element of \[1:12\] | Element of StockClass_list | \>= 0 | \>= 0 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear |
| 2 | StockClass must be unique within Month, Entity_ID and Period_End |
| 3 | Births can only be \>= 1 for newborn StockClass (StockClass values containing R1 or Lambs) |
| 4 | Deaths cannot exceed the current StockClass balance for the Month, Entity_ID and Period_End |

### StockRec_Movements

|  | Entity_ID | Period_End | Transaction_Date | StockClass | Transaction_Type | Stock_Count |
|:---|:---|:---|:---|:---|:---|:---|
| Example | 10001 | 2022-06-30 | 2022-04-03 | Steers R2 | Purchase | 120 |
| Example | 10001 | 2022-06-30 | 2022-06-02 | Steers R2 | Sale | 120 |
| Example | 10001 | 2022-06-30 | 2022-03-25 | Lambs | Sale | 390 |
| Example | 10001 | 2022-06-30 | 2022-04-30 | Ewes Mature | Sale | 100 |
| Example | 10001 | 2022-06-30 | 2022-04-30 | Rams Mature | Sale | 15 |
| Example | 10002 | 2023-05-31 | 2023-04-25 | Milking Cows Mature | Sale | 145 |
| Data_Type | str | date str | date str | str | str | int |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | ISO8601 YYYY-MM-DD format | Element of StockClass_list | Element of Transaction_Type_list | \>= 1 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear |
| 2 | Transaction_Date must be between (Period_End - 1 Year + 1 Day) and Period_End, inclusive |
| 3 | Stock_Count cannot exceed the current StockClass balance when Transaction_Type values are Sale or Transfer Out for the Entity_ID and Period_End |

### Dairy_Production

|  | Entity_ID | Period_End | Month | Milk_Yield_Herd_L | Milk_Fat_Herd_kg | Milk_Protein_Herd_kg |
|:---|:---|:---|:---|:---|:---|:---|
| Example | 10002 | 2023-05-31 | 8 | 116740.8911 | 4646.091865 | 5916.331744 |
| Example | 10002 | 2023-05-31 | 9 | 245081.654 | 9753.839196 | 12420.5354 |
| Example | 10002 | 2023-05-31 | 10 | 303713.2341 | 12087.27785 | 15391.93535 |
| Example | 10002 | 2023-05-31 | 11 | 280937.825 | 11180.85472 | 14237.69647 |
| Example | 10002 | 2023-05-31 | 12 | 252709.8793 | 10057.42978 | 12807.12754 |
| Example | 10002 | 2023-05-31 | 1 | 215892.3125 | 8526.177629 | 10881.40643 |
| Example | 10002 | 2023-05-31 | 2 | 175218.8682 | 6919.872117 | 8831.383093 |
| Example | 10002 | 2023-05-31 | 3 | 165686.0296 | 6543.394263 | 8350.908873 |
| Example | 10002 | 2023-05-31 | 4 | 127342.8347 | 5029.116671 | 6418.334788 |
| Example | 10002 | 2023-05-31 | 5 | 65141.06327 | 2572.598671 | 3283.240503 |
| Data_Type | str | date str | int | float | float | float |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | Element of \[1:12\] | \>= 0 | \>= 0 | \>= 0 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear |
| 2 | Month must be unique within Entity_ID and Period_End |
| 3 | Milk_L_herd must be 0 if no Milking Cows Mature are present for the Month, Entity_ID and Period_End |
| 4 | Milk_Fat_kg_herd and Milk_Protein_kg_herd must be 0 if Milk_L_herd is 0 |
| 5 | Milk_Fat_kg_herd must be \<= 15% of Milk_L_herd |
| 6 | Milk_Protein_kg_herd must be \<= 15% of Milk_L_herd |
| 7 | Milk_L_Herd must be \> 0 if Effluent_Structure_Use.Dairy_Shed_hrs_day \> 0 for the Month, Entity_ID, and Period_End |
| 8 | Milk_L_Herd must be 0 if Effluent_Structure_Use.Dairy_Shed_hrs_day is 0 for the Month, Entity_ID, and Period_End |

### Breed_Allocation

|  | Entity_ID | Period_End | Sector | Breed | Breed_Allocation |
|:---|:---|:---|:---|:---|:---|
| Example | 10002 | 2023-05-31 | Dairy | Holstein-Friesian | 0 |
| Example | 10002 | 2023-05-31 | Dairy | Holstein-Friesian Jersey Cross | 0.8 |
| Example | 10002 | 2023-05-31 | Dairy | Jersey | 0 |
| Example | 10002 | 2023-05-31 | Dairy | Other | 0.2 |
| Data_Type | str | date str | str | str | float |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | Element of Sector_list | Element of Breed_list | \>= 0 and \<= 1 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear |
| 2 | Breed_Allocation records are only allowed and required for Entity_ID and Period_End with female Dairy StockClass present (Dairy Heifers R1, Dairy Heifers R2, Milking Cows Mature) |
| 3 | Breed must be unique within Entity_ID and Period_End |
| 4 | Breed_Allocation must aggregate sum to 1 per Entity_ID and Period_End (Guidance: A tolerance range of 0.999-1.001 is acceptable) |

### Effluent_Structure_Use

|  | Entity_ID | Period_End | Month | Dairy_Shed_hrs_day | Other_Structures_hrs_day |
|:---|:---|:---|:---|:---|:---|
| Example | 10002 | 2023-05-31 | 6 | 0 | 0 |
| Example | 10002 | 2023-05-31 | 7 | 0 | 0.5 |
| Example | 10002 | 2023-05-31 | 8 | 3 | 1.5 |
| Example | 10002 | 2023-05-31 | 9 | 3 | 1.2 |
| Example | 10002 | 2023-05-31 | 10 | 3.1 | 1 |
| Example | 10002 | 2023-05-31 | 11 | 3.1 | 1 |
| Example | 10002 | 2023-05-31 | 12 | 3 | 1 |
| Example | 10002 | 2023-05-31 | 1 | 3 | 0.9 |
| Example | 10002 | 2023-05-31 | 2 | 3 | 0.9 |
| Example | 10002 | 2023-05-31 | 3 | 3 | 1 |
| Example | 10002 | 2023-05-31 | 4 | 3 | 1 |
| Example | 10002 | 2023-05-31 | 5 | 2.8 | 1 |
| Data_Type | str | date str | int | float | float |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | Element of \[1:12\] | \>= 0 and \<= 24 | \>= 0 and \<= 24 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear |
| 2 | Month must be unique within Entity_ID and Period_End |
| 3 | A row must exist for every Month that Milking Cows Mature are present for an Entity_ID and Period_End |
| 4 | Sum of Dairy_Shed_hrs_day and Other_Structures_hrs_day must be \<= 24 |
| 5 | Sum of Dairy_Shed_hrs_day and Other_Structures_hrs_day must be 0 or no row must exist for Months that no Milking Cows Mature are present for an Entity_ID and Period_End |
| 6 | Dairy_Shed_hrs_day must be \> 0 if Dairy_Production.Milk_L_Herd is \> 0 for the Month, Entity_ID and Period_End |
| 7 | Dairy_Shed_hrs_day must be 0 if Dairy_Production.Milk_L_Herd is 0 for the Month, Entity_ID and Period_End |

### Effluent_EcoPond_Treatments

|  | Entity_ID | Period_End | Treatment_Date |
|:---|:---|:---|:---|
| Example | 10002 | 2023-05-31 | 2022-04-25 |
| Example | 10002 | 2023-05-31 | 2022-08-01 |
| Example | 10002 | 2023-05-31 | 2022-09-05 |
| Example | 10002 | 2023-05-31 | 2022-10-10 |
| Example | 10002 | 2023-05-31 | 2022-11-14 |
| Example | 10002 | 2023-05-31 | 2022-12-19 |
| Example | 10002 | 2023-05-31 | 2023-01-23 |
| Example | 10002 | 2023-05-31 | 2023-02-27 |
| Example | 10002 | 2023-05-31 | 2023-04-03 |
| Example | 10002 | 2023-05-31 | 2023-05-10 |
| Data_Type | str | date str | date str |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | ISO8601 YYYY-MM-DD format |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear and their Solid_Separator_Use must be FALSE |
| 2 | Treatment_Date must be unique within Entity_ID and Period_End |
| 3 | Treatment_Date must be within the 2 years prior to Period_End |
| 4 | Guidance: If treatment was performed in the previous period, include the last Treatment_Date from that period |

### SuppFeed_DryMatter

|  | Entity_ID | Period_End | Supplement | Dry_Matter_t | Beef_Allocation | Dairy_Allocation | Deer_Allocation | Sheep_Allocation |
|:---|:---|:---|:---|:---|:---|:---|:---|:---|
| Example | 10001 | 2022-06-30 | Pasture, Hay | 5 | 0 | 0 | 0 | 1 |
| Example | 10001 | 2022-06-30 | Pasture, Silage | 10 | 0 | 0 | 0 | 1 |
| Example | 10001 | 2022-06-30 | Maize Grain, Concentrate | 5 | 0.7 | 0 | 0 | 0.3 |
| Example | 10002 | 2023-05-31 | Palm Kernel Extract, Concentrate | 9.52 | 0 | 1 | 0 | 0 |
| Example | 10002 | 2023-05-31 | Swede, Forage | 15.3 | 0 | 1 | 0 | 0 |
| Data_Type | str | date str | str | float | float | float | float | float |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | Element of Supplementary_Feed_list | \>= 0 | \>= 0 and \<= 1 | \>= 0 and \<= 1 | \>= 0 and \<= 1 | \>= 0 and \<= 1 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear |
| 2 | Supplement must be unique within Entity_ID and Period_End |
| 3 | Sum of Beef, Dairy, Deer, and Sheep Allocations must be 1 if Dry_Matter_t \> 0 (Guidance: A tolerance range of 0.999-1.001 is acceptable) |
| 4 | Sum of Beef, Dairy, Deer, and Sheep Allocations must be 0 if Dry_Matter_t is 0 |
| 5 | Allocation for a Sector must be 0 if no StockClass from that Sector is present |

### BreedingValues

|  | Entity_ID | Period_End | StockClass | BV_aCH4 |
|:---|:---|:---|:---|:---|
| Example | 10001 | 2022-06-30 | Ewe Hoggets | -0.02 |
| Example | 10001 | 2022-06-30 | Ram and Wether Hoggets | -0.02 |
| Example | 10001 | 2022-06-30 | Ewes Mature | -0.01 |
| Example | 10001 | 2022-06-30 | Rams Mature | -0.06 |
| Example | 10001 | 2022-06-30 | Lambs | -0.03 |
| Data_Type | str | date str | str | float |
| Column_Rules | Any str up to 32 chars | ISO8601 YYYY-MM-DD format | Element of StockClass list | \>= -0.4 and \<= 1 |

|  | Complex_Rules |
|---:|:---|
| 1 | Combination of Entity_ID and Period_End must exist in FarmYear |
| 2 | StockClass must be unique within Entity_ID and Period_End |
| 3 | StockClass balance must be \>=1 for at least 1 day for the Entity_ID and Period_End |

## Minimum Data Inputs to Run FEM

Minimum required input data tables to complete an emissions estimation
are laid out below.

Required inputs are tables with rows needed for the model to
successfully run. **All input data relevant to a given farm should be
entered to estimate emissions accurately.**

The `FarmYear` table is the core table and is always required.

Either the `Fertiliser` table or at least one of three livestock
StockRec tables are also required:

- `StockRec_OpeningBalance`
- `StockRec_BirthsDeaths`
- `StockRec_Movements`

This ensures at least one of the emissions modules, currently Fertiliser
and Livestock, are activated.

The following livestock related tables are conditionally required:

- `Breed_Allocation`

  - required if a farm has any female Dairy cattle (i.e. `StockClass`
    values containing `Dairy Heifers` or `Milking Cows Mature`) present
    during the period, based on the three StockRec tables.

- `Effluent_Structure_Use` required if a farm has any `StockClass` of
  `Milking Cows Mature` present during the period, based on the three
  StockRec tables.

- `Dairy_Production` and `Effluent_Structure_Use`

  - These both take data inputs on `Mature Milking Cows` being in the
    milking shed and therefore should be consistent with one another: If
    either `Dairy_Production.Milk_Yield_L` or
    `Effluent_Structure_Use.Dairy_Shed_hrs_day` are supplied and any of
    these values are postive, both tables are required.

The remaining livestock related tables are not required to complete an
emissions estimation:

- `SuppFeed_DryMatter`
- `BreedingValues`
- `Effluent_EcoPond_Treatments`

## Input Data Column Definitions

Definitions of each column in every input table are provided below.

### FarmYear

| Column_Title | Definition |
|:---|:---|
| Entity_ID | User supplied unique identifier to represent a specific entity from within a system, database, or application. |
| Period_Start | Beginning of an assessment period. Usually relates to the beginning of an entity’s tax year but could be aligned to another annual reporting framework. |
| Period_End | Conclusion of an assessment period. Usually relates to the end of an entity’s tax year but could be aligned to another annual reporting framework. |
| Territory | Primary geographic area (defined by Territorial Authorities) the farm sits within. Values defined by: Territory_list |
| Primary_Farm_Class | Classification of farm based on sector, activity, region, geography, and grazing levels. Values defined by Primary_Farm_Class_list |
| Solid_Separator_Use | Whether or not a solid separator is used as part of farm effluent management system. |

References:

- Territory as geographically defined by [Stats NZ Territorial
  Authority](https://datafinder.stats.govt.nz/layer/111194-territorial-authority-2023-generalised%5D).

- Primary_Farm_Class: Red meat classes use [Beef & Lamb farm class
  definitions](https://beeflambnz.com/industry-data/farm-data-and-industry-production/farm-classes).

### Fertiliser

Note the definitions here use tonnes **purchased**, not applied. This
approach minimises cost of compliance and maximises traceability.

| Column_Title | Definition |
|:---|:---|
| Entity_ID | See Table: FarmYear |
| Period_End | See Table: FarmYear |
| N_Urea_Coated_t | Tonnes of nitrogen in purchased Urea with a urease inhibitor coating. |
| N_Urea_Uncoated_t | Tonnes of nitrogen in purchased Urea without any protective coating. |
| N_NonUrea_SyntheticFert_t | Tonnes of nitrogen in purchased synthetic fertilisers, that do not use urea as the main nitrogen source. |
| N_OrganicFert_t | Tonnes of nitrogen in purchased manure and non-manure organic fertilisers. |
| Lime_t | Tonnes of purchased lime. |
| Dolomite_t | Tonnes of purchased dolomite. |

### StockRec_OpeningBalance

| Column_Title | Definition |
|:---|:---|
| Entity_ID | See Table: FarmYear |
| Period_End | See Table: FarmYear |
| StockClass | Category of animals defined by its sector, sex, age and if castrated. Values defined by StockClass_list. |
| Opening_Balance | The number of animals in a stock class at the start of the assessment period. |

Note the approach of:

- `Opening_Balance` should be the same as the closing balance for the
  previous reporting period.

- As per data specification rules for this table, a **newborn**
  `StockClass` (R1s or Lambs) can not have an `Opening_Balance`. Either
  stock is aged-up or it has not been born yet.

Which is aligned to accepted Stock valuation approaches from Inland
Revenue (NAMV and NSC).

### StockRec_BirthsDeaths

| Column_Title | Definition |
|:---|:---|
| Entity_ID | See Table: FarmYear |
| Period_End | See Table: FarmYear |
| Month | Calendar month. |
| StockClass | Category of animals defined by its sector, sex, age and if castrated. Values defined by StockClass_list. |
| Births | Number of live animals from relevant StockClass born. Positive values limited to newborn StockClasses. |
| Deaths | Number animals from relevant stockclass that died. |

Note:

- As per data specification rules for this table, only newborn
  StockClass (R1s or Lambs) can be have positive births.

- `Births` and `Deaths` should be entered in the `Month` they occur, not
  as Period_End values to adjust balances.

### StockRec_Movements

| Column_Title | Definition |
|:---|:---|
| Entity_ID | See Table: FarmYear |
| Period_End | See Table: FarmYear |
| Transaction_Date | Date on which a stock transaction occurs. Recognised on invoice date. |
| StockClass | Category of animals defined by its sector, sex, age and if castrated. Values defined by StockClass_list. |
| Transaction_Type | Business/farm activity relating to the movement of livestock. Values defined by Transaction_Type_list. |
| Stock_Count | Number of animals from a stock class included in a transaction. |

### Dairy_Production

| Column_Title         | Definition                                        |
|:---------------------|:--------------------------------------------------|
| Entity_ID            | See Table: FarmYear                               |
| Period_End           | See Table: FarmYear                               |
| Month                | Calendar month.                                   |
| Milk_Yield_Herd_L    | Litres of milk produced by dairy herd.            |
| Milk_Fat_Herd_kg     | Kilograms of milk fat produced by dairy herd.     |
| Milk_Protein_Herd_kg | Kilograms of milk protein produced by dairy herd. |

### Breed_Allocation

| Column_Title | Definition |
|:---|:---|
| Entity_ID | See Table: FarmYear |
| Period_End | See Table: FarmYear |
| Sector | Segments of the agriculture economy that revolve around livestock groups. Values defined by Sector_list. |
| Breed | Genetic ancestry of an animal, generally expressed as the number of 16ths of the breed which contribute to the makeup of the animal, in line with DIGAD definitions and data standards. Values defined by Breed_list, based on fields and aggregations published by DairyNZ. |
| Breed_Allocation | Percentage of total dairy herd attributable to a given breed. |

Note as per data specification rules for this table, `Breed` is
currently only for female Dairy cattle.

Breed & DIGAD references:

1.  <https://www.dairynz.co.nz/media/g1tbbhqq/core_database_fields.pdf>
2.  <https://www.dairynz.co.nz/media/oqzc5k3m/dds-parentage-breed-recording-and-genetic-testing-may-2024.pdf>
3.  <https://www.dairynz.co.nz/media/bywm13d4/dairy-statistics-2023-24.pdf>

### Effluent_Structure_Use

| Column_Title | Definition |
|:---|:---|
| Entity_ID | See Table: FarmYear |
| Period_End | See Table: FarmYear |
| Month | Calendar month. |
| Dairy_Shed_hrs_day | Average number of hours in a day that mature milking cows spend in dairy sheds. |
| Other_Structures_hrs_day | Average number of hours in a day that mature milking cows spend in off-paddock structures connected to effluent management systems, excluding dairy sheds. |

### Effluent_EcoPond_Treatments

| Column_Title   | Definition                                              |
|:---------------|:--------------------------------------------------------|
| Entity_ID      | See Table: FarmYear                                     |
| Period_End     | See Table: FarmYear                                     |
| Treatment_Date | Date on which effluent lagoon was treated with EcoPond. |

EcoPond treatments are effective in FEM for 6 weeks from the
`Treatment_Date`. Therefore, treatments from the previous period may be
required to calculate efficacy in this period.

### SuppFeed_DryMatter

| Column_Title | Definition |
|:---|:---|
| Entity_ID | See Table: FarmYear |
| Period_End | See Table: FarmYear |
| Supplement | Name of the supplementary feed. Values defined by Supplementary_Feed_list. |
| Dry_Matter_t | Mass of supplement dry matter in tonnes. Purchased or grown. |
| Beef_Allocation | Proportion of dry matter allocated to beef cattle. |
| Dairy_Allocation | Proportion of dry matter allocated to dairy cattle. |
| Deer_Allocation | Proportion of dry matter allocated to deer. |
| Sheep_Allocation | Proportion of dry matter allocated to sheep. |

### BreedingValues

| Column_Title | Definition |
|:---|:---|
| Entity_ID | See Table: FarmYear |
| Period_End | See Table: FarmYear |
| StockClass | Category of animals defined by its sector, sex, age and if castrated. Values defined by StockClass_list. |
| BV_aCH4 | Breeding value expressing methane reduction, adjusted for liveweight. Expressed as a percentage reduction, and, estimated from an appropriate genetics database or tool (e.g., nProve). |

Note:

- As per data specification rules for this table, `BV_aCH4` is currently
  only for Sheep stock classes.

- Science underpinning breeding values and adjustments for sheep
  administered by [Beef+Lamb NZ Genetics Coolsheep
  Programme](https://www.blnzgenetics.com/cool-sheep-programme/about-the-programme-2).
  A negative value will represent a decrease in expected methane
  production.

## Allowed Value Lists and Definitions

Some columns in the Input Data Specification tables have rules requiring
values to be from a list of allowed values. These lists are set out
below and definitions are provided where appropriate.

### Territory_list

These are geographically defined by [Stats
NZ](https://datafinder.stats.govt.nz/layer/111194-territorial-authority-2023-generalised/):

|  |  |  |
|:---|:---|:---|
| Far North District | Napier City | Buller District |
| Whangarei District | Central Hawkes Bay District | Grey District |
| Kaipara District | New Plymouth District | Westland District |
| Auckland | Stratford District | Kaikoura District |
| Thames-Coromandel District | South Taranaki District | Hurunui District |
| Hauraki District | Ruapehu District | Waimakariri District |
| Waikato District | Whanganui District | Christchurch City |
| Matamata-Piako District | Rangitikei District | Selwyn District |
| Hamilton City | Manawatu District | Ashburton District |
| Waipa District | Palmerston North City | Timaru District |
| Otorohanga District | Tararua District | Mackenzie District |
| South Waikato District | Horowhenua District | Waimate District |
| Waitomo District | Kapiti Coast District | Chatham Islands Territory |
| Taupo District | Porirua City | Waitaki District |
| Western Bay of Plenty District | Upper Hutt City | Central Otago District |
| Tauranga City | Lower Hutt City | Queenstown-Lakes District |
| Rotorua District | Wellington City | Dunedin City |
| Whakatane District | Masterton District | Clutha District |
| Kawerau District | Carterton District | Southland District |
| Opotiki District | South Wairarapa District | Gore District |
| Gisborne District | Tasman District | Invercargill City |
| Wairoa District | Nelson City |  |
| Hastings District | Marlborough District |  |

### Primary_Farm_Class_list

| Primary_Farm_Class | Type | Definition |
|:---|:---|:---|
| North Island Hard Hill Country | Red meat | Steep hill country or low fertility soils with most farms carrying 6 to 10 stock units per hectare. While some stock are finished a significant proportion are sold in store condition. |
| North Island Hill Country | Red meat | Easier hill country or higher fertility soils than Class 3. Mostly carrying between 7 and 13 stock units per hectare. A high proportion of sale stock sold is in forward store or prime condition. |
| North Island Finishing | Red meat | Easy contour farmland with the potential for high production. Mostly carrying between 8 and 15 stock units per hectare. A high proportion of stock is sent to slaughter and replacements are often bought in. |
| Dairy | Dairy | Primarily a dairy operation. |
| Cropping | Other | The primary output of the farm is crops for food, feed, fibre, and industrial purposes. |
| Orchard | Other | The primary output of the farm is fruit. |
| Vineyard | Other | The primary output of the farm is grapes. |
| South Island High Country | Red meat | Extensive run country located at high altitude. These farms run a diverse mix of operations which include breeding sheep, often fine wooled, breeding cows and deer. Stocking rate is typically up to three stock units per hectare. Located mainly in Marlborough, Canterbury and Otago. |
| South Island Hill Country | Red meat | Traditionally store stock producers with a proportion sold prime in good seasons. Carrying between two and seven stock units per hectare, they usually have a significant proportion of beef cattle. |
| South Island Finishing | Red meat | High producing grassland farms carrying about 9 to 14 stock units per hectare, with some cash crop. Located in Southland, South and West Otago. |
| South Island Finishing-Breeding | Red meat | Farms which breed or trade finishing stock, and may do some cash cropping. A proportion of stock may be sold store, especially from dryland farms. Carrying capacity ranges from 6 to 11 stock units per hectare on dryland farms and over 12 stock units per hectare on wetter or irrigated farms. Mainly in Canterbury and Otago, this is the dominant farm class in the South Island. |
| South Island Mixed Cropping & Finishing | Red meat | Located mainly on the Canterbury Plains. A high proportion of their revenue is derived from grain and small seed production, as well as stock finishing or grazing. |

Note if a farm could be described by multiple farm classes (e.g. it has
both dairy cows and sheep), farm revenue should be used as the primary
determinant, followed by stocking rate.

### Transaction_Type_list

| Transaction_Type | Definition |
|:---|:---|
| Sale | Transfer of stock ownership out of the entity in return for an agreed-upon payment. |
| Purchase | Transfer of stock ownership to the entity in return for an agreed-upon payment. |
| Transfer In | Non-cash movement of stock into the entity. |
| Transfer Out | Non-cash movement of stock out of the entity. |

### Sector_list

| Sector | Definition |
|:---|:---|
| Beef | Cattle primarily used for the production of meat and associated breeding / replacement stock. |
| Dairy | Cattle primarily used for milk production and associated breeding / replacement stock. |
| Deer | Deer farmed for breeding, velvet, hunting, and production of meat. |
| Sheep | Sheep farmed for breeding and production of meat. |

### StockClass_list

| Sector | StockClass | User_Friendly_Label | Definition |
|:---|:---|:---|:---|
| Beef | Heifers R1 | Heifer Calves R1 (0-1yr) | Female beef cattle born in the current period |
| Beef | Heifers R2 | Heifers R2 (1-2yr) | Female beef cattle born in the previous period. R1s last period |
| Beef | Heifers R3 | Heifers R3 (2-3yr) | Female beef cattle born two periods ago. R2s last period |
| Beef | Cows Mature | Cows (3+) | Female beef cattle born three or more periods ago. R3s or 3+ last period |
| Beef | Steers R1 | Steer Calves R1 (0-1yr) | Male castrated beef cattle born in the current period |
| Beef | Steers R2 | Steers R2 (1-2yr) | Male castrated beef cattle born in the previous period. R1s last period |
| Beef | Steers R3 | Steers R3 (2+) | Male castrated beef cattle born two or more periods ago. R2s last period |
| Beef | Bulls R1 | Bull Calves R1 (0-1yr) | Male uncastrated beef cattle born in the current period |
| Beef | Bulls R2 | Bulls R2 (1-2yr) | Male uncastrated beef cattle born in the previous period. R1s last period |
| Beef | Bulls R3 | Bulls R3 (2-3yr) | Male uncastrated beef cattle born two periods ago. R2s last period |
| Beef | Bulls Mature | Bulls (3+) | Male uncastrated beef cattle born three or more periods ago. R3s or 3+ last period |
| Dairy | Dairy Heifers R1 | Dairy Heifer Calves R1 (0-1yr) | Female dairy cattle born in the current period |
| Dairy | Dairy Heifers R2 | Dairy Heifers R2 (1-2yr) | Female dairy cattle born in the previous period. R2s last period |
| Dairy | Milking Cows Mature | Milking Cows (2+) | Female dairy cattle born two or more periods ago. R2s or 2+ last period |
| Dairy | Dairy Bulls R1 | Dairy Bull Calves R1 (0-1yr) | Male uncastrated dairy cattle born in the current period |
| Dairy | Dairy Bulls R2 | Dairy Bulls R2 (1-2yr) | Male uncastrated dairy cattle born in the previous period. R1s last period |
| Dairy | Dairy Bulls Mature | Dairy Bulls (2+) | Male uncastrated dairy cattle born two or more periods ago. R2s or 2+ last period |
| Deer | Hinds R1 | Hind Fawns R1 (0-1yr) | Female deer born in the current period and raised for meat, breeding or hunting |
| Deer | Hinds R2 | Hinds R2 (1-2yr) | Female deer born in the previous period and raised for meat, breeding or hunting. R1s last period |
| Deer | Hinds Mature | Hinds (2+) | Female deer born two or more periods ago and raised for meat, breeding or hunting. R2s or 2+ last period |
| Deer | Stags R1 | Stag Fawns R1 (0-1yr) | Male deer born in the current period and raised for velvet, meat, breeding or hunting |
| Deer | Stags R2 | Stags R2 (1-2yr) | Male deer born in the previous period and raised for velvet, meat, breeding or hunting. R1s last period |
| Deer | Stags R3 | Stags R3 (2-3yr) | Male deer born two periods ago and raised for velvet, meat, breeding or hunting. R3s last period |
| Deer | Stags Mature | Stags (3+) | Male deer born three or more periods ago and raised for velvet, meat, breeding or hunting. R3s or 3+ last period |
| Sheep | Lambs | Lambs (0-1yr) | Sheep born in the current period |
| Sheep | Ewe Hoggets | Ewe Hoggets (1-2yr) | Female sheep born in the previous period. Lambs last period |
| Sheep | Ram and Wether Hoggets | Ram and Wether Hoggets (1-2yr) | Male sheep born in the previous period. Lambs last period |
| Sheep | Ewes Mature | Ewes (2+) | Female sheep born two or more periods ago. Ewe Hoggets or 2+ last period |
| Sheep | Wethers Mature | Wethers (2+) | Male castrated sheep born two or more periods ago. Wether Hoggets or 2+ last period |
| Sheep | Rams Mature | Rams (2+) | Male uncastrated sheep born two or more periods ago. Ram hoggets or 2+ last period |

### Breed_list

| Breed | Definition |
|:---|:---|
| Holstein-Friesian | Dairy breed whose parentage comprises greater than 12/16ths (\>75%) Holstein-Friesian. |
| Jersey | Dairy breed whose parentage comprises greater than 12/16ths (\>75%) Jersey. |
| Holstein-Friesian Jersey Cross | Dairy breed whose parentage is comprised of Holstein-Friesian and Jersey, but with no dominant (i.e. greater than 12/16ths) breed. |
| Other | Dairy breeds that are not Holstein-Friesian, Jersey or Holstein-Friesian Jersey Cross. |

### Supplement_list

| Supplement | User_Friendly_Label | User_Friendly_Category | Definition |
|:---|:---|:---|:---|
| Apple Pomace, Byproduct | Apple Pomace | Concentrates, By-Products and Food Wastes | Moist, fibrous residue left after apple juice or cider extraction |
| Apple, Byproduct | Apple | Concentrates, By-Products and Food Wastes | Reject / waste apples |
| Barley Grain, Concentrate | Barley Grain | Concentrates, By-Products and Food Wastes | Pure barley grain |
| Barley, Silage | Barley Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from the whole barley plant, including the stems, leaves, and grain |
| Barley, Straw | Barley Straw | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Dry, hollow stalks of barley that remain after the grain has been harvested |
| Bread, Byproduct | Bread | Concentrates, By-Products and Food Wastes | Reject / waste bread |
| Brewers Grain, Concentrate | Brewers Grain | Concentrates, By-Products and Food Wastes | Moist, fibrous by-product of beer production |
| Broll, Concentrate | Broll | Concentrates, By-Products and Food Wastes | Wheat bran pellets produced under steam as a by-product of milling also known as pollard or mill run |
| Cabbage, Byproduct | Cabbage | Concentrates, By-Products and Food Wastes | Reject / waste cabbage |
| Canola Meal, Concentrate | Canola Meal | Concentrates, By-Products and Food Wastes | Made from the grinding of canola seeds after the oil has been extracted |
| Canola, Byproduct | Canola Seed | Concentrates, By-Products and Food Wastes | Byproduct of canola oil extraction |
| Carrot, Byproduct | Carrot | Concentrates, By-Products and Food Wastes | Reject / waste carrots |
| Cereal, Silage | Cereal Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from any cereal crop, such as wheat, barley, oats, or rye |
| Chicory, Forage | Chicory | Forage | Chicory fed in-situ |
| Citrus Pulp, Byproduct | Citrus Pulp | Concentrates, By-Products and Food Wastes | Fibrous residue left after juicing citrus fruits, consisting of peel, pulp and seeds |
| Condensed Distillers Syrup, Concentrate | Condensed Distillers Syrup | Concentrates, By-Products and Food Wastes | Liquid by-product of ethanol production |
| Corn Grits, Concentrate | Corn Grits | Concentrates, By-Products and Food Wastes | Processed dried corn kernels |
| Cottonseed Meal, Concentrate | Cottonseed Meal | Concentrates, By-Products and Food Wastes | Byproduct of oil extraction from cottonseed |
| Cottonseed, Byproduct | Cottonseed | Concentrates, By-Products and Food Wastes | Whole cottonseed |
| Dried Distillers Grain, Concentrate | Dried Distillers Grain (DDG) | Concentrates, By-Products and Food Wastes | Co-product of the ethanol production process from grains, primarily corn, in which residue is dried and processed into feed |
| Fishmeal, Byproduct | Fishmeal | Concentrates, By-Products and Food Wastes | Flour made from cooking, pressing, drying and grinding whole fish or fish by-products |
| Fodderbeet, Forage | Fodderbeet | Forage | Fodderbeet fed in-situ or harvested |
| Grape Pomace, Byproduct | Grape Pomace | Concentrates, By-Products and Food Wastes | Fibrous residue from winemaking, composed of skins, seeds and pulp, also known as grape marc |
| Japanese Millet, Forage | Japanese Millet | Forage | Japanese millet fed in-situ or freshly cut |
| Kale, Forage | Kale | Forage | Kale crop fed in-situ or freshly cut |
| Kiwifruit, Byproduct | Kiwifruit | Concentrates, By-Products and Food Wastes | Reject / waste kiwifruit |
| Lucerne Meal, Concentrate | Lucerne Meal | Concentrates, By-Products and Food Wastes | Made from dried and milled lucerne (alfalfa) |
| Lucerne, Baleage | Lucerne Baleage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from the lucerne (alfalfa) plant, including the leaves and stem |
| Lucerne, Forage | Lucerne Forage | Forage | Lucerne (alfalfa) crop fed in-situ or freshly cut |
| Lucerne, Silage | Lucerne Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from the lucerne plant, also known as alfalfa silage |
| Lupin, Concentrate | Lupin | Concentrates, By-Products and Food Wastes | Lupin grain which can be fed fresh or ensiled with maize/cereals |
| Maize Grain, Concentrate | Maize Grain | Concentrates, By-Products and Food Wastes | Pure maize grain |
| Maize, Forage | Maize Forage | Forage | Maize fed in-situ or freshly cut |
| Maize, Silage | Maize Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from the whole maize (corn) plant, including the stalks, leaves, cobs, and grain |
| Maize, Straw | Maize Straw | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Dry, hollow stalks of maize that remain after the grain has been harvested |
| Molasses, Concentrate | Molasses | Concentrates, By-Products and Food Wastes | Byproduct of sugar production from sugar cane or sugar beets, a viscous liquid |
| Oat Grain, Concentrate | Oat Grain | Concentrates, By-Products and Food Wastes | Pure Oat grain |
| Oat Hull Pellets, Concentrate | Oat Hull Pellets | Concentrate | Pelletised oat hulls |
| Oat, Forage | Oat Forage | Forage | Oats fed in-situ or freshly cut |
| Oat, Silage | Oat Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from the whole oat plant, including the grain, leaves, and stems |
| Oat, Straw | Oat Straw | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Dry, hollow stalks of oats that remain after the grain has been harvested |
| Onion, Byproduct | Onion | Concentrates, By-Products and Food Wastes | Reject / waste onion |
| Other Concentrates, Concentrate | Other Concentrates | Concentrates, By-Products and Food Wastes | Grains, meals, and byproducts not specifically categorized in this list |
| Other Food Wastes, Byproduct | Other Food Wastes | Concentrates, By-Products and Food Wastes | Plant materials that are discarded during the production, processing, or consumption of fruits and vegetables |
| Palm Kernel Extract, Concentrate | Palm Kernel Extract (PKE) | Concentrates, By-Products and Food Wastes | Derived from the extraction of oil from palm kernel, also known as palm kernel meal |
| Pasture, Baleage | Mixed Pasture Baleage/Haylage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented partially dried forage that has been baled and wrapped in plastic to create an airtight environment |
| Pasture, Hay | Pasture Hay | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Dried forage made from pasture grasses and legumes that are cut, left to dry in the field, and then baled for storage |
| Pasture, Silage | Mixed Pasture Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermenting freshly cut pasture grasses, which may include a variety of species such as ryegrass, clover, and fescue |
| Pea Dried, Concentrate | Pea Dried | Concentrates, By-Products and Food Wastes | Dried pea |
| Pea, Silage | Pea Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from the whole pea plant |
| Pea, Straw | Pea Straw | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Dry, hollow stalks of peas that remain after the grain has been harvested |
| Plantain, Forage | Plantain Forage | Forage | Plantain fed in-situ or freshly cut |
| Plantain, Silage | Plantain Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from plantain |
| Pollard, Byproduct | Pollard | Concentrates, By-Products and Food Wastes | Byproduct of wheat milling |
| Potato, Byproduct | Potato | Concentrates, By-Products and Food Wastes | Reject / waste potato |
| Proliq, Byproduct | Proliq | Concentrates, By-Products and Food Wastes | Liquid feed derived from whey after lactose extraction |
| Rape, Forage | Rape | Forage | Rape crop fed in-situ or freshly cut |
| Ryegrass, Straw | Ryegrass Straw | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Dry, stems of ryegrass that remain after the grain has been harvested |
| Sorghum, Forage | Sorghum Forage | Forage | Sorghum fed in-situ or freshly cut |
| Sorghum, Silage | Sorghum Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from the whole sorghum plant |
| Soya Bean Hull, Concentrate | Soyabean Hull | Concentrates, By-Products and Food Wastes | Outer coverings of soybeans, which are removed during the processing of soybeans for oil extraction |
| Soya Bean Meal, Concentrate | Soyabean Meal | Concentrates, By-Products and Food Wastes | Byproduct of oil extraction from soybeans |
| Squash, Byproduct | Squash / Pumpkin | Concentrates, By-Products and Food Wastes | Reject / waste squash and pumpkin |
| Sugar Beet, Forage | Sugar Beet | Forage | Sugar beet fed in-situ or harvested |
| Sulla, Forage | Sulla | Forage | Sulla fed in-situ or freshly cut |
| Sunflower Pellets, Concentrate | Sunflower Pellets | Concentrate | Residue of sunflower seeds after the oil has been extracted |
| Swede, Forage | Swede | Forage | Swede fed in-situ or harvested |
| Sweetcorn Waste, Byproduct | Sweetcorn Waste | By Product | Sweetcorn waste after the cobs are extracted |
| Tapioca, Concentrate | Tapioca | Concentrates, By-Products and Food Wastes | Starch extracted from the cassava root |
| Triticale, Forage | Triticale Forage | Forage | Triticale fed in-situ or freshly cut |
| Triticale, Silage | Triticale Silage | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Fermented forage made from the whole triticale plant, a hybrid of wheat and rye |
| Turnip, Forage | Turnip | Forage | Turnip fed in-situ or harvested |
| Wheat Grain, Concentrate | Wheat Grain | Concentrates, By-Products and Food Wastes | Pure wheat grain |
| Wheat, Straw | Wheat Straw | Conserved Feeds (e.g. Silage, Hay, Baleage, Straw) | Dry, hollow stalks of wheat that remain after the grain has been harvested |
| Whey Concentrate, Concentrate | Whey Concentrate | Concentrate | Milk whey concentrate |

## Output Data Specification

In this section the columns and data types of FEM’s outputs are
specified.

Configuring FEM to generate and save output tables is described in the
README.

### Emission Outputs

The tables below contain varying levels of aggregation of emission
outputs in kg of gas. Granular livestock emission table is aggregated
annually or monthly and by sector or stock class, while granular
fertiliser emission table is aggregated annually. Annually aggregated
livestock and fertiliser tables are joined and aggregated by gas.

#### smry_all_annual_by_gas

| Column_Title | Data_Type |
|:-------------|:----------|
| Entity_ID    | str       |
| Period_End   | date str  |
| CH4_total_kg | float     |
| N2O_total_kg | float     |
| CO2_total_kg | float     |

#### smry_all_annual_by_emission_type

| Column_Title              | Data_Type |
|:--------------------------|:----------|
| Entity_ID                 | str       |
| Period_End                | date str  |
| CH4_Digestion_kg          | float     |
| CH4_DungUrine_kg          | float     |
| CH4_Effluent_kg           | float     |
| N2O_DungUrine_kg          | float     |
| N2O_Effluent_kg           | float     |
| N2O_SynthFert_kg          | float     |
| CO2_SynthFert_kg          | float     |
| N2O_OrganicFert_Direct_kg | float     |
| CO2_Lime_kg               | float     |
| CO2_Dolomite_kg           | float     |

#### smry_livestock_annual

| Column_Title     | Data_Type |
|:-----------------|:----------|
| Entity_ID        | str       |
| Period_End       | date str  |
| CH4_Digestion_kg | float     |
| CH4_DungUrine_kg | float     |
| CH4_Effluent_kg  | float     |
| N2O_DungUrine_kg | float     |
| N2O_Effluent_kg  | float     |

#### smry_livestock_annual_by_Sector

| Column_Title     | Data_Type |
|:-----------------|:----------|
| Entity_ID        | str       |
| Period_End       | date str  |
| Sector           | str       |
| CH4_Digestion_kg | float     |
| CH4_DungUrine_kg | float     |
| CH4_Effluent_kg  | float     |
| N2O_DungUrine_kg | float     |
| N2O_Effluent_kg  | float     |

#### smry_livestock_monthly_by_Sector

| Column_Title     | Data_Type |
|:-----------------|:----------|
| Entity_ID        | str       |
| Period_End       | date str  |
| YearMonth        | date str  |
| Sector           | str       |
| CH4_Digestion_kg | float     |
| CH4_DungUrine_kg | float     |
| CH4_Effluent_kg  | float     |
| N2O_DungUrine_kg | float     |
| N2O_Effluent_kg  | float     |

#### smry_livestock_monthly_by_StockClass

| Column_Title     | Data_Type |
|:-----------------|:----------|
| Entity_ID        | str       |
| Period_End       | date str  |
| YearMonth        | date str  |
| Sector           | str       |
| StockClass       | str       |
| StockCount_mean  | float     |
| CH4_Digestion_kg | float     |
| CH4_DungUrine_kg | float     |
| CH4_Effluent_kg  | float     |
| N2O_DungUrine_kg | float     |
| N2O_Effluent_kg  | float     |

#### smry_fertiliser_annual

| Column_Title              | Data_Type |
|:--------------------------|:----------|
| Entity_ID                 | str       |
| Period_End                | date str  |
| N2O_SynthFert_kg          | float     |
| CO2_SynthFert_kg          | float     |
| N2O_OrganicFert_Direct_kg | float     |
| CO2_Lime_kg               | float     |
| CO2_Dolomite_kg           | float     |

### Mitigation Impact Outputs

The tables below show the emission impacts (in kg of gas) of mitigation
technologies in varying levels of aggregation. There are four mitigation
technologies supported in the model:

- Urease inhibitor coated urea fertiliser.
- Low methane animal genetics.
- EcoPond effluent treatment.
- Solid separator effluent systems.

The mitigation impact of a particular technology is the mitigated
emissions minus the emissions without the impact of that technology.
Please refer to the FEM’s Methodology for further details.

#### smry_all_annual_by_gas_mitign_delta

| Column_Title              | Data_Type |
|:--------------------------|:----------|
| Entity_ID                 | str       |
| Period_End                | date str  |
| CH4_total_mitign_delta_kg | float     |
| N2O_total_mitign_delta_kg | float     |
| CO2_total_mitign_delta_kg | float     |

#### smry_all_annual_by_emission_type_mitign_delta

| Column_Title                   | Data_Type |
|:-------------------------------|:----------|
| Entity_ID                      | str       |
| Period_End                     | date str  |
| CH4_Digestion_LMGenes_delta_kg | float     |
| CH4_Effluent_SolidSep_delta_kg | float     |
| CH4_Effluent_EcoPond_delta_kg  | float     |
| N2O_Effluent_SolidSep_delta_kg | float     |
| N2O_SynthFert_UI_delta_kg      | float     |

#### smry_livestock_annual_mitign_delta

| Column_Title                   | Data_Type |
|:-------------------------------|:----------|
| Entity_ID                      | str       |
| Period_End                     | date str  |
| CH4_Digestion_LMGenes_delta_kg | float     |
| CH4_Effluent_SolidSep_delta_kg | float     |
| CH4_Effluent_EcoPond_delta_kg  | float     |
| N2O_Effluent_SolidSep_delta_kg | float     |

#### smry_livestock_annual_by_Sector_mitign_delta

| Column_Title                   | Data_Type |
|:-------------------------------|:----------|
| Entity_ID                      | str       |
| Period_End                     | date str  |
| Sector                         | str       |
| CH4_Digestion_LMGenes_delta_kg | float     |
| CH4_Effluent_SolidSep_delta_kg | float     |
| CH4_Effluent_EcoPond_delta_kg  | float     |
| N2O_Effluent_SolidSep_delta_kg | float     |

#### smry_livestock_monthly_by_Sector_mitign_delta

| Column_Title                   | Data_Type |
|:-------------------------------|:----------|
| Entity_ID                      | str       |
| Period_End                     | date str  |
| YearMonth                      | date str  |
| Sector                         | str       |
| CH4_Digestion_LMGenes_delta_kg | float     |
| CH4_Effluent_SolidSep_delta_kg | float     |
| CH4_Effluent_EcoPond_delta_kg  | float     |
| N2O_Effluent_SolidSep_delta_kg | float     |

#### smry_livestock_monthly_by_StockClass_mitign_delta

| Column_Title                   | Data_Type |
|:-------------------------------|:----------|
| Entity_ID                      | str       |
| Period_End                     | date str  |
| YearMonth                      | date str  |
| Sector                         | str       |
| StockClass                     | str       |
| StockCount_mean                | float     |
| CH4_Digestion_LMGenes_delta_kg | float     |
| CH4_Effluent_SolidSep_delta_kg | float     |
| CH4_Effluent_EcoPond_delta_kg  | float     |
| N2O_Effluent_SolidSep_delta_kg | float     |

#### smry_fertiliser_annual_mitign_delta

| Column_Title              | Data_Type |
|:--------------------------|:----------|
| Entity_ID                 | str       |
| Period_End                | date str  |
| N2O_SynthFert_UI_delta_kg | float     |
