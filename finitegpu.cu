extern "C" {

#include "ko.h"

}

#include "kogpu.h"

// persistent arrays, extern'd in kogpu.h
ldouble *d_p_arr, *d_u_arr;
ldouble *d_flbx_arr, *d_flby_arr, *d_flbz_arr;
ldouble *d_emf_arr;

int *d_cellflag_arr, *d_int_slot_arr;

int prealloc_arrays_gpu()
{
  cudaError_t err = cudaSuccess;
 
  long long Nprim  = (SX)*(SY)*(SZ)*NV;
  long long NfluxX = (SX+1)*(SY)*(SZ)*NV;
  long long NfluxY = (SX)*(SY+1)*(SZ)*NV;
  long long NfluxZ = (SX)*(SY)*(SZ+1)*NV;
  long long Nemf = (NX+1)*(NY+1)*(NZ+1)*3;
 
  err = cudaMalloc(&d_p_arr,    sizeof(ldouble)*Nprim);
  err = cudaMalloc(&d_u_arr,    sizeof(ldouble)*Nprim);
  err = cudaMalloc(&d_flbx_arr, sizeof(ldouble)*NfluxX);
  err = cudaMalloc(&d_flby_arr, sizeof(ldouble)*NfluxY);
  err = cudaMalloc(&d_flbz_arr, sizeof(ldouble)*NfluxZ);
  err = cudaMalloc(&d_emf_arr,  sizeof(ldouble)*Nemf);
  
  long long Ncellflag = (SX)*(SY)*(SZ)*NFLAGS;
  err = cudaMalloc(&d_cellflag_arr, sizeof(int)*Ncellflag);
  err = cudaMalloc(&d_int_slot_arr, sizeof(int)*NGLOBALINTSLOT);

  // TODO: add error checks
  return 1;
}

int free_arrays_gpu()
{
  cudaFree(d_p_arr);
  cudaFree(d_u_arr);
  
  cudaFree(d_flbx_arr);
  cudaFree(d_flby_arr);
  cudaFree(d_flbz_arr);
  cudaFree(d_emf_arr);

  cudaFree(d_cellflag_arr);
  cudaFree(d_int_slot_arr);
  
  return 1;
}

int push_pu_gpu()
{
  // TODO: probably don't want to do it this way...

  cudaError_t err = cudaSuccess;
  
  if(doTEST==1) printf("H u: %e \n", get_u(u,ivTEST,ixTEST,iyTEST,izTEST));

  // copy prims, cons from host to device
  long long Nprim  = (SX)*(SY)*(SZ)*NV;
  err = cudaMemcpy(d_u_arr, u, sizeof(ldouble)*Nprim, cudaMemcpyHostToDevice);
  err = cudaMemcpy(d_p_arr, p, sizeof(ldouble)*Nprim, cudaMemcpyHostToDevice);

  // copy fluxes from host to device
  // TODO: in the future, this will be entirely internal to the GPU
  long long NfluxX = (SX+1)*(SY)*(SZ)*NV;
  long long NfluxY = (SX)*(SY+1)*(SZ)*NV;
  long long NfluxZ = (SX)*(SY)*(SZ+1)*NV;  
  err =  cudaMemcpy(d_flbx_arr, flbx, sizeof(ldouble)*NfluxX, cudaMemcpyHostToDevice);
  err =  cudaMemcpy(d_flby_arr, flby, sizeof(ldouble)*NfluxY, cudaMemcpyHostToDevice);
  err =  cudaMemcpy(d_flbz_arr, flbz, sizeof(ldouble)*NfluxZ, cudaMemcpyHostToDevice);

  // TODO: add error checks
  return 1;
}

int pull_pu_gpu()
{
  // TODO: probably only want p, maybe rename
  cudaError_t err = cudaSuccess;

  // copy prims, cons back from device to host 
  long long Nprim  = (SX)*(SY)*(SZ)*NV;
  err = cudaMemcpy(p, d_p_arr, sizeof(ldouble)*Nprim, cudaMemcpyDeviceToHost); 
  err = cudaMemcpy(u, d_u_arr, sizeof(ldouble)*Nprim, cudaMemcpyDeviceToHost); 
  
  return 1;
}

// TODO this is here
void print_double_array_at(FILE *fp, double *array, int ix, int iy, int iz)
{
  int iv = 0;
  fprintf(fp, "[ [%d, %d, %d], [%g", ix, iy, iz, get_u(array, iv, ix, iy, iz));

  for (iv=1; iv<NV; iv++) {
    fprintf(fp, ", %g", get_u(array, iv, ix, iy, iz)); 
  } 

  fprintf(fp, "] ]");
}

int output_state_debug(const char *fname, const char *header, const char *ctimes, const char *gtimes)
{ 
  // writes a diagnostic output file in json format

  FILE *fp = fopen(fname, "w");
  fprintf(fp, "{\n");

  // write header and times
  fprintf(fp, "%s\n", header);
  fprintf(fp, "\"cpu_timing\": %s,\n", ctimes);
  fprintf(fp, "\"gpu_timing\": %s,\n", gtimes);  

  // TODO loop over zones
  fprintf(fp, "\"cpu_prims\":[\n");
  print_double_array_at(fp, p, ixTEST, iyTEST, izTEST);
  fprintf(fp, "\n],\n\"cpu_cons\":[\n");
  print_double_array_at(fp, u, ixTEST, iyTEST, izTEST);
  fprintf(fp, "\n],\n");

  // TODO, make this more modular
  {
  long long Nprim = (SX)*(SY)*(SZ)*NV;
  ldouble* p_tmp, *u_tmp;

  if((p_tmp=(ldouble*)malloc(sizeof(ldouble)*Nprim))==NULL) my_err("malloc err.\n");
  if((u_tmp=(ldouble*)malloc(sizeof(ldouble)*Nprim))==NULL) my_err("malloc err.\n");

  cudaError_t err = cudaSuccess;

  err = cudaMemcpy(p_tmp, d_p_arr, sizeof(ldouble)*Nprim, cudaMemcpyDeviceToHost);
  if(err != cudaSuccess) printf("failed cudaMemcpy of d_p_arr to p_tmp\n");

  err = cudaMemcpy(u_tmp, d_u_arr, sizeof(ldouble)*Nprim, cudaMemcpyDeviceToHost);
  if(err != cudaSuccess) printf("failed cudaMemcpy of d_u_arr to u_tmp\n");

  fprintf(fp, "\"gpu_prims\":[\n");
  print_double_array_at(fp, p_tmp, ixTEST, iyTEST, izTEST);
  fprintf(fp, "\n],\n\"gpu_cons\":[\n");
  print_double_array_at(fp, u_tmp, ixTEST, iyTEST, izTEST);
  fprintf(fp, "\n]\n");

  free(u_tmp);
  free(p_tmp);
  }

  fprintf(fp, "}");
  fclose(fp);

  // TODO error checking...
  return 1;
}

__device__ __host__ int is_cell_active_device(int ix, int iy, int iz)
{
  //NOTE: by default ALWAYS active -- this may change
  return 1;
}


__device__ __host__ int is_cell_corrected_polaraxis_device(int ix, int iy, int iz)
{

#if defined(CORRECT_POLARAXIS) || defined(CORRECT_POLARAXIS_3D)
#ifdef MPI
  if(TJ==0) //tile
#endif
    if(iy<NCCORRECTPOLAR) 
      return 1;
#ifndef HALFTHETA
#ifdef MPI
  if(TJ==NTY-1) //tile
#endif   
    if(iy>(NY-NCCORRECTPOLAR-1))
      return 1;
#endif
#endif
  
  return 0;
}


// TODO replace get_x, get_xb, and get_gKr   everywherex

// get grid coordinate at the cell center indexed ic in dimeinsion idim
// copied from get_x macro in ko.h
__device__ __host__ ldouble get_x_device(ldouble* x_arr, int ic, int idim)
{
  ldouble x_out;
  x_out = (idim==0 ? x_arr[ic+NG] :		     
          (idim==1 ? x_arr[ic+NG + NX+2*NG] :  
	  (idim==2 ? x_arr[ic+NG + NX+2*NG + NY+2*NG ] : 0.)));

  return x_out;
}

// get grid coordinate on the cell wall indexed ic in dimension idim
// copied from get_xb macro in ko.h
__device__ __host__ ldouble get_xb_device(ldouble* xb_arr, int ic, int idim)
{
  ldouble xb_out;
  xb_out = (idim==0 ? xb_arr[ic+NG] :		     
           (idim==1 ? xb_arr[ic+NG + NX+2*NG + 1] :  
	   (idim==2 ? xb_arr[ic+NG + NX+2*NG +1 + NY+2*NG +1 ] : 0.)));

  return xb_out;
}
/*
__device__ __host__ ldouble get_gKr_device(ldouble* gKr_arr, int i,int j, int k,
				  int ix, int iy, int iz)
{
  ldouble gKr_out = gKr_arr[i*4*4+j*4+k + (iX(ix)+(NGCX))*64 + \
				          (iY(iy)+(NGCY))*(SX)*64 + \
			                  (iZMET(iz)+(NGCZMET))*(SY)*(SX)*64];
  return gKr_out;
}
*/
// get size of cell indexed ic in dimension idim
// copied from get_size_x in finite.c
__device__ __host__ ldouble get_size_x_device(ldouble* xb_arr, int ic, int idim)
{
  ldouble dx;
  dx = get_xb_device(xb_arr, ic+1,idim) - get_xb_device(xb_arr, ic, idim);
  return dx;
}


// fill geometry
__device__ __host__ int fill_geometry_device(int ix,int iy,int iz, ldouble* x_arr,void* geom,ldouble* g_arr, ldouble* G_arr)
{

  struct geometry *ggg 
    = (struct geometry *) geom;

  ggg->par=-1;
  ggg->ifacedim = -1;

  //pick_g(ix,iy,iz,ggg->gg);
  //pick_G(ix,iy,iz,ggg->GG);
  for(int i=0;i<4;i++)
  {
    for(int j=0;j<5;j++)
    {
      ggg->gg[i][j]=get_g(g_arr,i,j,ix,iy,iz);
      ggg->GG[i][j]=get_g(G_arr,i,j,ix,iy,iz);
    }
  }

  ggg->alpha=sqrt(-1./ggg->GG[0][0]);
  ggg->ix=ix;  ggg->iy=iy;  ggg->iz=iz;
  ggg->xxvec[0]=0.;
  ggg->xxvec[1]=get_x_device(x_arr, ix,0);
  ggg->xxvec[2]=get_x_device(x_arr, iy,1);
  ggg->xxvec[3]=get_x_device(x_arr, iz,2);
  ggg->xx=ggg->xxvec[1];
  ggg->yy=ggg->xxvec[2];
  ggg->zz=ggg->xxvec[3];
  ggg->gdet=ggg->gg[3][4];
  ggg->gttpert=ggg->GG[3][4];
  ggg->coords=MYCOORDS;
    
  return 0;
  
}


// Metric source term
// TODO: deleted RADIATION and SHEARINGBOX parts
__device__ __host__ int f_metric_source_term_device(int ix, int iy, int iz, ldouble* ss,
		      	                            ldouble* p_arr, ldouble* x_arr,
			                            ldouble* g_arr, ldouble* G_arr, ldouble* gKr_arr)
{

     
  struct geometry geom;
  fill_geometry_device(ix,iy,iz,x_arr,&geom,g_arr,G_arr);

      
  ldouble (*gg)[5],(*GG)[5],gdetu;
  ldouble *pp = &get_u(p_arr,0,ix,iy,iz);
  gg=geom.gg;
  GG=geom.GG;

  #if (GDETIN==0) //no metric determinant inside derivatives
  gdetu=1.;
  #else
  gdetu=geom.gdet;
  #endif
  
  ldouble T[4][4];
  //calculating stress energy tensor components
  calc_Tij_device(pp,&geom,T); 
  indices_2221_device(T,T,gg);

  for(int i=0;i<4;i++)
  {
    for(int j=0;j<4;j++)
    {
	if(isnan(T[i][j])) 
	{
	    printf("%d %d %e\n",i,j,T[i][j]);
	    printf("nan in metric_source_terms\n");
	    //my_err("nan in metric_source_terms\n");//TODO
	}
    }
  }
  
  // zero out all source terms initially
  for(int iv=0;iv<NV;iv++)
    ss[iv]=0.;  

  //terms with Christoffels
  for(int k=0;k<4;k++)
  {
    for(int l=0;l<4;l++)
    {
      ss[1]+=gdetu*T[k][l]*get_gKr(gKr_arr,l,0,k,ix,iy,iz);
      ss[2]+=gdetu*T[k][l]*get_gKr(gKr_arr,l,1,k,ix,iy,iz);
      ss[3]+=gdetu*T[k][l]*get_gKr(gKr_arr,l,2,k,ix,iy,iz);
      ss[4]+=gdetu*T[k][l]*get_gKr(gKr_arr,l,3,k,ix,iy,iz);       
    }
  }


#if (GDETIN==0)
  //gdet derivatives
  ldouble dlgdet[3];
  dlgdet[0]=gg[0][4]; //D[gdet,x1]/gdet
  dlgdet[1]=gg[1][4]; //D[gdet,x2]/gdet
  dlgdet[2]=gg[2][4]; //D[gdet,x3]/gdet

  //get 4-velocity
  ldouble vcon[4],ucon[4];
  vcon[1]=pp[2];
  vcon[2]=pp[3];
  vcon[3]=pp[4];  
  conv_vels_device(vcon,ucon,VELPRIM,VEL4,gg,GG); 

  //terms with dloggdet  
  for(int l=1;l<4;l++)
  {
    ss[0]+=-dlgdet[l-1]*pp[RHO]*ucon[l];
    ss[1]+=-dlgdet[l-1]*(T[l][0]+pp[RHO]*ucon[l]);
    ss[2]+=-dlgdet[l-1]*(T[l][1]);
    ss[3]+=-dlgdet[l-1]*(T[l][2]);
    ss[4]+=-dlgdet[l-1]*(T[l][3]);
    ss[5]+=-dlgdet[l-1]*pp[ENTR]*ucon[l];
  }   
#endif
  
  return 0;
}

//**********************************************************************
// calculate stress energy tensor
//**********************************************************************
__device__ __host__ int calc_Tij_device(ldouble *pp, void* ggg, ldouble T[][4])
{
  struct geometry *geom
    = (struct geometry *) ggg;

  ldouble (*gg)[5],(*GG)[5];
  gg=geom->gg;
  GG=geom->GG;

  ldouble utcon[4],ucon[4],ucov[4];  
  ldouble bcon[4],bcov[4],bsq=0.;
  
  //converts to 4-velocity
  utcon[0]=0.;
  for(int iv=1;iv<4;iv++)
    utcon[iv]=pp[1+iv];
  conv_vels_both_device(utcon,ucon,ucov,VELPRIM,VEL4,gg,GG);

#ifdef NONRELMHD
  ucon[0]=1.;
  ucov[0]=-1.;
#endif

#ifdef MAGNFIELD
  calc_bcon_bcov_bsq_from_4vel_device(pp, ucon, ucov, geom, bcon, bcov, &bsq); 
#else
  bcon[0]=bcon[1]=bcon[2]=bcon[3]=0.;
  bsq=0.;
#endif
  
  ldouble gamma=GAMMA;
  #ifdef CONSISTENTGAMMA
  //gamma=pick_gammagas(geom->ix,geom->iy,geom->iz); //TODO
  #endif
  ldouble gammam1=gamma-1.;

  ldouble rho=pp[RHO];
  ldouble uu=pp[UU];  
  ldouble p=(gamma-1.)*uu; 
  ldouble w=rho+uu+p;
  ldouble eta=w+bsq;
  ldouble ptot=p+0.5*bsq;

#ifndef NONRELMHD  
  for(int i=0;i<4;i++)
    for(int j=0;j<4;j++)
      T[i][j]=eta*ucon[i]*ucon[j] + ptot*GG[i][j] - bcon[i]*bcon[j];
#else
  
  ldouble v2=dot3nr(ucon,ucov); //TODO
  for(int i=1;i<4;i++)
    for(int j=1;j<4;j++)
      T[i][j]=(rho)*ucon[i]*ucon[j] + ptot*GG[i][j] - bcon[i]*bcon[j];

  T[0][0]=uu + bsq/2. + rho*v2/2.;
  for(int i=1;i<4;i++)
    T[0][i]=T[i][0]=(T[0][0] + ptot) *ucon[i]*ucon[0] + ptot*GG[i][0] - bcon[i]*bcon[0];

#endif  // ifndef NONRELMHD

  return 0;
}


//**********************************************************************
// calculate total gas entropy from density & energy density
//**********************************************************************
__device__ __host__ ldouble calc_Sfromu_device(ldouble rho,ldouble u,int ix,int iy,int iz)
{
  ldouble gamma=GAMMA;
  #ifdef CONSISTENTGAMMA
  //gamma=pick_gammagas(ix,iy,iz); //TODO
  #endif
  ldouble gammam1=gamma-1.;
  ldouble indexn=1.0/gammam1;
  ldouble pre=gammam1*u;
  #ifdef NOLOGINS
  ldouble ret = rho*u / pow(rho,gamma);
  #else
  ldouble ret = rho*log(pow(pre,indexn)/pow(rho,indexn+1.));
  #endif

  return ret;
}


//**********************************************************************
// kernels
//**********************************************************************

__global__ void calc_update_kernel(int Nloop_0, 
                                   int* loop_0_ix, int* loop_0_iy, int* loop_0_iz,
		       	           ldouble* x_arr, ldouble* xb_arr,
                                   ldouble* gcov_arr, ldouble* gcon_arr, ldouble* gKr_arr,
				   ldouble* flbx_arr, ldouble* flby_arr, ldouble* flbz_arr,
				   ldouble* u_arr, ldouble* p_arr, ldouble dtin)
{

  int ii;
  int ix,iy,iz;
  ldouble dx,dy,dz;
  ldouble flxl,flxr,flyl,flyr,flzl,flzr;
  ldouble val,du;
  ldouble ms[NV];
  //ldouble gs[NV]; //NOTE gs[NV] is for artifical sources, rarely used

  // get index for this thread
  // Nloop_0 is number of cells to update;
  // usually Nloop_0=NX*NY*NZ, but sometimes there are weird bcs inside domain 
  ii = blockIdx.x * blockDim.x + threadIdx.x;
  if(ii >= Nloop_0) return;
    
  // get indices from 1D arrays
  ix=loop_0_ix[ii];
  iy=loop_0_iy[ii];
  iz=loop_0_iz[ii]; 

  // Source term
#ifdef NOSOURCES
  for(int iv=0;iv<NV;iv++) ms[iv]=0.;
#else
  if(is_cell_active_device(ix,iy,iz)==0) // NOTE: is_cell_active currently always returns 1 
  {
     // Source terms applied only for active cells	  
     for(int iv=0;iv<NV;iv++) ms[iv]=0.; 
  }
  else
  {
     // Get metric source terms ms[iv]
     // and any other source terms gs[iv] 
     f_metric_source_term_device(ix,iy,iz,ms,p_arr, x_arr,gcov_arr,gcon_arr,gKr_arr);
     //f_general_source_term(ix,iy,iz,gs); //NOTE: *very* rarely used, ignore for now
     //for(int iv=0;iv<NV;iv++) ms[iv]+=gs[iv];
  }
#endif


 if(doTEST==1 && ix==ixTEST && iy==iyTEST && iz==izTEST)
   printf("D ms[NV]: %e %e %e %e %e %e %e %e %e\n", ms[0],ms[1],ms[2],ms[3],ms[4],ms[5],ms[6],ms[7],ms[8]);
  
  // Get the cell size in the three directions
  dx = get_size_x_device(xb_arr,ix,0); 
  dy = get_size_x_device(xb_arr,iy,1); 
  dz = get_size_x_device(xb_arr,iz,2); 
  
  //update all conserved according to fluxes and source terms      
  for(int iv=0;iv<NV;iv++)
  {	

    // Get the initial value of the conserved quantity
    val = get_u(u_arr,iv,ix,iy,iz);
    
    if(doTEST==1 && ix==ixTEST && iy==iyTEST && iz==izTEST && iv==ivTEST)
      printf("D u: %e\n", val);
    
    // Get the fluxes on the six faces.
    // flbx, flby, flbz are the fluxes at the LEFT walls of cell ix, iy, iz.
    // To get the RIGHT fluxes, we need flbx(ix+1,iy,iz), etc.
    flxl=get_ub(flbx_arr,iv,ix,iy,iz,0);
    flxr=get_ub(flbx_arr,iv,ix+1,iy,iz,0);
    flyl=get_ub(flby_arr,iv,ix,iy,iz,1);
    flyr=get_ub(flby_arr,iv,ix,iy+1,iz,1);
    flzl=get_ub(flbz_arr,iv,ix,iy,iz,2);
    flzr=get_ub(flbz_arr,iv,ix,iy,iz+1,2);

    // Compute Delta U from the six fluxes
    du = -(flxr-flxl)*dtin/dx - (flyr-flyl)*dtin/dy - (flzr-flzl)*dtin/dz;

    // Compute the new conserved by adding Delta U and the source term
    val += (du + ms[iv]*dtin);

    // Save the new conserved to memory
    
//#ifdef SKIPHDEVOLUTION
//  if(iv>=NVMHD)
//#endif
//#ifdef RADIATION
//#ifdef SKIPRADEVOLUTION
//#ifdef EVOLVEPHOTONNUMBER
//  if(iv!=EE && iv!=FX && iv!=FY && iv!=FZ && iv!=NF)
//#else
//  if(iv!=EE && iv!=FX && iv!=FY && iv!=FZ)
//#endif
//#endif  
//#endif  
//#ifdef SKIPHDBUTENERGY
//  if(iv>=NVMHD || iv==UU)
//#endif
	
    set_u(u_arr,iv,ix,iy,iz,val);	 

  }  
}

ldouble calc_update_gpu(ldouble dtin)
{
  cudaError_t err = cudaSuccess;
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  // Launch calc_update_kernel

  int threadblocks = (Nloop_0 / TB_SIZE) + ((Nloop_0 % TB_SIZE)? 1:0);
  //printf("\nTest %d\n", threadblocks); fflush(stdout);

  cudaEventRecord(start);
  calc_update_kernel<<<threadblocks, TB_SIZE>>>(Nloop_0, 
						d_loop0_ix, d_loop0_iy, d_loop0_iz,
						d_x, d_xb,d_gcov, d_gcon, d_Kris,
						d_flbx_arr, d_flby_arr, d_flbz_arr,
						d_u_arr, d_p_arr, dtin);
  
  cudaEventRecord(stop);
  err = cudaPeekAtLastError();
  // printf("ERROR-Kernel (error code %s)!\n", cudaGetErrorString(err));

  // synchronize
  cudaDeviceSynchronize();
  
  // timing information
  cudaEventSynchronize(stop);
  float tms = 0.;
  cudaEventElapsedTime(&tms, start,stop);
  printf("gpu update time: %0.2f \n",tms);
 
#ifdef CPUKO 
  ldouble* u_tmp;
  long long Nprim  = (SX)*(SY)*(SZ)*NV;
  if((u_tmp=(ldouble*)malloc(Nprim*sizeof(ldouble)))==NULL) my_err("malloc err.\n");
  err = cudaMemcpy(u_tmp, d_u_arr, Nprim*sizeof(ldouble), cudaMemcpyDeviceToHost);
  if(err != cudaSuccess) printf("failed cudaMemcpy of d_p_arr to p_tmp\n");
  printf("gpu update uu[NV]: ");
  for(int iv=0;iv<NV;iv++)
    printf("%e ", get_u(u_tmp, iv, ixTEST, iyTEST, izTEST));
  printf("\n");
  free(u_tmp);
#endif

  // set global timestep dt
  dt = dtin;

  return (ldouble)tms;
}

