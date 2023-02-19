**README. Modeling spatiotemporal domestic wastewater variability:**
*Implications to measure sanitation efficiency*
================
Néstor DelaPaz-Ruíz, Ellen-Wien Augustijn, Mahdi Farnaghi, Raul
Zurita-Milla.
February, 2023

- <a href="#about" id="toc-about">About</a>
- <a href="#getting-started" id="toc-getting-started">Getting Started</a>
  - <a href="#pre-requirements"
    id="toc-pre-requirements">Pre-requirements</a>
- <a href="#usage" id="toc-usage">Usage</a>
  - <a href="#build-netlogo-images" id="toc-build-netlogo-images">Build
    NetLogo images</a>
  - <a href="#run-netlogo-containers" id="toc-run-netlogo-containers">Run
    NetLogo containers</a>
  - <a href="#build-rstudio-image" id="toc-build-rstudio-image">Build
    RStudio image</a>
  - <a href="#run-rstudio-container" id="toc-run-rstudio-container">Run
    RStudio container</a>
- <a href="#expected-results" id="toc-expected-results">Expected
  results</a>
- <a href="#support" id="toc-support">Support</a>
- <a href="#license" id="toc-license">License</a>
- <a href="#acknowledgements"
  id="toc-acknowledgements">Acknowledgements</a>

Affiliation: Department of Geo-Information Process (GIP), Faculty of
Geo-Information Science and Earth Observation (ITC), University of
Twente, Drienerlolaan 5, 7522 NB Enschede, The Netherlands

## About

This repository provides access to the materials (code-data),
software-environments (NetLogo, Rstudio, Docker containers), and the
steps for reproducing the results from the publication: *Modeling
spatiotemporal domestic wastewater variability: Implications to measure
sanitation efficiency*.

The information below guides you to execute two NetLogo simulations. One
represents a non-calibrated model, and the other is a calibrated and
evaluated model. The main outputs are the figures and tables
representing the results assessment of the mentioned publication.

## Getting Started

### Pre-requirements

You will need the following:

1.  Data:

- Download or copy this repository to the local folder where you plan to
  execute the code scripts.

2.  Open-source software:

- You have Docker Desktop installed and running in your computer
  (v.4.16.3 is recommended).See:
  <https://www.docker.com/products/docker-desktop/>
- A command-line shell: Git Bash is used for running the commands. See:
  <https://gitforwindows.org/>

3.  Read the full section of `Usage` before executing code.

4.  NetLogo alternative:

- Before building and running NetLogo images and containers in Docker
  Desktop consider that you can run the NetLogo models once you install
  NetLogo 6.1.1. Running NetLogo in Docker Desktop can take a couple of
  hours. [Link to NetLogo 6.1.1
  Downloads](https://ccl.northwestern.edu/netlogo/6.1.1/). Running
  NetLogo with your own NetLogo 6.1.1 installation can take less than 1
  hour if your computer has multiple processors and good RAM. For this
  option copy the provided `NetLogo.cfg` file and replace it at the
  folder: `C:\Program Files\NetLogo 6.1.1\app`. In this way, you are
  free to use several processors. Please, refer to the following link:
  [FAQ: How big can my model be? How many turtles, patches, procedures,
  buttons, and so on can my model
  contain?](http://ccl.northwestern.edu/netlogo/docs/faq.html#how-big-can-my-model-be-how-many-turtles-patches-procedures-buttons-and-so-on-can-my-model-contain).
  After the NetLogo installation, make sure to execute the
  `. ./code/newfiles.txt` in Git Bash and then you can jump to step 3)
  in the bellow Usage section and run the required 2 simulations.

## Usage

- Open Git Bash in the folder path of the repository.

- Execute the following command in Git Bash to set up new files to run
  NetLogo:

``` bash
. ./code/newfiles.txt
```

### Build NetLogo images

- Open Docker Desktop and verify the engine is running (green icon at
  the left-bottom corner).

- Execute the below commands in Git Bash to create NetLogo Docker
  images. Note that the two models must be created and run:

  - Model not calibrated, and model calibrated:

``` bash
docker build -f DockerfileNetlogoNocalibration --build-arg MODEL_NAME=dw.sms.abm.snt.2020.no.cal.val.1.nlogo --build-arg NETLOGO_VERSION=6.1.1 -t dwsmsabmsntnocalibration .
```

``` bash
docker build -f DockerfileNetlogo --build-arg MODEL_NAME=dw.sms.abm.snt.2020.cal.val.1.nlogo --build-arg NETLOGO_VERSION=6.1.1 -t dwsmsabmsntresults .
```

- Verify that the following images were created. Go to Docker
  Desktop/images: `dwsmsabmsntnocalibration` & `dwsmsabmsntresults`.

### Run NetLogo containers

- Execute the below command in Git Bash to run the XPRA X11 tool.

``` bash
docker run -d --name x11-bridge -e MODE="tcp" -e XPRA_HTML="yes" -e DISPLAY=:14 -e XPRA_PASSWORD=111 -p 10000:10000 jare/x11-bridge
```

- Go to Docker Desktop/containers to verify that the container
  `x11-bridge` is running.

- Run the calibrated and no calibrated models with the following steps:

Note that in the two commands bellow (1,7) you have to replace the
`'my/directory/path/to/results'` to your working directory. For example:
`'my/directory/path/to/results'` = `C:/Mydocker.dwvariability/results`.

1)  Execute the below command in Git Bash to run the container
    `dwsmsabmsntnocalibration`.

``` bash
docker run -it -d -m 20024M -d --name dwnetlogonocalibration --volumes-from x11-bridge -v 'my/directory/path/to/results':/home/results dwsmsabmsntnocalibration
```

2)  Once the Docker container is running, open your web browser
    (e.g. Chrome, Firefox) and paste the following URL in the search
    bar: <http://localhost:10000/index.html?encoding=rgb32&password=111>

You should see the NetLogo model.

3)  Press `ctrl+shift+B` to open the Behavior space menu and you should
    see the experiment: `cal.val.1 (50 runs)`.

4)  Press `Run`. In `Simultaneous runs in parallel` type 2 or 3
    processors and *deselect* all `Run options`.

Note: If you get the message running out of memory, go to containers in
Docker Desktop. Stop and start again the container named
`dwsmsabmsntnocalibration` to run again NetLogo and try 1 processor.

5)  Make sure that the NetLogo window `Running Experiment:` with a timer
    appears. Move the bar of `normal speed` to the right until showing
    fast. Processing time depends on the number of processors and
    computer features. For example, with 3 processors the simulation
    should take around 1:30 hrs.

6)  In Docker Desktop go to containers. Stop the
    `dwsmsabmsntnocalibration` container.

7)  To execute the following model container: `dwsmsabmsntresults` go to
    Git Bash and run the command:

``` bash
docker run -it --cpus=12 -d -m 20024M -d --name dwnetlogoresults --volumes-from x11-bridge -v 'my/directory/path/to/results':/home/results dwsmsabmsntresults
```

8)  For the `dwsmsabmsntresults` container, repeat steps from 2 to 6.

You can refer to the following tutorial which shows a video to run
NetLogo images in Docker:  
[https://forum.comses.net/t/containerizing-a-netlogo-model-gui-version/8236](Containerizing%20a%20NetLogo%20model%20-%20GUI%20version)

### Build RStudio image

- In Git Bash execute the following command to create the Rstudio image
  in Docker Desktop.

``` bash
docker build -f DockerfileRstudioDWresults -t dwsmsabmsnt2020rproj .
```

- Verify that the following image was created. Go to Docker
  Desktop/images: `dwsmsabmsnt2020rproj`.

### Run RStudio container

- Execute the below command in Git Bash to run RStudio. Do not forget to
  replace your own working directory. For example:
  `'my/directory/path/to/results'` = `C:/Mydocker.dwvariability/results`

``` bash
docker run -d --name dwrstudio -p 8787:8787 -e PASSWORD=mypassword -v 'my/directory/path/to/results':/home/rstudio/results dwsmsabmsnt2020rproj
```

- Go to Docker Desktop/containers to verify that the container
  `dwrstudio` is running. Open the following link in a web browser:

<http://localhost:8787>

- Type the following credentials:  
  `username:` rstudio  
  `mypassword:` mypassword

- In the RStudio user interface, go to files and open the
  `DW_ABM_before_after_calibration_and_validation.Rmd` file. The file
  content will appear. Press the `Knit` icon.

- The viewer panel shows the results.

## Expected results

The bellow content is what you can expect after pressing `Knit` in
RStudio.

\`\`\`\`{=html, echo=F, eval=F}

\`\`\`\`

## Support

This repository is expected to be in continuous improvement. For major
changes, please open an issue first to discuss what you would like to
improve.

## License

This project is licensed under the MIT license. Feel free to edit and
distribute this template as you like. See LICENSE for more information.

[MIT](https://choosealicense.com/licenses/mit/)

## Acknowledgements

The authors wish to express their gratitude for the valuable support in
the local implementation of this study, without which this research
cannot be consolidated: Carlos Pailles, Ana Velasco, Lucía Guardamino,
Rodrigo Tapia-McClung, Araceli Chávez, Diana Ramos, Daniela Goméz, José
Luis Pérez, Natalia Volkow, and the anonymous facilitators from Mexico
City, citizens of Tepeji del Río, and the INEGI department of microdata.
Scholarship funder: CONACYT-Alianza FiiDEM.
