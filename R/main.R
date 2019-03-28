#------------------------------------------------------------------------
# main.R        Main workflow of the analysis
#------------------------------------------------------------------------
#
# This script provides the main workflow



# Study area --------------------------------------------------------------

# Prepare study area, including an ocean mask and bathymetry
source("R/01_study_area/01_study_area.R")


# Argo analysis -----------------------------------------------------------

# Process Argo
source("R/02_argo/01_argo_proc.R")

# Persistence and coldspots
source("R/02_argo/02_argo_gaps.R")

# Plot Argo
source("R/02_argo/04_argo_plots.R")
