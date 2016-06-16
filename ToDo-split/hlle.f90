!=======================================================================
!> @file hlle.f90
!> @brief HLLE approximate Riemann solver module
!> @author C. Villarreal  D'Angelo, A. Esquivel, M. Schneiter
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

!> @brief HLLE approximate Riemann solver module
!! @details The module contains the routines needed to Solve the Riemann
!! problem in the entire domain and return the physical fluxes in x,y,z
!! with the HLLE solver

module hlle

#ifdef HLLE

contains

!=======================================================================
#ifndef MHD_BSPLIT
!> @brief Solves the Riemann problem at the interface PL,PR
!! using the HLLE solver
!> @details Solves the Riemann problem at the interface betweem 
!! PL and PR using the HLLE solver
!> @n The fluxes are computed in the X direction, to obtain the
!! y ans z directions a swap is performed
!> @param real [in] primL : primitives at the Left state
!> @param real [in] primR : primitives at the Right state
!> @param real [out] ff : fluxes at the interface (@f$ F_{i+1/2} @f$)

subroutine prim2fhlle(priml,primr,ff)

  use parameters, only : neq
  use hydro_core, only : cfastX, prim2f, prim2u
  implicit none
  real, dimension(neq),intent(in   ) :: priml, primr
  real, dimension(neq),intent(inout) :: ff
  real, dimension(neq)               :: uR, uL, fL, fR
  real :: csl, csr, sl, sr

  call cfastX(priml,csl)
  call cfastX(primr,csr)

  sr=max(priml(2)+csl,primr(2)+csr)
  sl=min(priml(2)-csl,primr(2)-csr)

  if (sl > 0) then
     call prim2f(priml,ff)
     return
  endif

  if (sr < 0) then
     call prim2f(primr,ff)
     return
  endif

  call prim2f(priml,fL)
  call prim2f(primr,fR)
  call prim2u(priml,uL)
  call prim2u(primr,uR)

  ff(:)=(sr*fL(:)-sl*fR(:)+sl*sr*(uR(:)-uL(:)))/(sr-sl)

  end subroutine prim2fhlle

!=======================================================================

!> @brief Calculates HLLE fluxes from the primitive variables 
!!   on all the domain
!> @details Calculates HLLE fluxes from the primitive variables 
!!   on all the domain
!> @param integer [in] choice : 1, uses primit for the 1st half of timestep
!! (first order)
!!                  @n 2 uses primit for second order timestep

subroutine hllEfluxes(choice)

  use parameters, only : neq, nx, ny, nz
  use globals, only : primit, f, g, h
  use hydro_core, only : swapy, swapz, limiter
  implicit none
  integer, intent(in) :: choice
  integer :: i, j, k
  real, dimension(neq) :: priml, primr, primll, primrr, ff
  !
  select case(choice)
 
  case(1)        ! 1st half timestep
 
     do k=0,nz
        do j=0,ny
           do i=0,nx
 
              !------- x direction -------------------------------------
              priml(:)=primit(:,i  ,j ,k )
              primr(:)=primit(:,i+1,j ,k )
 
              call prim2fhlle(priml,primr,ff)
              f(:,i,j,k)=ff(:)

              !------- y direction -------------------------------------
              priml(:)=primit(:,i ,j  ,k )
              primr(:)=primit(:,i, j+1,k )
              call swapy(priml,neq)          !swaps primL for L state
              call swapy(primr,neq)          !swaps primR for R state 
 
              call prim2fhlle(priml,primr,ff)  !gets fluxes (swapped)
              call swapy(ff,neq)             !swaps back the fluxes
              g(:,i,j,k)=ff(:)

              !------- z direction -------------------------------------
              priml(:)=primit(:,i ,j ,k  )
              primr(:)=primit(:,i, j, k+1)
              call swapz(priml,neq)
              call swapz(primr,neq)
              !
              call prim2fhlle(priml,primr,ff)
              call swapz(ff,neq)
              h(:,i,j,k)=ff(:)
 
           end do
        end do
     end do
 
  case (2)   !  2nd half timestep
 
     do k=0,nz
        do j=0,ny
           do i=0,nx
  
              !------- x direction ------------------------------------
              priml (:)=primit(:,i,  j,k )
              primr (:)=primit(:,i+1,j,k )
              primll(:)=primit(:,i-1,j,k )
              primrr(:)=primit(:,i+2,j,k )
              call limiter(primll,priml,primr,primrr,neq)
 
              call prim2fhlle(priml,primr,ff)
              f(:,i,j,k)=ff(:)
 
              !------- y direction ------------------------------------
              priml (:)=primit(:,i,j  ,k )
              primr (:)=primit(:,i,j+1,k )
              primll(:)=primit(:,i,j-1,k )
              primrr(:)=primit(:,i,j+2,k )
              call swapy(priml,neq)
              call swapy(primr,neq)
              call swapy(primll,neq)
              call swapy(primrr,neq)
              call limiter(primll,priml,primr,primrr,neq)
 
              call prim2fhlle(priml,primr,ff)
              call swapy(ff,neq)
              g(:,i,j,k)=ff(:)
 
              !------- z direction ------------------------------------
              priml (:)=primit(:,i,j,k  )
              primr (:)=primit(:,i,j,k+1)
              primll(:)=primit(:,i,j,k-1)
              primrr(:)=primit(:,i,j,k+2)
              call swapz(priml,neq)
              call swapz(primr,neq)
              call swapz(primll,neq)
              call swapz(primrr,neq)
              call limiter(primll,priml,primr,primrr,neq)
 
              call prim2fhlle(priml,primr,ff)
              call swapz(ff,neq)
              h(:,i,j,k)=ff(:)
 
           end do
        end do
     end do

  end select

end subroutine hllEfluxes

#endif

!======================================================================
!             SPLIT
!======================================================================
#ifdef MHD_BSPLIT

subroutine prim2fhlle(priml,primr,B0l,B0r,ff)

  use parameters, only : neq
  use hydro_core, only : cfastX_bsplit, prim2f_bsplit, prim2u
  implicit none
  real, dimension(neq),intent(in   ) :: priml, primr
  real, dimension(3) , intent(in   ) :: B0l, B0r
  real, dimension(neq),intent(inout) :: ff
  real, dimension(neq)               :: uR, uL, fL, fR
  real :: csl, csr, sl, sr

  call cfastX_bsplit(priml,B0l,csl)
  call cfastX_bsplit(primr,B0r,csr)

  sr=max(priml(2)+csl,primr(2)+csr)
  sl=min(priml(2)-csl,primr(2)-csr)

  if (sl > 0) then
     call prim2f_bsplit(priml,B0l,ff)
     return
  endif

  if (sr < 0) then
     call prim2f_bsplit(primr,B0r,ff)
     return
  endif

  call prim2f_bsplit(priml,B0l,fL)
  call prim2f_bsplit(primr,B0r,fR)
  call prim2u(priml,uL)
  call prim2u(primr,uR)

  ff(:)=(sr*fL(:)-sl*fR(:)+sl*sr*(uR(:)-uL(:)))/(sr-sl)

  end subroutine prim2fhlle

!=======================================================================

!> @brief Calculates HLLE fluxes from the primitive variables 
!!   on all the domain
!> @details Calculates HLLE fluxes from the primitive variables 
!!   on all the domain
!> @param integer [in] choice : 1, uses primit for the 1st half of timestep
!! (first order)
!!                  @n 2 uses primit for second order timestep

subroutine hllEfluxes(choice)

  use parameters, only : neq, nx, ny, nz
  use globals, only : primit, f, g, h, B0
  use hydro_core, only : swapy, swapz, swapy_bsplit, swapz_bsplit, limiter
  implicit none
  integer, intent(in) :: choice
  integer :: i, j, k
  real, dimension(neq) :: priml, primr, primll, primrr, ff
  real, dimension(3)   :: B0l, B0r, B0ll, B0rr
  !
  select case(choice)
 
  case(1)        ! 1st half timestep
 
     do k=0,nz
        do j=0,ny
           do i=0,nx
 
              !------- x direction -------------------------------------
              priml(:)=primit(:,i  ,j ,k )
              primr(:)=primit(:,i+1,j ,k )
              B0l(:)=B0(:,i ,j ,k)
              B0r(:)=B0(:,i+1 ,j ,k)
 
              call prim2fhlle(priml,primr,B0l,B0r,ff)
              f(:,i,j,k)=ff(:)

              !------- y direction -------------------------------------
              priml(:)=primit(:,i ,j  ,k )
              primr(:)=primit(:,i, j+1,k )
              B0l(:)=B0(:,i ,j   ,k)
              B0r(:)=B0(:,i ,j+1 ,k)
              
              call swapy(priml,neq)          !swaps primL for L state
              call swapy(primr,neq)          !swaps primR for R state 
              call swapy_bsplit(B0l,3)
              call swapy_bsplit(B0r,3)
 
              call prim2fhlle(priml,primr,B0l,B0r,ff)  !gets fluxes (swapped)
              call swapy(ff,neq)             !swaps back the fluxes
              g(:,i,j,k)=ff(:)

              !------- z direction -------------------------------------
              priml(:)=primit(:,i ,j ,k  )
              primr(:)=primit(:,i, j ,k+1)
              B0l(:)=B0(:,i ,j ,k)
              B0r(:)=B0(:,i ,j ,k+1)
              
              call swapz(priml,neq)
              call swapz(primr,neq)
              call swapz_bsplit(B0l,3)
              call swapz_bsplit(B0r,3) 
              
              call prim2fhlle(priml,primr,B0l,B0r,ff)
              call swapz(ff,neq)
              h(:,i,j,k)=ff(:)
 
           end do
        end do
     end do
 
  case (2)   !  2nd half timestep
! 2016/04/14
! DISCUTIR CON ALEJANDRO Y CARO LA NECESIDAD DE LIM PARA LOS B0 
     do k=0,nz
        do j=0,ny
           do i=0,nx
  
              !------- x direction ------------------------------------
              priml (:)=primit(:,i,  j,k )
              primr (:)=primit(:,i+1,j,k )
              primll(:)=primit(:,i-1,j,k )
              primrr(:)=primit(:,i+2,j,k )
              B0l (:)=B0(:,i   ,j ,k)
              B0r (:)=B0(:,i+1 ,j ,k)
              B0ll(:)=B0(:,i-1 ,j ,k)
              B0rr(:)=B0(:,i+2 ,j ,k)
              
              call limiter(primll,priml,primr,primrr,neq)
              call limiter(B0ll,B0l,B0r,B0rr,3)
 
              call prim2fhlle(priml,primr,B0l,B0r,ff)
              f(:,i,j,k)=ff(:)
 
              !------- y direction ------------------------------------
              priml (:)=primit(:,i,j  ,k )
              primr (:)=primit(:,i,j+1,k )
              primll(:)=primit(:,i,j-1,k )
              primrr(:)=primit(:,i,j+2,k )
              B0l (:)=B0(:,i,j  ,k )
              B0r (:)=B0(:,i,j+1,k )
              B0ll(:)=B0(:,i,j-1,k )
              B0rr(:)=B0(:,i,j+2,k )
              
              call swapy(priml,neq)
              call swapy(primr,neq)
              call swapy(primll,neq)
              call swapy(primrr,neq)
              
!               call swapy_bsplit(B0l,3)
!               call swapy_bsplit(B0r,3)
!               call swapy_bsplit(B0ll,3)
!               call swapy_bsplit(B0rr,3)
 
              call limiter(primll,priml,primr,primrr,neq)
              call limiter(B0ll,B0l,B0r,B0rr,3)
 
              call swapy_bsplit(B0l,3)
              call swapy_bsplit(B0r,3)
 
              call prim2fhlle(priml,primr,B0l,B0r,ff)
              call swapy(ff,neq)
              g(:,i,j,k)=ff(:)
 
              !------- z direction ------------------------------------
              priml (:)=primit(:,i,j,k  )
              primr (:)=primit(:,i,j,k+1)
              primll(:)=primit(:,i,j,k-1)
              primrr(:)=primit(:,i,j,k+2)
              B0l (:)=B0(:,i,j,k  )
              B0r (:)=B0(:,i,j,k+1)
              B0ll(:)=B0(:,i,j,k-1)
              B0rr(:)=B0(:,i,j,k+2)
              
              call swapz(priml,neq)
              call swapz(primr,neq)
              call swapz(primll,neq)
              call swapz(primrr,neq)
              
!               call swapz_bsplit(B0l,3)
!               call swapz_bsplit(B0r,3)
!               call swapz_bsplit(B0ll,3)
!               call swapz_bsplit(B0rr,3)
 
              call limiter(primll,priml,primr,primrr,neq)
              call limiter(B0ll,B0l,B0r,B0rr,3)
              
              call swapz_bsplit(B0l,3)
              call swapz_bsplit(B0r,3)
 
              call prim2fhlle(priml,primr,B0l,B0r,ff)
              call swapz(ff,neq)
              h(:,i,j,k)=ff(:)
 
           end do
        end do
     end do

  end select

end subroutine hllEfluxes

#endif
!=======================================================================
#endif

end module hlle
