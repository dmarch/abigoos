# abigoos

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.2638123.svg)](https://doi.org/10.5281/zenodo.2638123)


This repository provides the R code that accompanies the article "Towards the integration of animal-borne instruments into global ocean observing systems"


### Requirements
* R-studio with R >= 3.1.0
* Packages:
  * Data manipulation: dplyr, lubridate, stringr, reshape2, data.table, foreign, Hmisc
  * Spatial data: rgdal, maptools, geosphere, rgeos, sp, raster, ncdf4
  * Plots: ggplot2
  * API: rfishbase, rredlist, jsonlite


## Installation

The R code can be downloaded from the following [link](https://github.com/dmarch/abigoos/archive/master.zip). Additionaly, check out this guideline at the [Rstudio website](https://support.rstudio.com/hc/en-us/articles/200532077-Version-Control-with-Git-and-SVN) for installing Git on your computer and creating a new project.


## Getting started

There several steps that need to be conducted before running the scripts. 

* Download raw data from third-party providers (see bellow)
* Edit the paths to those datasets
* Run the scripts following the suggested order from folders and scripts


## Datasets

### Raw data

Most of the data used is open and freely available. However, some datasets (e.g. Birdlife, SWOT and OBIS-SEAMAP) will require a data request or form registration with the data providers.

* The GEBCO 2014 Grid, version 20150318, www.gebco.net.
* Land polygons using the 1:50 vector map from Natural Earth (www.naturalearthdata.com), 
* SeaVox Salt and Fresh Water Body Gazetter (v16 2015) from Marine Regions (http://www.marineregions.org)
* Exclusive Economic Zones (EEZ) from Marine Regions (http://www.marineregions.org).
* Profile directory of Argo floats. Argo (2000). Argo float data and metadata from Global Data Assembly Centre (Argo GDAC). SEANOE. http://doi.org/10.17882/42182.
* IUCN. The IUCN Red List of Threatened Species. Version 2017-3. http://www.iucnredlist.org. (2017).
* MEOP-CTD database. http://doi.org/10.17882/45461
* OBIS-SEAMAP. Halpin, P. et al. OBIS-SEAMAP: The World Data Center for Marine Mammal, Sea Bird, and Sea Turtle Distributions. Oceanography 22, 104–115 (2009).
* BirdLife International and Handbook of the Birds of the World (2017) Bird species distribution maps of the world. Version 2017.2. Available at http://datazone.birdlife.org/species/requestdis.
* SWOT. Kot, C. Y. et al. The State of the World’s Sea Turtles Online Database: Data provided by the SWOT Team and hosted on OBIS-SEAMAP. Oceanic Society, Conservation International, IUCN Marine Turtle Specialist Group (MTSG), and Marine Geospatial Ecology Lab, Duke University. Available at: http://seamap.env.duke.edu/swot. 



## Use of external services

This project uses an external service [IUCN](https://apiv3.iucnredlist.org/) that requires the generation of a token. It also uses the API from FishBase and SeaLifeBase.


## Use of external software

Distribution ranges of seabirds were provided in a ESRI geodatabase by Birdlife . Previous to link them with the species list, a filtered query was constructed using ArcMap software. Further details are provided in the script [05_link_eoo.R](https://github.com/dmarch/abigoos/blob/master/03_species/05_link_eoo.R)


## License

Copyright (c) 2019 David March  
Licensed under the [MIT license](https://github.com/dmarch/abigoos/blob/master/LICENSE).


## Citation

David March, Joaquín Tintoré, Brendan J Godley. (2019) Towards the integration of animal-borne instruments into global ocean observing systems.


## Acknowledgements

We gratefully acknowledge funding by the BBVA Foundation (“Ayudas Fundación BBVA a Equipos de Investigación Científica 2016”) and the European Union’s Horizon 2020 research and innovation programme under the Marie Skłodowska-Curie grant agreement No 794938. DM acknowledge support from Spanish Government (grant “Juan de la Cierva-Formación” FJCI-2014-20064, grant “José Castillejo” CAS17/00193). We thank all the data providers for making their data available and making this study possible. 
