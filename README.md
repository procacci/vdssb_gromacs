# Absolute Dissociation  Free Energy calculations on HPCs: vDSSB tutorial for GROMACS users  
<center> <img src="FSDAMgromacs.png" alt="vDSSB in GROMACS" width="600" height="323"> <br>
This Supporting Information document is conceived as a tutorial for the calculation of absolute dissociation free energy between PF-07321332 and 3CL$^{\rm pro}$.
The methodology is divided into six consecutive steps. For each step, we report the computational details. The major massively parallel computational step consists in the HREM simulations (Step 3) and in fast switching alchemical simulations (Step 5). The Steps 1, 2 and 4 are fast preparatory automatized procedures for running the two major computational jobs on the HPC. The last Step 6 is the automatized post-processing of the vDSSB data. All files necessary (filenames are indicated in \bb{blue bold}) are in the compressed SI.zip archive. In the archive are present also the output file/folder as a reference to verify the success of the protocol application (filenames in the text are in \br{red bold} with OUT keyword). Full output data for the application PF-07321332-3CL$^{\rm pro}$ can be found on the Zenodo repository (https://zenodo.org/record/5139374). <br>
<a href="step1.html"> Step 1 </a>: Docking (local)     
<a href="step2.html"> Step 2 </a>: Running <a href="https://github.com/MauriceKarrenbrock/HPC_Drug"> HPC_drug <a/> for HREM set-up (local) <br>
  <a href="step3.html"> Step 3 </a>: HREM simulations (<b> HPC </b>)  <br>
  <a href="step4.html"> Step 4 </a>: Selection of the (enhanced sampled) configurations (<b> HPC </b>) <br>
  <a href="step5.html"> Step 5 </a>:  Fast Switching Alchemical Simulations (<b> HPC</b>)<br>
  <a href="step6.html"> Step 6 </a>:   Calculation of dissociation free energy (<b> HPC </b>/local)
