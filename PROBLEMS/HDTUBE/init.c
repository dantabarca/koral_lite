
/*
int
set_initial_profile()
{
  int ix,iy,iz;
  for(iz=0;iz<NZ;iz++)
    {
      for(iy=0;iy<NY;iy++)
	{
	  for(ix=0;ix<NX;ix++)
	    {
*/
/***********************************************/
struct geometry geom;
fill_geometry(ix,iy,iz,&geom);

	      ldouble rho,mx,my,mz,m,E,uint,E0,Fx,Fy,Fz,pLTE;  
	      ldouble xx,yy,zz;
	      ldouble uu[NV];

	      xx=get_x(ix,0);
	      yy=get_x(iy,1);
	      zz=get_x(iz,2);
	      ldouble gg[4][5],GG[4][5],eup[4][4],elo[4][4];
	      pick_g(ix,iy,iz,gg);
	      pick_G(ix,iy,iz,GG);

	      ldouble pp[NV],T;

/************************/

	      //	      if(xx<(MAXX+MINX)/2.)
	      if(xx<0.)
		{
		  rho=ST_RHO1;
		  uint=ST_U1;
		}
	      else
		{
		  rho=ST_RHO5;
		  uint=ST_U5;
		}		  
	      mx=my=mz=0.;
	      pp[0]=rho;
	      pp[1]=uint;
	      pp[2]=mx;
	      pp[3]=my;
	      pp[4]=mz;

//converting from 3vel to relative velocity
conv_velsinprims(pp,VEL3,VELPRIM,gg,GG);

p2u(pp,uu,&geom);	 

//print_Nvector(pp,NV);
//print_Nvector(uu,NV);getchar();


/***********************************************/

	      int iv;

	      for(iv=0;iv<NV;iv++)
		{
		  set_u(u,iv,ix,iy,iz,uu[iv]);
		  set_u(p,iv,ix,iy,iz,pp[iv]);
		}

	      //entropy
	      update_entropy(ix,iy,iz,0);

	      //if(isnan(get_u(p,5,ix,iy,iz))) {printf("pr: %d %d %d S: %Le\n",ix,iy,iz,0.);getchar();}

	      //mark initialy succesfull u2p_hot step
	      set_cflag(0,ix,iy,iz,0);
