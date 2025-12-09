**SST-Sea-ice ancillary file generation**

Step-by-step guide to producing regridded (for the n96 or n216 grid) monthly corrected sea-ice and SST values from either HadISST or input4mips datasets.


[**HadISST**](https://www.metoffice.gov.uk/hadobs/hadisst/index.html)
- "Monthly globally-complete fields of SST and sea ice concentration on a 1 degree latitude-longitude grid from 1870 to date"
- .nc.gz files were downloaded [here](https://www.metoffice.gov.uk/hadobs/hadisst/data/download.html), with file names:
	- `HadISST_sst.nc.gz` (~240Mb)  
	- `HadISST_ice.nc.gz` (~17Mb)


[**input4mips**](https://aims2.llnl.gov/search)
- Data described in @EyringEtAl2016 used for AMIP experiments
- Sea-ice/SST data regridded from the [merged Hadley-OI SST](https://climatedataguide.ucar.edu/climate-data/merged-hadley-noaaoi-sea-surface-temperature-sea-ice-concentration-hurrell-et-al-2008) product originally described by @HurrellEtAl2008 ...
	- "developed as surface forcing data sets for AMIP style uncoupled simulations of the Community Atmosphere Model (CAM). The Hadley Centre's SST/SIC version 1.1 (HADISST1), which is derived gridded, bias-adjusted in situ observations, were merged with the NOAA-Optimal Interpolation (version 2; OI.v2) analyses. The HADISST1 spanned 1870 onward but the OI.v2, which started in November 1981, better resolved features such as the Gulf Stream and Kuroshio Current which are important components of the climate system. Since the two data sets used different development methods, anomalies from a base period were used to create a more homogeneous record. Also, additional adjustments were made to the SIC data set."
- Data is available from 1870 to 2022-12 (as of 30-07-2025)
- .nc files were downloaded [here](https://aims2.llnl.gov/search), with file names:
	- `tos_input4MIPs_SSTsAndSeaIce_CMIP_PCMDI-AMIP-1-1-9_gn_187001-202212.nc`
	- `siconc_input4MIPs_SSTsAndSeaIce_CMIP_PCMDI-AMIP-1-1-8_gn_187001-202112.nc`


**Prerequisites to SST/Sea-ice ancillary file generation:**
1. MetOffice MOSRS account (access to data processing scripts)
2. The land-sea fractional mask for n96 and n216 (0.0=sea point, 1.0=land point)
	- Make sure that this is the ACCESS land-sea fractional mask (not the UM)
3. NCI gadi account with xp65 membership* (not required but will give access to key packages like "ants")


**SST/Sea-ice ancillary file generation steps:**
After getting access to a MOSRS account, details for ancillary file creation is described by the MetOffice [here](https://code.metoffice.gov.uk/trac/ancil/wiki/CMIP6/ForcingData/SstSeaIce), with further details on the correction steps [here](https://code.metoffice.gov.uk/trac/ancil/ticket/620).
- The HadISST/input4mips datasets are regridded for the n96/n216 grid and processed so that after interpolation from the monthly mean to higher temporal resolution (i.e. daily), calculation of the monthly mean still closely matches observations
- Note that the code is setup to regrid the HadISST/input4mips datasets followed by application of the Karl Taylor procedure (method of value correction) - note that this produces ancillary files with unphysical values (e.g. sea-ice concentration <0)
- Processing code is located [here](https://code.metoffice.gov.uk/trac/ancil/browser/contrib/branches/dev/jeffknight/r4697_amiplbcs4cmip6/SstSeaIce)
1. Pre-processing the input4mips/HadISST datasets
	- The input4mips dataset does not require preprocessing, go to step 2.
	- The HadISST dataset has slightly different format to the input4mips data- and so was processed using python using `reformat_HADISST_files.ipynb`, this mainly involves changing variable names, units, longitudinal range and adding attributes
2. Modification of the MetOffice processing code 
	1. Modifying the paths in the control file `anc_control_amip4cmip6.py`
		1. Input data file paths and filenames: input4mips/ reformatted HadISST
		2. Path and filename of land-sea mask: for ACCESS n96- `/g/data/access/projects/access/data/ancil/access_cm2_n96e/O1/`, `qrparm.landfrac`
		3. Working directory - note 6+ files are generated >~5 GB
		4. Output files - note 2-4 (2 if only regridding for n96) files are generated ~800 MB
		5. Fortran source: path to where `karl_taylor_hadgam3_n96e.f` and `karl_taylor_hadgam3_n216e.f` is located
	2. Modification to the fortran program `karl_taylor_hadgam3_n96e.f`
		1. Four key variables must be edited for the input file time period and output required by the user- ==If these four edits do not match the input dataset, the resulting file will be produced but the output file longitude is shifted by 180 degrees with weird/no values==
			1. `iyrnrd` Last year of interest minus a buffer year (second last year in the input dataset): 3 instances (in code this value is 2015)
			2. `iyrn` Laster year - buffer year (final year in input dataset): 1 instance (in code this value is 2016)
			3. `nmon` Total number of months in the input dataset (including the buffer first and last years): 1 instance (in code this value is 1764)
			4. `nmont` Total number of years in input dataset (including the buffer first and last years): 3 instances (in code this value is 147)
			5. Modification to `run_make_amip_lbcs.py` change 
			`os.system('cp '+p_work+'karl/hadisstbc_sic_192x144_1871_2024.pp '+p_work+'seaice_amip_karled_n96e.pp')`
			- Make sure 1871_2024 are the interest years (second and second last years in the input file)
		2. Other edits to specific lines are detailed *here* 
	3. Modification to `regrid_input_ants.py`
	4. Modification *build_nl* to `utils.py`
	5. Modification to `run_make_amip_lbcs.py`
3. Edit paths in `run_sea-ice-sst_processing_script.sh` to path your file paths
4. Run code `qsub run_sea-ice-sst_processing_script.sh`


**Output ancillary files**
- Located in the output file directory defined by `anc_control_amip4cmip6.py`
- Note that the first (generally 1870) and last years (in my case 2024) of the processed output data files will contain uncorrected SST/seaice values *noted by the MetOffice under* [what do the files contain?](https://code.metoffice.gov.uk/trac/ancil/wiki/CMIP6/ForcingData/SstSeaIce)
- Check files with xconv `xconv seaice_amip_n96e.anc`


**Update suite model ancillary file paths**
- Current ACCESS .anc file location and name: `app/um/rose-app.conf:ancilfilename='/g/data/access/TIDS/CMIP6_**ANCIL**/data/**ancil**s/amip_fix/timeseries_1870-2018/SstSeaIce/seaice_amip_n96e.anc'`
1. Change path to new ancillary file
