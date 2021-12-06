# Simulation platform
We chose **Julia** as the main engine for running the model. We briefly discuss why Julia might be a better alternative than R and Python, which are the main programming languages that researchers use for health economic evaluation. Often, codes written purely in R or Python are inefficient and thus require use of C++ (via RCpp or Cython, respecitvely) or Fortran. Consequently, normal R or Python users would have difficulty with reading, interpreting, and modifying (usually very long and tedious) C or C++ codes, presenting a major obstacle towards making a reference model that can be easily understood, modified and used. 

Julia is a new open-source, high-level (like R and Python) programming language for high-performance computing (like C), and thus solves the "2-langauge" paradigm. Julia codes can be often compact, quickly written (for maximal efficiency it requires experience and efforts) and easily interpretable. 

For accessibility, we provided an intefrace to R by wrapping the Julia package in R.

The code is publicly available and can be downloaded and run as a Julia or an R package.