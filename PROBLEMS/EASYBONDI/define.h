/************************************/
//restart
/************************************/
#define RESTART
#define RESTARTGENERALIDICES
#define RESTARTNUM -1



/************************************/
//black
/************************************/
#define MASS 10
#define BHSPIN 0.

/************************************/
//coordinates/grid
/************************************/
#define MYCOORDS MKS1COORDS
#define OUTCOORDS BLCOORDS
#define RMIN 1.5
#define RMAX 1000

#define MKSR0 0.
#define METRICAXISYMMETRIC

#define MINX (log(RMIN-MKSR0))
#define MAXX (log(RMAX-MKSR0))

#define MINY 0.99*M_PI/2.
#define MAXY 1.01*M_PI/2.

#define MINZ -1.
#define MAXZ 1.

//resolution
#define TNX 500
#define TNY 1
#define TNZ 1

#define NTX 1
#define NTY 1
#define NTZ 1



/************************************/
//boundary conditions
/************************************/
#define COPY_XBC
#define COPY_YBC
#define COPY_ZBC

/************************************/
//numerics
/************************************/
#define TSTEPLIM .5//kind of courant limiter
#define FLUXLIMITER 0
#define MINMOD_THETA 2.
#define INT_ORDER 1


/************************************/
// output
/************************************/
#define DTOUT1 100. //dt for basic output
#define ALLSTEPSOUTPUT 0
#define NOUTSTOP 10000
#define SIMOUTPUT 2


/************************************/
// physics
/************************************/

#define GAMMA (5./3.)
//nonrel:
//#define GAMMA (1.4)

/************************************/
// initial conditions
/************************************/
#define RHOMAX 1.e-4 //g/cm^3
#define TEMP 1.e7 //Kelvin
