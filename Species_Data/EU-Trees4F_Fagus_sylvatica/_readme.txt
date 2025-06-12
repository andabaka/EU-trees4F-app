This document describes the content of the data set “EU-Tree4F” published along with the paper:
Mauri A., Girardello M., Strona G., Beck P. S. A., Forzieri G., Caudullo G., Manca F. & Cescatti A., 2022. EU-Trees4F, a dataset on the future distribution of European tree species. Scientific Data. DOI: https://doi.org/10.1038/s41597-022-01128-5


## LAYER NAMING SYSTEM ##
Layer names are composed of different codes, separated by underscores, that indicate the type of layer and the procedure used to create them. Some codes are always present in the file name (mand = mandatory), others are optional and used in specific cases only (opt = optional).

|---------------------------------------------------------------------------------|
|     SPECIES    |   MODEL/ENSEMBLE  | SCENARIO | PERIOD  | TYPE | DISTRIB | CLIP |
|     (mand)     |       (mand)      |  (opt)   | (mand)  |(mand)|  (mand) | (opt)| 
|----------------|-------------------|----------|---------|------|---------|------| 
| Abies_alba     | ens-clim          |  rcp45   | cur2005 | bin  |  pot    |  lu  |
| Acer_campestre | ens-sdms          |  rcp85   | fut2035 | prob |  nat    |      |
| Acer_opalus    | CCLM-CNRM-CERFACS |          | fut2065 | std  |  disp   |      |
| ...            | CCLM-ICHEC-EC-EAR |          | fut2095 | cv   |         |      |
|                | CCLM-MPI-M-MPI-ES |          |         |      |         |      |
|                | HIRH-ICHEC-EC-EAR |          |         |      |         |      |
|                | RACM-ICHEC-EC-EAR |          |         |      |         |      |
|                | RCA4-CNRM-CERFACS |          |         |      |         |      |
|                | RCA4-ICHEC-EC-EAR |          |         |      |         |      |
|                | RCA4-IPSL-IPSL-CM |          |         |      |         |      |
|                | RCA4-MOHC-HadGEM2 |          |         |      |         |      |
|                | RCA4-MPI-M-MPI-ES |          |         |      |         |      |
|                | WRF3-IPSL-IPSL-CM |          |         |      |         |      |
|---------------------------------------------------------------------------------|

SPECIES: scientific name of the tree species (genus and species)
MODEL/ENSEMBLE: name of the used regional climate models or the ensemble projection (ens-).
SCENARIO: emission scenario used for the model (RCP 4.5 or RCP 8.5)
PERIOD: 30-year time period
        cur2005 = centered on 2005
        fut2035 = centered on 2035
        fut2065 = centered on 2065
        fut2095 = centered on 2095
TYPE: type of layer
      bin = binary [0,1]
      prob = probability scaled from [0,1] to [0,1000]
      std = standard deviation
      cv = coefficient of variation
DISTRIB: type of species distribution
         pot = potential
         nat = realized (masked with native range)
         disp = natural dispersal model (Migclim)
CLIP: clipped by land use (masked with forest areas)

Examples:
- Abies_alba_ens-clim_rcp45_fut2065_bin_disp_lu.tif = binary habitat suitability map of Abies alba for future period centered on 2065 using the dispersal model (Migclim) and the climatic ensemble projection with the emission scenario RCP 4.5, the result is clipped with the forest mask.
- Abies_alba_ens-sdms_cur2005_prob_pot.tif =  habitat suitability map of Abies alba for the current period centered on 2005 using the SDM ensemble projections with the emission scenario RCP 8.5. 
- Abies_alba_RCA4-MPI-M-MPI-ES_rcp85_fut2035_bin_pot.tif = binary habitat suitability map of Abies alba for the future period centered on 2035 using the regional climate model “RCA4-MPI-M-MPI-ES” with the emission scenario RCP 8.5.



## DATA SET FOLDERS ##

The data set is organized in 4 main folders:

- ENS_CLIM: the layers derived from the climatic ensemble mean approach that projects the consensus model from Biomod2 into future conditions using the average output of the 11 RCMs. The ensemble binary layers (folder /bin) are GeoTIFF raster files in the Lambert Azimuthal Equal Area (EPSG:3035) reference system with integer number values 0 and 1. The ensemble probability layers (folder /prob) are GeoTIFF raster files in the WGS84 (EPSG:4326) reference system with integer number values from 0 to 1000. 

/ens_clim
    |_ /bin
    |_ /prob 
 
 
- SDMS_CLIM: the layers derived from the SDM ensemble mean that projects the consensus model for every single RCM, and a posteriori averages of the output of the 11 SDMs. The ensemble binary layers (folder /binaries) are GeoTIFF raster files in the Lambert Azimuthal Equal Area (EPSG:3035) reference system with integer number values 0 and 1. The ensemble probability layers (folder /prob) with integer number values from 0 to 1000 and the ensemble standard deviation layers (folder /std), both are GeoTIFF raster files in the WGS84 (EPSG:4326) reference system. 

/ens_sdms
    |_ /bin
    |_ /prob
    |_ /std


- SINGLE_MODELS: the output maps derived from Biomod2 using the 11 regional climate models. For each of the models, the potential distribution maps are available as probabilities (folder /prob), and in binary format (folder /bin) along with the associated coefficient of variation (folder /cv). All maps are in GeoTIFF format WGS84 (EPSG:4326).

/single_models
    |_ /Species_name
        |_ /bin  
        |_ /prob
        |_ /cv


- PNGS: output maps of the tree species potential distributions in PNG image format. In the folder /disp, the maps show in green and blue the potential distribution range (according to ensemble SDM projections). The expected distribution range as simulated using a dispersal model (Migclim) is shown in green, and the blue area represents the potential suitable range that is not occupied by the species due to dispersal limitations. In the folder /disp_2095 the maps show the potential distribution range using a dispersal model (Migclim) modelled until the end of the century: in green the ‘Stable presence’ areas that will remain suitable habitat from the present until the end of the century; in red the ‘Decolonized’ areas that will become climatically unsuitable by the end of the century; in blue the ‘Suitable but not occupied’ areas that will become climatically suitable by the end of the century but will not be naturally colonized due to dispersal limitations; in grey ‘Always absent’ where the species will remain absent.

/pngs
    |_ /disp
    |_ /disp_2095

