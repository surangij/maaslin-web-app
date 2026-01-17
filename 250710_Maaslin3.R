# Load arguments
args <- commandArgs(trailingOnly = TRUE)
taxa_table_name <- args[1]
metadata_name <- args[2]
output <- args[3]
formula <- args[4] # Formula for the model
normalization <- args[5] # Normalization method
transform <- args[6] # Transformation method
augment <- as.logical(args[7]) # Augment data
standardize <- as.logical(args[8]) # Standardize data
max_significance <- as.numeric(args[9]) # Maximum significance level
median_comparison_abundance <- as.logical(args[10]) # Median comparison abundance 
median_comparison_prevalence <- as.logical(args[11]) # Median comparison prevalence
max_pngs <- as.numeric(args[12]) # Maximum number of PNGs to create
cores <- as.numeric(args[13]) # Number of cores to use      

# Read data
cat("Reading data files...\n")
taxa_table <- read.csv(taxa_table_name, sep = '\t', row.names = 1)
metadata <- read.csv(metadata_name, sep = '\t', row.names = 1)

## Factor the categorical variables to test IBD against healthy controls
#metadata$diagnosis <- 
#  factor(metadata$diagnosis, levels = c('nonIBD', 'UC', 'CD'))
#metadata$dysbiosis_state <- 
#  factor(metadata$dysbiosis_state, levels = c('none', 'dysbiosis_UC', 'dysbiosis_CD'))
#metadata$antibiotics <- 
#  factor(metadata$antibiotics, levels = c('No', 'Yes'))

# Check how the dataframes look like
cat("Data preview:\n")
print(taxa_table[1:5, 1:5])
print(metadata[1:5, 1:5])

# Create test output to verify directory is writable
write.table(data.frame(x=1:5), file = "output/test.tsv", sep = "\t")
cat("Test file created successfully\n")

# Test PNG creation capability
cat("Testing PNG creation...\n")
tryCatch({
  png("output/test_plot.png", width = 800, height = 600)
  plot(1:10, 1:10, main = "Test Plot")
  dev.off()
  cat("Test PNG created successfully\n")
}, error = function(e) {
  cat("PNG creation test failed:", e$message, "\n")
})

# Load maaslin3
cat("Loading maaslin3...\n")
library(maaslin3)
set.seed(1)

cat("Formula: ", formula, "\n")
cat("Normalization method:", normalization, "\n")
cat("Transformation method:", transform, "\n")
cat("Augment data:", augment, "\n")
cat("Standardize data:", standardize, "\n")
cat("Maximum significance level:", max_significance, "\n")
cat("Median comparison abundance:", median_comparison_abundance, "\n")
cat("Median comparison prevalence:", median_comparison_prevalence, "\n")
cat("Maximum PNGs to create:", max_pngs, "\n")
cat("Number of cores to use:", cores, "\n")


# Run maaslin3 analysis
cat("Running maaslin3 analysis...\n")
fit_out <- maaslin3(input_data = taxa_table,
                    input_metadata = metadata,
                    output = output,
                    formula = formula,
                    normalization = normalization,
                    transform = transform,
                    augment = augment,
                    standardize = standardize,
                    max_significance = max_significance,
                    median_comparison_abundance = median_comparison_abundance,
                    median_comparison_prevalence = median_comparison_prevalence,
                    max_pngs = max_pngs,
                    cores = cores)

cat("Analysis completed\n")

# List output files
output_files <- list.files("output", full.names = FALSE)
cat("Files created in output directory:\n")
for(file in output_files) {
  cat(" -", file, "\n")
}

# Check specifically for PNG files
png_files <- list.files("output", pattern = "\\.png$", full.names = FALSE)
cat("PNG files created:\n")
for(png in png_files) {
   cat(" -", png, "\n")
}

if(length(png_files) == 0) {
  cat("No PNG files were created. This might indicate an issue with graphics capabilities.\n")
} else {
  cat("Successfully created", length(png_files), "PNG files\n")
}