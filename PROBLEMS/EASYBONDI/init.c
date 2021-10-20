
struct geometry geom;
fill_geometry(ix, iy, iz, &geom);

struct geometry geomBL;
fill_geometry_arb(ix, iy, iz, &geomBL, BLCOORDS);

ldouble r, rho, rhocgs, uint;
ldouble pp[NV], uu[NV];

//radius in BL coordinates
r = geomBL.xx;

rhocgs = pow(RMAX/r,2)*RHOMAX;
rho = rhoCGS2GU(rhocgs);
uint = calc_PEQ_ufromTrho(TEMP, rho, ix, iy, iz); 


pp[RHO] = rho;
pp[UU] = uint;

//velocities
ldouble ucon3[4] = {0., 0., 0., 0.};
ldouble ucon4[4];
//convert from 3 vector to 4-vector
conv_vels(ucon3, ucon4, VEL3, VEL4, geomBL.gg, geomBL.GG);
ldouble ucon4_cc[4];
//convert from BLCOORDS to code coordinates
trans2_coco(geomBL.xxvec, ucon4, ucon4_cc, BLCOORDS, MYCOORDS);
if(r<2.) calc_normalobs_4vel(geom.GG, ucon4_cc);
ldouble ucon_prim[4];
//convert to primative velocities
conv_vels(ucon4_cc, ucon_prim, VEL4, VELPRIM, geom.gg, geom.GG);
//set the primitive velocities
pp[VX] = ucon_prim[1];
pp[VY] = ucon_prim[2];
pp[VZ] = ucon_prim[3];

//geom.gg = g_{\mu\nu}, geom.GG = g^{\mu\nu}

// convert from pimitives to conserved
p2u(pp,uu,&geom);	 

//print_Nvector(pp,NV);
//print_Nvector(uu,NV);getchar();


/***********************************************/

	      int iv;

	      for(iv=0;iv<NV;iv++)
		{
         //set the primitives and converved in memory
		  set_u(u,iv,ix,iy,iz,uu[iv]);
		  set_u(p,iv,ix,iy,iz,pp[iv]);
		}

	      //entropy
	      update_entropy(ix,iy,iz,0);

	      //if(isnan(get_u(p,5,ix,iy,iz))) {printf("pr: %d %d %d S: %Le\n",ix,iy,iz,0.);getchar();}

	      //mark initialy succesfull u2p_hot step
	      set_cflag(0,ix,iy,iz,0);
