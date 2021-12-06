# Simulation baseline setting
Agents enter the simulation from bith, are updated annually, and live until they reach the maximum age or the end of the time horizon. We assume that the death always occurs as the last event.

There are six major input parameters:
* max_age: The maximum age of the agent. 
* starting_year: the starting year of the simulation. 
* time_horizon: the time window over which the agent lives.
* n: the baseline number of agents for the starting year. The subsequent number of agents depends on the population growth.
* population_growth_type: the population growth trajectory type defined by Statistics Canada.
* parameters: module parameters. See each of the module for details.

Note that each module contains a set of parameters and a process function that uses the parameters as the input.

Here is the current version of the schematic illustration of the disease pathway.
![Process Diagram](../../figures/model/asthma_model_diagram_April05_2021.png)

