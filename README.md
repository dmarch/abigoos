# abigoos
Integraton of Animal-Borne Instruments into Global Ocean Observing Systems

This repository provides the R code that accompanies the article "Monitoring the oceans with animal-borne platforms to complement global ocean observing systems"



## Structure of the repository

* config.R: Script to set your data paths
* /argo: folder with scripts to process Argo data
* /abp: folder with scripts to process animal-borne platform data
* /eoo: folder with scripts to process extents of occurrence of species
* /overlap
* /overlap/ov_eoo.R
* /overlap/ov_tel.R
* /overlap/compare_eoo_tel.R
* /common: utils.R, oceanmask.R, zonal.R
* /plots: R scripts for generating the figures
* /output: output files. (figures and nc)


## Derived data products
* Ocean mask
* List of animal-borne platform species (with results from analysis). 
* Argo gaps (unsampled and undersampled) per year. (1nc)
* EOO maps per species (1nc) => not sure if could be redistributed...
* Telemetry maps per species (1nc) => not sure if could be registributed...
* Overlap maps with EOO per species (1nc)
* Overlap maps with telemetry per species (1nc)


## Third-party data (/ext folder)
* Bathymetry
* Argo profiles from GDAC
* MEOP-CTD database
* OBIS-SEAMAP
* IUCN spatial data
* Birdlife
* SWOT
* SeaVox Salt and Fresh Water Body Gazetter (v16 2015)
* Land mask, Natural Earth
