!=======================================================================
!> @file user_mod.f90
!> @brief User input module
!> @author Alejandro Esquivel
!> @date 2/Nov/2014

! Copyright (c) 2014 A. Esquivel, M. Schneiter, C. Villareal D'Angelo
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

!> @brief User imput module
!> @details  This is an attempt to have all input neede from user in a
!! single file
!!!  This module should load additional modules (i.e. star, corona, sn), to
!!  impose initial and boundary conditions (such as sources)

module user_mod

  ! load auxiliary modules
  use corona   ! Note that parameters is included here
  implicit none
  real :: equi(neq,nymin:nymax)
  public :: integral
contains

!> @brief Initializes variables in the module, as well as other
!! modules loaded by user.
!! @n It has to be present, even if empty 
subroutine init_user_mod()

  implicit none      
  !  if needed initialize modules loaded by user
  call init_corona()

end subroutine init_user_mod

!=====================================================================

!> @brief Here the domain is initialized at t=0
!> @param real [out] u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax) : 
!! conserved variables
!> @param real [in] time : time in the simulation (code units)

subroutine initial_conditions(u)

  use parameters, only : neq, nxmin, nxmax, nymin, nymax, nzmin, &
                        nzmax, cv, rsc, vsc2, rhosc, Tempsc, ny, &
                        gamma, mu, mu_1, mu_2

  use globals, only : coords, dy, primit0
  use constants, only : Ggrav, Msun, Rsun, pi, Rg
  implicit none
  real, intent(out) :: u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax) 
  real :: g
  real :: y , P_y, c1, c2, c
  integer :: i, j, k, jj
  real :: Temp1, Temp2
  !  real :: integral, Temp1, Temp2
  g = Ggrav*Msun/Rsun/Rsun
  nc = 1.e20
  Temp1 = 1.e4 
  P_0 = nc*kb*Temp1
  Temp2 = 1.e6
  c  = mu * g/Rg
  c1 = mu_1*g/Rg
  c2 = mu_2*g/Rg

! UNPERTURBED VARIABLES
  primit0(:,:,:,:)=0.
  
!  integral = c1 * dy*rsc*coords(1)
!  integral = 0.
  
  do j = nymin,nymax
     jj = j +coords(1)
     y = (float(j+coords(1)*ny) + 0.5)*dy*rsc
!     do coords(1)=0,np-1
!        integral = integral + mu*g*dy/Rg/Temp
!     end do
     P_y = P_0*exp(-integral(jj,Temp1,Temp2,mu_1, mu_2))
!!$     if(rank.eq.master)then
!!$        print*,j,'P_y',P_y,integral(jj,Temp1,Temp2,mu_1, mu_2)
!!$     end if
     equi(5,j)  = P_y/Psc       
     equi(2,j)  = 0.      
     equi(3,j)  = 0.
     equi(4,j)  = 0.
     if(y.le.2.e8)then
        equi(1,j)  = (mu_1*P_y/Rg/Temp1)/rhosc
     else
        equi(1,j)  = (mu_1*P_y/Rg/Temp2)/rhosc
     end if
     equi(6,j)  = 0.
     equi(7,j)  = 1./Bsc
     equi(8,j)  = 0.

     do k =nzmin, nzmax
        do i = nxmin, nxmax
           primit0(:,i,j,k) = equi(:,j)
        end do
     end do
  end do
  u = 0.
 

end subroutine initial_conditions

real function integral(jj,Temp1,Temp2,mu_1, mu_2)
  use globals, only:dy
  implicit none
  integer, intent(in) :: jj 
  real,intent(in) ::Temp1, Temp2,mu_1,mu_2
  integer :: ii
  real :: y, g
  
  g = Ggrav*Msun/Rsun/Rsun
  integral=0.
  do ii=0,jj
     y = (float(ii)+0.5)*dy*rsc
     if(y.le.2.E8) then
        integral = integral + dy*rsc*mu_1*g/Rg/Temp1  
     else 
        integral = integral + dy*rsc*mu_2*g/Rg/Temp2  
     endif
  !   print*,jj,integral
  end do
!stop
end function integral
  
!=====================================================================

!> @brief User Defined Boundary conditions
!> @param real [out] u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax) : 
!! conserved variables
!> @param real [in] time : time in the simulation (code units)
!> @param integer [in] order : order (mum of cells to be filled in case
!> domain boundaries are being set, valid values are 1 or 2)

subroutine impose_user_bc(u,order)

  use parameters, only : neq, nxmin, nxmax, nymin, nymax, nzmin, nzmax, &
                         bc_user, nx, ny, nz, tsc
  use globals   , only : time 
  implicit none
  real :: u(neq,nxmin:nxmax,nymin:nymax,nzmin:nzmax)
  integer, intent(in) :: order
  integer :: i, k, ieq
  real    :: time_sec

  time_sec = time*tsc  

  !  In this case the boundary is the same for 1st and second order)
  
  if (order == 1) then 
     !  BC in X
!!$     do k=0, nz+1
!!$        do j=0, ny+1
!!$           do ieq = 1, neq
!!$              u(ieq,   0,j,k) = equi(ieq,j)
!!$              u(ieq,nx+1,j,k) = equi(ieq,j)
!!$           end do
!!$        end do
!!$     end do
     !  BC in Y
     do k=0, nz+1
        do i=0, nx+1
           do ieq = 1, neq
              u(ieq,i,0   ,k) = 0.!equi(ieq,0   )
              u(ieq,i,ny+1,k) = 0.!equi(ieq,ny+1)
           end do
        end do
     end do
!!     !  BC in Z
!!     do j=0, ny+1
!!        do i=0, nx+1
!!           do ieq = 1, neq
!!              u(ieq,i,j,0  ) =  equi(ieq,j)
!!              u(ieq,i,j,nz+1) = equi(ieq,j)
!!           end do
!!        end do
!!     end do
  else if (order == 2) then
          !  BC in X
!     do k=nzmin, nzmax
!        do j=nymin, nymax
!           do ieq = 1, neq
!              u(ieq,   -1,j,k) = equi(ieq,j)
!              u(ieq,    0,j,k) = equi(ieq,j)
!              u(ieq, nx+1,j,k) = equi(ieq,j)
!              u(ieq, nx+2,j,k) = equi(ieq,j)
!           end do
!        end do
!     end do
     !  BC in Y
     do k=nzmin, nzmax
        do i=nxmin, nxmax
           do ieq = 1, neq
              u(ieq,i,  -1,k) = 0.! equi(ieq,-1  )
              u(ieq,i,   0,k) = 0.! equi(ieq,0   )
              u(ieq,i,ny+1,k) = 0.! equi(ieq,ny+1)
              u(ieq,i,ny+2,k) = 0.! equi(ieq,ny+2)
           end do
        end do
     end do
     !  BC in Z
!!$     do j=nymin, nymax
!!$        do i=nxmin, nxmax
!!$           do ieq = 1, neq
!!$              u(ieq,i,j,-1  ) =  equi(ieq,j)
!!$              u(ieq,i,j,0   ) =  equi(ieq,j)
!!$              u(ieq,i,j,nz+1) =  equi(ieq,j)
!!$              u(ieq,i,j,nz+2) =  equi(ieq,j)
!!$           end do
!!$        end do
!!$     end do
     end if
  
end subroutine impose_user_bc

!=======================================================================

!> @brief User Defined source terms
!> This is a generic interrface to add a source term S in the equation
!> of the form:  dU/dt+dF/dx+dG/dy+dH/dz=S
!> @param real [in] pp(neq) : vector of primitive variables
!> @param real [inout] s(neq) : vector with source terms, has to add to
!>  whatever is there, as other modules can add their own sources
!> @param integer [in] iin : cell index in the X direction
!> @param integer [in] jin : cell index in the Y direction
!> @param integer [in] kin : cell index in the Z direction

subroutine get_user_source_terms(pp,s, iin, jin , kin)

  ! in this example a constant gravity is added
  use constants,  only : Ggrav,Msun,Rsun
  use parameters, only : neq, nymin, nymax, rsc, vsc
  implicit none
  integer, intent(in), optional    :: iin, jin, kin
  integer  :: i,j,k
  real, intent(in)    :: pp(neq)
  real, intent(inout) :: s(neq)
  real :: g

  if (present(iin)) i=iin
  if (present(jin)) j=jin
  if (present(kin)) k=kin

  g = Ggrav*Msun/Rsun/Rsun
  g = g*rsc/vsc2

  ! momento
  s(2)= s(2)
  s(4)= s(4)
  s(3)= s(3)-pp(1)*g!GM/((R)**2.)
  ! energy
  s(5)= s(5)-pp(1)*pp(3)*g!GM/((R)**2. )

end subroutine get_user_source_terms
!=====================================================================

end module user_mod



!=======================================================================
