# utility script for exporting Rmd files to R and github markdown formats

library(knitr)
library(rmarkdown)

# FEM equations

purl(
  "utils/FEM_equations.Rmd",
  output = normalizePath("src/FEM_equations.R"),
  documentation = 0
)

render(
  "utils/FEM_equations.Rmd",
  output_format = md_document(variant = "gfm"),
  output_file = normalizePath("../FEM_equations.md")
  )

# Data specification and dictionary

render(
  "utils/FEM_data_specification.Rmd",
  output_format = md_document(variant = "gfm"),
  output_file = normalizePath("../FEM_data_specification.md")
  )