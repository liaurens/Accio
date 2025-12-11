/*==========================================================
  get_bolt_force_schmidt_neuper_mex.c

  Calculates bolt force using the Schmidt-Neuper model

  * Syntax:
 	fBolt = get_bolt_force_schmidt_neuper_mex(
 				fvFls, p, lambda, z1, z2, fApplied)
  * Inputs:
 	- fvFls, p, lambda, z1, z2 [double], [nRows x 1]
 	- fApplied [double], [nRows x nBins]

  * Output:
 	- fBolt [double], [nRows x nBins]

  This is a MEX-file for MATLAB.

*========================================================*/

#include "mex.h"

/* The computational routine */
void test(double *fvFls, double *p, double *lambda, double *z1, double *z2, double *fApplied, double *fBolt,
		  int nDims, const mwSize *dims)
{
	int i, iR, dim0;
	int nElem = 1;

	// Count total number of elements
	for (i=0; i<nDims; i++) {
		nElem = nElem * dims[i];
    }

	// Get number of rows
	dim0 = dims[0];

	// Precalculate variables that only vary in dimension 0
	double tmp1[dim0], tmp2[dim0];

	for (iR=0; iR<dim0; iR++){
		tmp1[iR] = fvFls[iR] + p[iR] * z1[iR];
		tmp2[iR] = (lambda[iR] * z2[iR] - (fvFls[iR] + p[iR] * z1[iR])) / (z2[iR] - z1[iR]);
	}

	// Linearly loop through 3D matrix to fill fBolt
	for (i=0; i<nElem; i++){
		// Row index
		iR = i % dim0;

		if (fApplied[i] <= z1[iR]){
			// First linear function
			fBolt[i] = fvFls[iR] + p[iR] * fApplied[i];

		} else if (fApplied[i] > z2[iR]){
			// Third linear function
			fBolt[i] = lambda[iR] * fApplied[i];

		} else { // z1 > fApplied <= z2
			// Second linear function - in between 1 and 3
			fBolt[i] = tmp1[iR] +
				tmp2[iR] * (fApplied[i] - z1[iR]);
		}
	}
}

/* The gateway function */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[])
{
    double *fvFls, *p, *lambda, *z1, *z2, *fApplied; 	// INPUT
	double *fBolt;      								// OUTPUT
	int nDims, nDimsTest, nelem;
	int i;
	int nInput = 6;
	const mwSize *dims;
	const mwSize *dimsTest;

    // check for proper number of arguments
    if(nrhs!=nInput) {
        mexErrMsgIdAndTxt("get_bolt_force_schmidt_neuper_mex:nrhs","MEX: Six inputs required.");
    }
    if(nlhs > 1) {
        mexErrMsgIdAndTxt("get_bolt_force_schmidt_neuper_mex:nlhs","MEX: One output required.");
    }

	// get dimensions of the fApplied matrix
	nDims = mxGetNumberOfDimensions(prhs[nInput - 1]);
	dims = (const mwSize *) mxGetDimensions(prhs[nInput - 1]);

    // make sure the fApplied is 2D
    if(nDims!=2) {
        mexErrMsgIdAndTxt("get_bolt_force_schmidt_neuper_mex:fAppliedIsNot3D","fApplied is expected to be a 3D matrix");
    }

	// make sure all input arguments are type double
	for(i=0; i<(nInput); i++){
		if(!mxIsDouble(prhs[i])) {
			mexErrMsgIdAndTxt("get_bolt_force_schmidt_neuper_mex:isNotDouble","Input %i is expected to be a double", i+1);
		}
	}

	/* make sure all input arguments except fApplied are :
	- column vectors [nRows x 1] or [1]
	- equal nRows as fApplied
	*/
	for(i=0; i<(nInput-1); i++){
		nDimsTest = mxGetNumberOfDimensions(prhs[i]);
		dimsTest = (const mwSize *) mxGetDimensions(prhs[i]);
		if (nDimsTest > 2 || dimsTest[1] > 1) {
			mexErrMsgIdAndTxt("get_bolt_force_schmidt_neuper_mex:isNotColumnVec","Input %i is expected to be a 1D column vector", i+1);
		}
		if (dimsTest[0] != dims[0]) {
			mexErrMsgIdAndTxt("get_bolt_force_schmidt_neuper_mex:isNotEqualSize","Input %i is expected to have as many rows as fApplied", i+1);
		}
	}

    // get pointers to input data
	fvFls = mxGetPr(prhs[0]);
	p = mxGetPr(prhs[1]);
	lambda = mxGetPr(prhs[2]);
	z1 = mxGetPr(prhs[3]);
	z2 = mxGetPr(prhs[4]);
	fApplied = mxGetPr(prhs[5]);

	// create output matrix
	plhs[0] = mxCreateNumericArray(nDims, dims, mxDOUBLE_CLASS, mxREAL);

    // get a pointer to the real data in the output matrix
    fBolt = mxGetPr(plhs[0]);

    // call the computational routine
    test(fvFls, p, lambda, z1, z2, fApplied, fBolt, nDims, dims);
}
