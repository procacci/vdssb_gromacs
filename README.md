# Absolute Dissociation  Free Energy calculations on HPCs: vDSSB tutorial for GROMACS users  
<center> <img src="FSDAMgromacs.png" alt="vDSSB in GROMACS" width="600" height="323"></center> <br>
<p style="text-align:justify"> This is a technical tutorial for the calculation of the absolute dissociation free energy between PF-07321332 and 3CL<sup>pro</sup> on high performing architectures using a nonequilibrium alchemical approach with the GROMACS code. The theoretical background of the methodology can be found <a href="https://pubs.acs.org/doi/full/10.1021/acs.jctc.0c00634"> here </a> and <a href="https://pubs.acs.org/doi/10.1021/acs.jcim.1c00909"> here </a>.   
The procedure is divided into six consecutive steps. The major massively parallel computational steps consist in the HREM simulations (<font color="#FF6347">Step 3</font>) and in the fast switching alchemical simulations (<font color="#FF6347">Step 5</font>). The Steps 1, 2 and 4 are fast preparatory automatized procedures for running the two major computational jobs on the HPC, <font color="#FF6347">Step 3</font> and <font color="#FF6347">Step 5</font>.  The last Step 6 is the automatized post-processing of the vDSSB data. Full output data for the application PF-07321332-3CL<sup>pro</sup> can be found on the Zenodo repository (<a href="https://zenodo.org/record/5139374"> https://zenodo.org/record/5139374 </a>).</p> 
<a href="step1.html"> Step 1 </a>: Docking (<b>local</b>) <br>
<a href="step2.html"> Step 2 </a>: Running <a href="https://github.com/MauriceKarrenbrock/HPC_Drug"> HPC_drug <a/> for HREM set-up (<b>local</b>) <br>
<a href="step3.html" style="color:#FF6347;"> Step 3 </a>: HREM simulations (<b>HPC</b>)  <br>
<a href="step4.html"> Step 4 </a>: Selection of the (enhanced sampled) configurations (<b>HPC</b>) <br>
<a href="step5.html" style="color:#FF6347;"> Step 5 </a>:  Fast Switching Alchemical Simulations (<b>HPC</b>)<br>
<a href="step6.html"> Step 6 </a>:   Calculation of dissociation free energy (<b>HPC/local</b>)<br>
<hr>
<font size="2"> Marina Macchiagodena, Maurice Karrenbrock, Marco Pagliai, Piero Procacci <br>
 Dipartimento di Chimica "Ugo Schiff", Università degli Studi di Firenze, Via della Lastruccia 3, 50019 Sesto Fiorentino, Italy <br>
 If you have any questions, please feel free to contact the <a href = "mailto: piero.procacci@unifi.it">authors</a>.
  </font>
  
