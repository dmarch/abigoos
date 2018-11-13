# abigoos
Integraton of Animal-Borne Instruments into Global Ocean Observing Systems

This repository provides the R code that accompanies the article "Biologging in under-sampled regions of the global ocean"



## Structure of the repository
* data_paths.R: Script to set your data paths, temp and output folders
* /argo: folder with scripts to process Argo data (density, undersampled, hotspot, eez, gradients)
* /tel: folder with scripts to process animal telemetry data
* /eoo: folder with scripts to process extents of occurrence of species
* /overlap: folder with scripts to overlap under-sampled regions with species distributions
* /overlap/ov_eoo.R
* /overlap/ov_tel.R
* /overlap/compare_eoo_tel.R
* /ocean: folder with script to process the ocean and landmask
* /common: utils.R, oceanmask.R, zonal.R
* /plots: R scripts for generating the figures
* /output: output files. (figures and nc)


## Derived data products
* Ocean mask
* List of animal-borne platform species (with results from analysis). 
* Argo gaps (unsampled and undersampled) per year. (1nc)
* EOO maps per species (1nc) => not sure if could be redistributed...
* Telemetry maps per species (1nc) => not sure if could be redistributed...
* Overlap maps with EOO per species (1nc)
* Overlap maps with telemetry per species (1nc)


## Third-party data used
* Bathymetry
* Argo profiles from GDAC
* MEOP-CTD database
* OBIS-SEAMAP
* IUCN spatial data
* Birdlife
* SWOT
* SeaVox Salt and Fresh Water Body Gazetter (v16 2015)
* Land mask, Natural Earth

## Workflow
