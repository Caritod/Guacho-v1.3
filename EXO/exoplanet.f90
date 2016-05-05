!=======================================================================
!> @file exoplanet.f90
!> @brief Exoplanet problem module
!> @author M. Schneiter, C. Villarreal  D'Angelo, A. Esquivel
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
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see http://www.gnu.org/licenses/.
!=======================================================================

!> @brief Exoplanet module
!> @details Problem Module for exoplanet

module exoplanet

  use parameters
  implicit none
  real :: RSW     !< Stellar wind radius
  real :: TSW     !< Stellar wind temperature
  real :: VSW     !< Stellar wind velocity
  real :: dsw     !< Stellar Wind Density
  real :: RsS
  real :: bsw     !< Magnetic Field
  real :: bpw     !< Planetary Magnetic Field  
  real :: RPW     !< Planetary radius
  real :: TPW     !< Planetary wind temperature
  real :: VPW     !< Planetary wind velocity
  real :: dpw     ! Planetary wind density
  real :: torb    !< planet: orbital period 
  real :: rorb    !<  orbital radius 
  real :: omegap  !< planet: angular velocity 
  real :: MassS   !< Mass of the Star
  real :: MassP   !< Mass of the Planet
  real :: xp      !< X position of the planet
  real :: yp      !< Y position of the planet
  real :: zp      !< Z position of the planet

contains

!=======================================================================

!> @brief Module initialization
!> @details Here the parameters of the Star are initialized, and scaled 
!! to code units

subroutine init_exo()
  
  use constants, only : Msun, Yr, Ggrav, pi, mjup, au, day,Rjup, rsun

  implicit none
  real :: amdot  ! mdot_star (MSUN/yr)
  real :: ampdot ! mdot_planet (g/s)

  !----------------STAR PARAMETERS ------------------
  MassS = 1.1*msun
  RsS   = 1.2*rsun
  AMDOT = 2.E-14*msun/yr              ! Stellar Mass Loss rate (g s^-1)
  TSW   = 1.56E6     !*************   ! Stellar temperature (K)
  !  Stellar wind, imposed at the 1.5x  sonic point (cm)
  RSW   = 1.2*rsun   !*************
  vsw   = 1.e5       !*************      ! Stellar wind velocity (cm/s)
  dsw   = ((AMDOT/RSW)/(4*pi*RSW*VSW))   ! Stellar density @RS (g cm^-3)
  bsw   = 1.0                            ! Stellar magnetic field (g)

  !----------------PLANET PARAMETERS------------------
  MassP = 0.67*mjup
  AMPDOT= 1.E10   !***********         ! Planetary Mass Loss rate (g/s)
  TPW   = 1E4                          ! Planets temperature
  RPW   = 3.*1.38*Rjup                 ! Planetary wind radius (cm) 
  vpw   = 10.e5                        ! Planets wind velocity (cm/s)
  dpw=((AMPDOT/RPW)/(4*pi*RPW*VPW))    ! Planetary wind density
  bpw   = 0.04                         ! Planetary magnetic field (g)

  !ORBITAL PARAMETERS
  rorb=.047*AU!0.47**AU
  torb=3.52*day

  ! change to code units
  dsw=dsw/rhosc
  vsw=vsw/sqrt(vsc2)
  Tsw=Tsw/Tempsc
  Rsw=Rsw/rsc
  RsS=RsS/rsc
  bsw=bsw/bsc 
  bpw=bpw/bsc
  dpw=dpw/rhosc
  vpw=vpw/sqrt(vsc2)
  Tpw=Tpw/Tempsc
  Rpw=Rpw/rsc
  rorb=rorb/rsc 
  torb=torb/tsc

  omegap=2.*pi/torb        !tidally locked planet
  
  
  !  initial position
  xp=Rorb*cos(-25.*pi/180.)
  yp=0.
  zp=Rorb*sin(-25.*pi/180.)

end subroutine init_exo

!=======================================================================

!> @brief Inject sources of wind
!> @details Imposes the sources of wond from the star and planet
!> @param real [out] u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax) :
!! conserver variables
!> @param real [time] time : current integration timr
  !--------------------------------------------------------------------

subroutine impose_exo(u,time)
  
  use constants, only : pi
  use globals, only : coords, dx, dy, dz
  implicit none
  real, intent(out) :: u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax)
  real, intent (in) :: time
  real :: x, y, z, xpl, ypl, zpl
  real :: velx, vely, velz, rads, dens, radp, phi
  real :: vxorb, vyorb, vzorb
#ifdef BFIELD
  real :: cpi
#endif
  integer ::  i,j,k

  phi=-25.*pi/180.


  XP=Rorb*COS(omegap*TIME+phi)
  ZP=Rorb*SIN(omegap*TIME+phi)

  !Orbital planetary velocity (moves in the xz-plane)
  vxorb=-omegap*Rorb*sin(omegap*TIME+phi)
  vzorb= omegap*Rorb*cos(omegap*TIME+phi)
  vyorb=0.

  do i=nxmin,nxmax
    do j=nymin,nymax
      do k=nzmin,nzmax

        ! Position measured from the centre of the grid (star)
        x=(float(i+coords(0)*nx-nxtot/2)+0.5)*dx
        y=(float(j+coords(1)*ny-nytot/2)+0.5)*dy
        z=(float(k+coords(2)*nz-nztot/2)+0.5)*dz

        ! Position measured from the centre of the planet
        xpl=x-xp
        ypl=y
        zpl=z-zp

        ! Distance from the centre of the star
        rads=sqrt(x**2+y**2+z**2)

        ! Distance from the centre of the planet
        radp=sqrt(xpl**2+ypl**2+zpl**2)         

        ! IF INSIDE THE STAR
        if( rads <= rsw) then
          if(rads == 0.) rads=dx*0.10

          VelX=VSW*X/RADS
          VelY=VSW*Y/RADS
          VelZ=VSW*Z/RADS
          DENS=DSW!*RSW**2/RADS**2
          !   total density and momena
          u(1,i,j,k) = dens
          u(2,i,j,k) = dens*velx
          u(3,i,j,k) = dens*vely
          u(4,i,j,k) = dens*velz
          !   magnetic field

          if (pmhd .or. mhd) then
#ifdef BFIELD
            cpi = bsw*(RSW/rads)**3/(2.*rads**2)
            u(6,i,j,k) = 3.*y*x*cpi
            u(7,i,j,k) = (3.*y**2-rads**2)*cpi
            u(8,i,j,k) = 3.*y*z*cpi
#endif
          end if

          if (mhd) then
#ifdef BFIELD
            ! total energy
            u(5,i,j,k)=0.5*dens*(velx**2+vely**2+velz**2)        &
            + cv*dens*Tsw       & 
            + 0.5*(u(6,i,j,k)**2+u(7,i,j,k)**2+u(8,i,j,k)**2)
#endif
          else
            ! total energy
            u(5,i,j,k)=0.5*dens*(velx**2+vely**2+velz**2) &
            + cv*dens*1.9999*Tsw
          endif

          if (passives) then
#ifdef PASSIVES
            !  density of neutrals
            u(neqdyn+1,i,j,k)= 0.0001*dens
            !   passive scalar (h-hot, c-cold, i-ionized, n-neutral)
            u(neqdyn+2,i,j,k)= dens   ! passive scalar
#endif
          end if


        ! IF INSIDE THE PLANET
        else if(radp <= rpw) then

          if(radp == 0.) radp=dx*0.10
          
          VelX=VXORB+VPW*XPL/RADP
          VelY=VYORB+VPW*YPL/RADP
          VelZ=VZORB+VPW*ZPL/RADP
          DENS=DPW!*RPW**2/RADP**2
          !   total density and momenta
          u(1,i,j,k) = dens
          u(2,i,j,k) = dens*velx
          u(3,i,j,k) = dens*vely
          u(4,i,j,k) = dens*velz
          !  Magnetic fields (IF MHD or PMHD)
#ifdef BFIELD
          cpi = bpw*(rpw/radp)**3/(2.*radp**2)
          u(6,i,j,k) = 3.*ypl*xpl*cpi
          u(7,i,j,k) = (3.*ypl**2-radp**2)*cpi
          u(8,i,j,k) = 3.*ypl*zpl*cpi
#endif
          !   energy
         if (mhd) then
#ifdef BFIELD
          u(5,i,j,k)=0.5*dens*(velx**2+vely**2+velz**2) &
               + cv*dens*1.8*Tpw                    & 
               + 0.5*(u(6,i,j,k)**2+u(7,i,j,k)**2+u(8,i,j,k)**2)
#endif
        else
          u(5,i,j,k)=0.5*dens*(velx**2+vely**2+velz**2) &
               + cv*dens*1.8*Tpw
        end if

        if (passives) then
#ifdef PASSIVES
          !  density of neutrals
          u(neqdyn+1,i,j,k)=0.2*dens                
          !   passive scalar (h-hot, c-cold, i-ionized, n-neutral)
          u(neqdyn+2,i,j,k)= -dens   ! passive scalar
        endif
#endif

        end if

      end do
    end do
  end do

end subroutine impose_exo

!=======================================================================

end module exoplanet

!=======================================================================
