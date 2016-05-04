!=======================================================================
!> @file parameters.f90
!> @brief parameters module
!> @author C. Villarreal, M. Schneiter, A. Esquivel
!> @date 4/May/2016

! Copyright (c) 2016 Guacho Co-Op
!
! This file is part of Guacho-3D.
!
! Guacho-3D is free software; you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation; either version 3 of the License, or
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
! GNU General Public License for more details.
!
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see http://www.gnu.org/licenses/.
!=======================================================================

!> @brief Parameters module
!> @details This module contains parameters of the run, some of this
!! can be moved later to a runtime input file

module parameters
  use constants
  implicit none
#ifdef MPIP
  include "mpif.h"
  logical, parameter :: mpip     = .true.   !<  enable mpi parallelization
#endif

  !> Path used to write the output
  character (len=128),parameter ::  outputpath='./EXO/'
  !> working directory
  character (len=128),parameter ::  workdir='./'

  !----------------------------------------
  !  setup parameters
  !  If logical use true or false
  !  If integer, choose from list provided
  !----------------------------------------
  
  logical, parameter :: pmhd     = .false.  !<  enadble passive mhd
  logical, parameter :: mhd      = .true.   !<  Enable full MHD
  
  !> Approximate Riemman Solver
  !> SOLVER_HLL  : HLL solver (HD most diffusive)
  !> SOLVER_HLLC : HLLC solver 
  !> SOLVER_HLLE : HLLE solver (too diffusive)
  !> SOLVER_HLLD : HLLD solver
  !> SOLVER_HLLE_SPLIT : Split version of HLLE
  !> SOLVER_HLLD_SPLIT : Split version of HLLD
  integer, parameter :: riemann_solver = SOLVER_HLLD

  !>  Include terms proportional to DIV B (powell et al. 1999)
  logical, parameter :: eight_wave = .false.
  !>  Enable field-CD cleaning of div B
  logical, parameter :: enable_field_cd = .true.
  !>  Enable writting of divB to disk
  logical, parameter :: dump_divb = .true.

  !  Type of output (silo has to be set in Makefile)
  logical, parameter :: out_bin  = .true.   !< binary i/o (needed for warmstart)
  logical, parameter :: out_vtk  = .false.  !< vtk (also binary)

  !> Equation of state used to compute T and P
  !> EOS_ADIABATIC     : Does not modify P, and T=(P/rho)*Tempsc
  !> EOS_SINGLE_SPECIE : Uses only n (e.g. to use with tabulated cooling curves)
  !> EOS_H_RATE        : Using n_HI and n_HII
  !> CHEM              : Enables a full chemical network
  integer, parameter :: eq_of_state = EOS_H_RATE

  !> Type of cooling (choose only one)
  !> COOL_NONE: Turns off the cooling
  !> COOL_H    : Single parametrized cooling function (ionization frac and T)
  !> COOL_BBC  : Cooling function of Benjamin, Benson and Cox (2003)
  !> COOL_DMC  : coronal eq. (tabulated) from Dalgarno & Mc Cray (1972)
  !> COOL_CHI  : From table(s) generated with Chianti
  !> COOL_CHEM : enables cooling from a full chemical network
  integer, parameter :: cooling = COOL_H

  !> Boundary conditions
  !> BC_OUTFLOW   : Outflow boundary conditions (free flow)
  !> BC_CLOSED    : Closed BCs, (aka reflective)
  !> BC_PERIODIC  : Periodic BCs
  !> BC_OTHER     : Left to the user to set boundary (via user_mod)
  !! Also in user mod the boundaries for sources (e.g. winds/outflows)
  !! are set
  integer, parameter :: bc_left   = BC_outflow
  integer, parameter :: bc_right  = BC_outflow
  integer, parameter :: bc_bottom = BC_outflow
  integer, parameter :: bc_top    = BC_outflow
  integer, parameter :: bc_out    = BC_outflow
  integer, parameter :: bc_in     = BC_outflow
  logical, parameter :: bc_user   = .true. !< user boundaries (e.g. sources)

  !>  Slope limiters
  !>  LIMITER_NO_AVERAGE = Performs no average (1st order in space)
  !>  LIMITER_NO_LIMIT   = Does not limit the slope (unstable)
  !>  LIMITER_MINMOD     = Minmod (most diffusive) limiter
  !>  LIMITER_VAN_LEER   = Van Ler limiter
  !>  LIMITER_VAN_ALBADA = Van Albada limiter
  !>  LIMITER_UMIST      = UMIST limiter
  !>  LIMITER_WOODWARD   = Woodward limiter
  !>  LIMITER_SUPERBEE   = Superbee limiter
  integer, parameter :: slope_limiter = LIMITER_MINMOD

  !>  Thermal conduction
  !> TC_OFF         : No thermal conduction
  !> TC_ISOTROPIC   : Isotropic thermal conduction
  !> TC_ANISOTROPIC : Anisotropic thermal conduction (requires B field)
  integer, parameter :: th_cond = TC_OFF
  !> Enable Saturation in thermal conduction
  logical, parameter :: tc_saturation = .false.

  !> Enable 'diffuse' radiation
  logical, parameter :: dif_rad = .false.

  !> Include user defined source terms (e.g. gravity, has to be set in usr_mod)
  logical, parameter :: user_source_terms = .true.

  !> Include radiative pressure
  logical, parameter :: radiation_pressure = .false.

  
#ifdef PASSIVES
  integer, parameter :: npas=2        !< num. of passive scalars
#else
  integer, parameter :: npas=0        !< num. of passive scalars
#endif

  integer, parameter :: nxtot=400      !< Total grid size in X
  integer, parameter :: nytot=100      !< Total grid size in Y
  integer, parameter :: nztot=400      !< Total grid size in Z

#ifdef MPIP
  !   mpi array of processors
  integer, parameter :: MPI_NBX=4     !< number of MPI blocks in X
  integer, parameter :: MPI_NBY=2     !< number of MPI blocks in Y
  integer, parameter :: MPI_NBZ=2     !< number of MPI blocks in Z   
  !> total number of MPI processes
  integer, parameter :: np=MPI_NBX*MPI_NBY*MPI_NBZ
#endif

  !  set box size   
  real, parameter :: xmax=1.          !< grid extent in X (code units)
  real, parameter :: ymax=0.25        !< grid extent in Y (code units)
  real, parameter :: zmax=1.          !< grid extent in Z (code units)
  real, parameter :: xphys=0.3*au     !< grid extent in X (physical units, cgs)

  !  For the equation of state
  real, parameter :: cv=1.5            !< Specific heat at constant volume (/R)
  real, parameter :: gamma=(cv+1.)/cv  !< Cp/Cv
  real, parameter :: mu = 1.           !< mean atomic mass
  
  !  scaling factors to physical (cgs) units
  real, parameter :: T0=1.e4                !<  reference temperature (for cs)
  real, parameter :: rsc=xphys/xmax         !<  distance scaling
  real, parameter :: rhosc= amh*mu          !<  mass density scaling
  real, parameter :: Tempsc=T0*gamma        !<  Temperature scaling
  real, parameter :: vsc2 = gamma*Rg*T0/mu  !<  Velocity scaling squared
  real, parameter :: vsc = sqrt(vsc2)       !<  Velocity scaling
  real, parameter :: Psc = rhosc*vsc2       !<  Pressure scaling
  real, parameter :: tsc =rsc/sqrt(vsc2)    !<  time scaling
  real, parameter :: bsc = sqrt(4.0*pi*Psc) !< magnetic field scaling

  !> Maximum integration time
  real, parameter :: tmax    = 5.*day/tsc
  !> interval between consecutive outputs
  real, parameter :: dtprint = 0.025 *day/tsc
  real, parameter :: cfl=0.4        !< Courant-Friedrichs-Lewy number
  real, parameter :: eta=0.01       !< artificial viscosity

  !> Warm start flag, if true restarts the code from previous output
  logical, parameter :: iwarm=.false.
  integer            :: itprint0=141  !< number of output to do warm start


  !*********************************************************************
  !  some derived parameters (no need of user's input below this line)
  !*********************************************************************

#ifdef PASSIVES
  logical, parameter :: passives = .true.   !<  enable passive scalars
#else
  logical, parameter :: passives = .false.  !<  enable passive scalars
#endif
 integer, parameter :: ndim=3         !< num. of dimensions
  integer, parameter :: nghost=2      !< num. of ghost cells

  !> number of dynamical equations
#ifdef BFIELD
  integer, parameter :: neqdyn=8      !< num. of eqs  (+scal)
#else
  integer, parameter :: neqdyn=5      !< num. of eqs  (+scal)
#endif

  integer, parameter :: neq=neqdyn + npas  !< number of equations

#ifdef SILO
  logical, parameter :: out_silo = .true.  !< silo (needs hdf/silo libraries)
#else
  logical, parameter :: out_silo = .false.  !< silo (needs hdf/silo libraries)
#endif

#ifdef MPIP
  !>  number of physical cells in x in each MPI block
  integer, parameter :: nx=nxtot/MPI_NBX
  !>  number of physical cells in y in each MPI block
  integer, parameter :: ny=nytot/MPI_NBY
  !>  number of physical cells in z in each MPI block
  integer, parameter :: nz=nztot/MPI_NBZ
#else
  integer, parameter :: nx=nxtot, ny=nytot, nz=nztot
  integer, parameter :: np=1, MPI_NBY=1, MPI_NBX=1, MPI_NBZ=1
#endif
!
  integer, parameter :: nxmin = 1  - nghost  !< lower bound of hydro arrays in x
  integer, parameter :: nxmax = nx + nghost  !< upper bound of hydro arrays in x
  integer, parameter :: nymin = 1  - nghost  !< lower bound of hydro arrays in y
  integer, parameter :: nymax = ny + nghost  !< upper bound of hydro arrays in y
  integer, parameter :: nzmin = 1  - nghost  !< lower bound of hydro arrays in z
  integer, parameter :: nzmax = nz + nghost  !< upper bound of hydro arrays in z
  
  !  more mpi stuff
  integer, parameter ::master=0  !<  rank of master of MPI processes
  
  !   set floating point precision (kind) for MPI messages
#ifdef MPIP
#ifdef DOUBLEP
  integer, parameter :: mpi_real_kind=mpi_real8  !< MPI double precision
#else
  integer, parameter :: mpi_real_kind=mpi_real4  !< MPI single precision
#endif
#endif

end module parameters

!=======================================================================

