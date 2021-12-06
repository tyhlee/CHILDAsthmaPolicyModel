[![Build Status](https://travis-ci.com/tyhlee/CHILDAsthmaPolicyModel.jl.svg?branch=master)](https://travis-ci.com/tyhlee/CHILDAsthmaPolicyModel.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/tyhlee/CHILDAsthmaPolicyModel.jl?svg=true)](https://ci.appveyor.com/project/tyhlee/CHILDAsthmaPolicyModel-jl)
[![Coverage](https://codecov.io/gh/tyhlee/CHILDAsthmaPolicyModel.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/tyhlee/CHILDAsthmaPolicyModel.jl)
[![Coverage](https://coveralls.io/repos/github/tyhlee/CHILDAsthmaPolicyModel.jl/badge.svg?branch=master)](https://coveralls.io/github/tyhlee/CHILDAsthmaPolicyModel.jl?branch=master)

# Overview
This is a discrete-event-simulation whole-disease model of asthma implemented in Julia. It is the back-bone of the [R package](https://github.com/tyhlee/AsthmaR), which is a wrapper of the Julia package for R.

# Version

## 1.0
* The schematic illustration of the model is provided below:
![Process Diagram](figures/model/asthma_model_diagram_April05_2021.png)
* It is composed of the following components:
	* [Conceptual framework](documentation/V1/conceptual_framework.md)
	* [Simulation platform](documentation/V1/simulation_platform.md)
	* [Simulation baseline setting](documentation/V1/simulation_baseline_setting.md)
	* [Birth module](documentation/V1/birth_module.md)
	* [Death module](documentation/V1/death_module.md)
	* [Antibiotic drug use module](documentation/V1/antibiotic_drug_use_module.pdf)
	* [Asthma incidence module](documentation/V1/asthma_incidence_module.pdf)
	* [Asthma control module](documentation/V1/asthma_control_module.md)
	* [Asthma exacerbation module](documentation/V1/asthma_exacerbation_module.pdf)

# Update logs

## Update [Jan 06 2021]
* A discrete-event (not continuous!) time simulation model with discrete events is being developed. Each agent in the model is updated *annually*.
* This is an open-population model, but the initial population has not been created. Each year, a set of newborns/agents enter the simulated world (the number of babies is based on the population projection from Stats Canada). Currently, 2018-2067 is supported.
* Currently every person in the model is followed till death.
* Here is the list of events that each person may go through:
    * Asthma incidence
    * Death

## Update [Jan 07 2021]
* Added the framework of the three additional processes:
    * Asthma control
    * Asthma severity
    * Asthma exacerbation
* The process diagram is provided:
![Process Diagram](figures/model/asthma_model_diagram_Jan07.png)

## Update [Jan 14 2021]
* Antibiotic drug usage module has been added.
* Setting the time window = 20 years, max age = 111, and n= 500,000, the current code takes about 15 sec to run for each year.
* The process diagram has been updated accordingly:
![Process Diagram](figures/model/asthma_model_diagram_Jan14_20.png)

## Update [Jan 22 2021]
* A prototype modular framework has been implemented.
* Memory allocation is better, but computation time is longer.
* The framework needs to be further optimized for better performance.

## Update [Feb 5 2021]
* Milestone #1 is finished; see the issue.
* The model can be run from R.

## Update [Feb 17 2021]
* Asthma control module is implemented.
* The [control level plot](figures/Feb_17_2021/control.png) is obtained under the same simulation setting used for Milestone #1.

## Update [March 4 2021]
* Asthma exacerbation module is implemented.

## Update [March 9 2021]
* Asthma exacerbation module is re-implemented; exacerbation is treated as a count variable.
* See the [plot of the exacerbation rates](figures/March_9_2021/exacerbation_rate.png).
* The rate is little higher than expected; I expected it to be around 0.4.

## Update [April 5 2021]
* The code has been re-structured in response to comments provided by two anonymous reviewers (see Issue [#2](/../../issues/2)).

## Update [December 6 201]
* The first version of the model is ready after calibration.
