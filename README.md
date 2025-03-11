
**Reproducible results. Modeling spatiotemporal domestic wastewater variability:** 
*Implications to measure treatment efficiency* 
================ 

Journal article: <https://doi.org/10.1016/j.jenvman.2023.119680>

Repository: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.10242566.svg)](https://doi.org/10.5281/zenodo.10242566)

Néstor DelaPaz-Ruíz, Ellen-Wien Augustijn, Mahdi Farnaghi, Raul Zurita-Milla. February, 2023

-   <a href="#about" id="toc-about">About</a>
-   <a href="#getting-started" id="toc-getting-started">Getting Started</a>
    -   <a href="#pre-requirements"
        id="toc-pre-requirements">Pre-requirements</a>
-   <a href="#quick-reproducibility" id="toc-quick-reproducibility">Quick reproducibility</a>
-   <a href="#long-term-reproducibility" id="toc-long-term-reproducibility">Long-term reproducibility</a>
    -   <a href="#build-netlogo-images" id="toc-build-netlogo-images">Build NetLogo images</a>
    -   <a href="#run-netlogo-containers" id="toc-run-netlogo-containers">Run NetLogo containers</a>
    -   <a href="#build-rstudio-image" id="toc-build-rstudio-image">Build RStudio image</a>
    -   <a href="#run-rstudio-container" id="toc-run-rstudio-container">Run RStudio container</a>
-   <a href="#expected-results" id="toc-expected-results">Expected results</a>
-   <a href="#support" id="toc-support">Support</a>
-   <a href="#license" id="toc-license">License</a>
-   <a href="#acknowledgements"
    id="toc-acknowledgements">Acknowledgements</a>

Affiliation: Department of Geo-Information Processing (GIP), Faculty of Geo-Information Science and Earth Observation (ITC), University of Twente, Drienerlolaan 5, 7522 NB Enschede, The Netherlands

## About

This repository provides access to the materials (code-data), software-environments (NetLogo, Rstudio, Docker containers), and the steps for reproducing the results from the publication: *Modeling spatiotemporal domestic wastewater variability: Implications to measure sanitation efficiency*.

The information below guides you to execute two NetLogo simulations. One represents a non-calibrated model, and the other is a calibrated and evaluated model. The main outputs are the figures and tables representing the results assessment of the mentioned publication.

Note: If you found this repository useful and would like to support reproducibility and open science, I would appreciate a star for this repository. You can also send an email if you could replicate the results. Your reaction is relevant for monitoring and maintaining this material.

## Getting Started

### Pre-requirements

Used computational environment:

```         
Platform: x86_64-w64-mingw32/x64 (64-bit) 
Running under: Windows 11 x64 (build 22631)
Processor:  Intel(R) Core(TM) i7-10750H CPU @ 2.60GHz   2.59 GHz
Logical processors: 12 
Installed RAM   32.0 GB (31.6 GB usable)
System type 64-bit operating system, x64-based processor

Docker Desktop v.4.16.3

R version 4.3.1 (2023-06-16 ucrt)
RStudio 2023.12.1

NetLogo 6.1.1
```

1.  Data:

-   Download or copy this repository to a local folder .

2.  Open-source software:

Quick reproducibility (requires NetLogo/Rstudio experience):

-   Install and run Git Bash. See: <https://gitforwindows.org/>
-   Install and run NetLogo. See: <https://ccl.northwestern.edu/netlogo/6.1.1/>
-   Install Rstudio. See: <https://dailies.rstudio.com/version/2023.12.1+402/>
-   NetLogo note: For this option copy the provided `NetLogo.cfg` file and replace it at the folder: `C:\Program Files\NetLogo 6.1.1\app`. In this way, you are free to use several processors. Please, refer to the following link: [FAQ: How big can my model be? How many turtles, patches, procedures, buttons, and so on can my model contain?](http://ccl.northwestern.edu/netlogo/docs/faq.html#how-big-can-my-model-be-how-many-turtles-patches-procedures-buttons-and-so-on-can-my-model-contain). After the NetLogo installation, make sure to execute the `. ./code/newfiles.txt` in Git Bash.,

Long-term reproducibility (requires some familiarity with Docker):

-   Install and run Git Bash. See: <https://gitforwindows.org/>
-   Install and run Docker Desktop. See: <https://www.docker.com/products/docker-desktop/>
-   NetLogo note: Before building and running NetLogo images and containers in Docker Desktop consider that you can run the NetLogo models once you install NetLogo 6.1.1. Running NetLogo in Docker Desktop can take a couple of hours. Running NetLogo with your own NetLogo 6.1.1 installation can take around 25 minutes.

4.  Libraries and extensions:

-   NetLogo: The first time running the Netlogo file, you will get a windows to install the time extension. Follow the instructions to install it.
-   Rstudio: The first time that you open the R project execute the `renv::restore()` in the R console to load the required libraries. You can explore the library requirements in the `renv.lock` file.

## Quick reproducibility

This section is for Windows users familiar with NetLogo, Rstudio, and Git bash. Mac or Linux users can also try to reproduce results. Jump to the long-term reproducibility (usage) section, which uses Docker to reproduce results as the alternative for non-experienced users.

Steps for a quick reproduction:

1)  In a new folder, execute the following commands in git bash:

``` bash
git clone https://github.com/delapazruiz/domestic.wastewater.variability.git
```

``` bash
. ./code/newfiles.txt
```

2)  Open the NetLogo (v. 6.1.1) files and run the experiments. In Tools/BehaviorSpace, change to 25 runs and select processors to run each experiment. (time: around 25 min each)

``` bash
dw.sms.abm.snt.2020.cal.val.1.nlogo
```

``` bash
dw.sms.abm.snt.2020.no.cal.val.1.nlogo
```

3)  Open the Rstudio project file and verify the library requirements.

R Project file:

``` bash
domestic.wastewater.variability.Rproj
```

Make sure that 'renv' is installed and loaded.

``` bash
install.packages("renv")
```

Load the 'renv' library.

``` bash
library(renv)
```

Run the following in the R console to install the required libraries.

``` bash
renv::restore()
```

4)  Open the R markdown file and knit it to generate the report: (time: around 25 min)

``` bash
DW_ABM_before_after_calibration_and_validation.Rmd
```

## Long term reproducibility

-   Open Git Bash in the folder path of the repository.

-   Execute the following command in Git Bash to set up new files to run NetLogo:

``` bash
. ./code/newfiles.txt
```

### Build NetLogo images

-   Open Docker Desktop and verify the engine is running (green icon at the left-bottom corner).

-   Execute the below commands in Git Bash to create NetLogo Docker images. Note that the two models must be created and run:

    -   Model not calibrated, and model calibrated:

``` bash
docker build -f DockerfileNetlogoNocalibration --build-arg MODEL_NAME=dw.sms.abm.snt.2020.no.cal.val.1.nlogo --build-arg NETLOGO_VERSION=6.1.1 -t dwsmsabmsntnocalibration .
```

``` bash
docker build -f DockerfileNetlogo --build-arg MODEL_NAME=dw.sms.abm.snt.2020.cal.val.1.nlogo --build-arg NETLOGO_VERSION=6.1.1 -t dwsmsabmsntresults .
```

-   Verify that the following images were created. Go to Docker Desktop/images: `dwsmsabmsntnocalibration` & `dwsmsabmsntresults`.

### Run NetLogo containers

-   Execute the below command in Git Bash to run the XPRA X11 tool.

``` bash
docker run -d --name x11-bridge -e MODE="tcp" -e XPRA_HTML="yes" -e DISPLAY=:14 -e XPRA_PASSWORD=111 -p 10000:10000 jare/x11-bridge
```

-   Go to Docker Desktop/containers to verify that the container `x11-bridge` is running.

-   Run the calibrated and no calibrated models with the following steps:

Note that in the two commands bellow (1,7) you have to replace the `'my/directory/path/to/results'` to your working directory. For example: `'my/directory/path/to/results'` = `C:/Mydocker.dwvariability/results`.

1)  Execute the below command in Git Bash to run the container `dwsmsabmsntnocalibration`.

``` bash
docker run -it -d -m 20024M -d --name dwnetlogonocalibration --volumes-from x11-bridge -v 'my/directory/path/to/results':/home/results dwsmsabmsntnocalibration
```

2)  Once the Docker container is running, open your web browser (e.g.B Chrome, Firefox) and paste the following URL in the search bar: <http://localhost:10000/index.html?encoding=rgb32&password=111>

You should see the NetLogo model.

3)  Press `ctrl+shift+B` to open the Behavior space menu and you should see the experiment: `cal.val.1 (50 runs)`.

4)  Press `Run`. In `Simultaneous runs in parallel` type 2 or 3 processors and *deselect* all `Run options`.

Note: If you get the message running out of memory, go to containers in Docker Desktop. Stop and start again the container named `dwsmsabmsntnocalibration` to run again NetLogo and try 1 processor.

5)  Make sure that the NetLogo window `Running Experiment:` with a timer appears. Move the bar of `normal speed` to the right until showing fast. Processing time depends on the number of processors and computer features. For example, with 3 processors the simulation should take around 1:30 hrs.

6)  In Docker Desktop go to containers. Stop the `dwsmsabmsntnocalibration` container.

7)  To execute the following model container: `dwsmsabmsntresults` go to Git Bash and run the command:

``` bash
docker run -it --cpus=12 -d -m 20024M -d --name dwnetlogoresults --volumes-from x11-bridge -v 'my/directory/path/to/results':/home/results dwsmsabmsntresults
```

8)  For the `dwsmsabmsntresults` container, repeat steps from 2 to 6.

You can refer to the following tutorial which shows a video to run NetLogo images in Docker:\
[https://forum.comses.net/t/containerizing-a-netlogo-model-gui-version/8236](Containerizing%20a%20NetLogo%20model%20-%20GUI%20version)

### Build RStudio image

-   In Git Bash execute the following command to create the Rstudio image in Docker Desktop.

``` bash
docker build -f DockerfileRstudioDWresults -t dwsmsabmsnt2020rproj .
```

-   Verify that the following image was created. Go to Docker Desktop/images: `dwsmsabmsnt2020rproj`.

### Run RStudio container

-   Execute the below command in Git Bash to run RStudio. Do not forget to replace your own working directory. For example: `'my/directory/path/to/results'` = `C:/Mydocker.dwvariability/results/calibration.snt`

``` bash
docker run -d --name dwrstudio -p 8787:8787 -e PASSWORD=mypassword -v 'my/directory/path/to/results':/home/rstudio/results/calibration.snt dwsmsabmsnt2020rproj
```

-   Go to Docker Desktop/containers to verify that the container `dwrstudio` is running. Open the following link in a web browser:

<http://localhost:8787>

-   Type the following credentials:\
    `username:` rstudio\
    `mypassword:` mypassword

-   In the RStudio user interface, go to files and open the R project file:

``` bash
domestic.wastewater.variability.Rproj
```

-   Make sure that 'renv' is installed and loaded. Execute in the R console:

``` bash
install.packages("renv")
```

-   Load renv:

``` bash
library(renv)
```

-   Run the following in the R console to install and load the required libraries.

``` bash
renv::restore()
```

-   In Files, Home, open the R markdown file and Press the `Knit` icon to generate the report: (processing time: around 5 min). Click 'Yes' to any 'Install or Update' emergent message.

``` bash
DW_ABM_before_after_calibration_and_validation.Rmd
```

-   The viewer panel shows the results.

## Expected results

Download the repository and open the file: `DW_ABM_before_after_calibration_and_validation.html` to see expected results after pressing `Knit` in RStudio.

## Support

This repository is expected to be in continuous improvement. For major changes, please open an issue first to discuss what you would like to improve.

## License

This project is licensed under the MIT license. Feel free to edit and distribute this template as you like. See LICENSE for more information.

[MIT](https://choosealicense.com/licenses/mit/)

## Acknowledgements

The authors wish to express their gratitude for the valuable support in the local implementation of this study, without which this research cannot be consolidated: Carlos Pailles, Ana Velasco, LucC-a Guardamino, Rodrigo Tapia-McClung, Araceli ChC!vez, Diana Ramos, Daniela GomC)z, JosC) Luis PC)rez, Natalia Volkow, and the anonymous facilitators from Mexico City, citizens of Tepeji del RC-o, and the INEGI department of microdata. Scholarship funder: CONACYT-Alianza FiiDEM.
