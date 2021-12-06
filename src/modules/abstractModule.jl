abstract type Agent_Module end

abstract type Simulation_Module end

# sub types
abstract type Birth_Module <: Simulation_Module  end
abstract type Immigration_Module <: Simulation_Module  end
abstract type Emigration_Module <: Simulation_Module  end
abstract type Death_Module <: Simulation_Module  end
abstract type AntibioticExposure_Module   <: Simulation_Module  end
abstract type Asthma_Module   <: Simulation_Module  end
abstract type Incidence_Module   <: Asthma_Module  end
abstract type Exacerbation_Module   <: Asthma_Module  end
abstract type Severity_Module   <: Asthma_Module  end
abstract type Control_Module   <: Asthma_Module  end
