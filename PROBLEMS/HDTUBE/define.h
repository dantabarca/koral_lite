#define MYCOORDS MINKCOORDS
#define NX 500
#define NY 1
#define NZ 1
#define TSTEPLIM .5//kind of courant limiter
#define COPY_XBC
#define COPY_YBC
#define COPY_ZBC
#define FLUXLIMITER 0
#define MINMOD_THETA 2.
#define INT_ORDER 1
#define DTOUT1 5.e0 //dt for basic output
#define ALLSTEPSOUTPUT 0
#define GAMMA (5./3.)
#define NOUTSTOP 20
//nonrel:
//#define GAMMA (1.4)
#define MINX -50
#define MAXX 50
#define MINY -1.
#define MAXY 1.
#define MINZ -1.
#define MAXZ 1.

#define ST_P1 1.
#define ST_P5 .1

/*
//non-rel
#define ST_RHO1 1.e5
#define ST_RHO5 .125e5
#define ST_U1 2.5
#define ST_U5 .25
*/

//rel
#define ST_RHO1 10.
#define ST_RHO5 1.
#define ST_U1 20.
//#define ST_U5 1.e-7
#define ST_U5 (1.e-8/(GAMMA-1.))

double ST_P3;

//#define U2P_NUMTEMP
