# check param_saveout_tables

if(!isFALSE(param_saveout_tables) && length(param_saveout_tables) > 0) {
  
  # parse system datetime for appending to output filenames
  
  sys_datetime <- format(Sys.time(), "%Y-%m-%d_%H%M%S")
  
  tables_to_save <- setNames(
    lapply(param_saveout_tables, function(x) get(paste0(x, "_df"))),
    param_saveout_tables
  )
  
  if(length(tables_to_save) > 0) {
    
    # create output dir
    if (!dir.exists(param_output_path)) {
      dir.create(param_output_path, recursive = TRUE)
    }
  }
  
  if(param_output_data_format == "csv") {
    
    # Save out all tables as CSV files
    for (table_name in param_saveout_tables) {
      table_df <- get(paste0(table_name, "_df"))
      write_csv(
        table_df,
        file.path(
          param_output_path,
          paste0(table_name, "_", sys_datetime, ".csv")
        )
      )
      
    }
    
  } else if(param_output_data_format == "json") {
    
    # saveout one json file
    write_json(
      tables_to_save,
      file.path(
        param_output_path,
        paste0("output_", sys_datetime, ".json")
      ),
      digits=NA
    )
  
  }
}
