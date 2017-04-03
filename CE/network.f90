!=======================================================================
!> @file network.f90
!> @brief chemical network module
!> @author P. Rivera, A. Rodriguez, A. Castellanos,  A. Raga and A. Esquivel
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

!> @brief Chemical/atomic network module
!> @details this module should be generated by an interface code.

 module network

  implicit none

 ! number of species
  integer, parameter :: n_spec = 5

  ! number of equilibrium species
  integer, parameter:: nequil = 2

  ! number of total elements
  integer, parameter :: n_elem = 1

  ! number of non-equilibrium equations
  integer, parameter :: n_nequ = n_spec - nequil

  ! indexes of the different species
  integer, parameter :: Hhp = 1  ! hot ionized H
  integer, parameter :: Hh0 = 2  ! hot neutral H
  integer, parameter :: Hcp = 3  ! cold ionized H
  integer, parameter :: Hc0 = 4  ! cold neutral H
  integer, parameter :: ie  = 5  ! electron density

  ! indexes of the equilibrium species
  integer, parameter :: Ht = 1

  ! number of reaction rates
  integer, parameter :: n_reac = 5

  ! indexes of the different rates
  integer, parameter :: alpha = 1
  integer, parameter :: coll  = 2
  integer, parameter :: beta  = 3
  integer, parameter :: phiH  = 4
  integer, parameter :: phiC  = 5

 contains

!=======================================================================

subroutine derv(y,rate,dydt,y0)

  implicit none
  real (kind=8), intent(in)  ::   y0(n_elem)
  real (kind=8), intent(in)  ::    y(n_spec)
  real (kind=8), intent(out) :: dydt(n_spec)
  real (kind=8), intent(in)  :: rate(n_reac)

  dydt(Hhp)= rate(coll)*y(Hh0)*y(ie)  - rate(alpha)*y(Hhp)*y(ie) + &
             rate(beta)*y(Hh0)*y(Hcp) - rate(beta)*y(Hhp)*y(Hc0) + &
             rate(phiH)*y(Hh0)

  dydt(Hh0) = - dydt(Hhp)

  dydt(Hcp)= rate(coll)*y(Hc0)*y(ie)  - rate(alpha)*y(Hcp)*y(ie) + &
             rate(beta)*y(Hc0)*y(Hhp) - rate(beta)*y(Hcp)*y(Hh0) + &
             rate(phiC)*y(Hc0)

  !conservation species
  dydt(Hc0) = - y0(Ht) + y(Hcp)+ y(Hh0)+ y(Hcp)+ y(Hc0)
  dydt(ie ) = - y(ie) + y(Hhp) + y(Hcp)

   end subroutine derv

!=======================================================================

subroutine get_jacobian(y,jacobian,rate)

  implicit none
  real (kind=8), intent(in)  :: y(n_spec)
  real (kind=8), intent(out) :: jacobian(n_spec,n_spec)
  real (kind=8), intent(in)  :: rate(n_reac)

  !Hhp
  jacobian(Hhp, Hhp) = - rate(alpha)*y(ie ) - rate(beta)*y(Hc0)
  jacobian(Hhp, Hh0) =   rate(coll )*y(ie ) + rate(beta)*y(Hcp) + phiH
  jacobian(Hhp, Hcp) =   rate(beta )*y(Hh0)
  jacobian(Hhp, Hc0) = - rate(beta )*y(Hhp)
  jacobian(Hhp, ie ) =   rate(coll )*y(Hh0) - rate(alpha)*y(Hcp)

  !Hh0
  jacobian(Hh0, Hhp) = - jacobian(Hhp, Hhp)
  jacobian(Hh0, Hh0) = - jacobian(Hhp, Hh0)
  jacobian(Hh0, Hcp) = - jacobian(Hhp, Hcp)
  jacobian(Hh0, Hc0) = - jacobian(Hhp, Hc0)
  jacobian(Hh0, ie ) = - jacobian(Hhp, ie )

  !Hcp
  jacobian(Hcp, Hhp) =   rate(beta )*y(Hc0)
  jacobian(Hcp, Hh0) = - rate(beta )*y(Hhp)
  jacobian(Hcp, Hcp) = - rate(alpha)*y(ie ) - rate(beta)*y(Hh0)
  jacobian(Hcp, Hc0) =   rate(coll )*y(ie ) + rate(beta)*y(Hhp) + phiC
  jacobian(Hcp, ie ) =   rate(coll )*y(Hc0) - rate(alpha)*y(Hcp)

  !Htot
  jacobian(Hc0, Hhp) = 1.
  jacobian(Hc0, Hh0) = 1.
  jacobian(Hc0, Hcp) = 1.
  jacobian(Hc0, Hc0) = 1.
  jacobian(Hc0, ie ) = 0.

  !ne
  jacobian(ie , Hhp) =  1.
  jacobian(ie , Hh0) =  0.
  jacobian(ie , Hcp) =  1.
  jacobian(ie , Hc0) =  0.
  jacobian(ie , ie ) = -1.

end subroutine get_jacobian

!=======================================================================

subroutine get_reaction_rates(rate,T,phiH,phiC)
  implicit none
  real (kind=8), intent(in)                    :: T, phiH, phiC
  real (kind=8), dimension(n_reac),intent(out) ::rate

  rate(alpha) = 2.55d-13*(1.e4/T)**0.79
  rate(coll ) = 5.83e-11*sqrt(T)*exp(-157828./T)
  rate(beta ) = 4.0E-08
  rate(phiH ) = phiH
  rate(phiC ) = phiC

end subroutine get_reaction_rates

!=======================================================================

subroutine nr_init(y,y0)
  implicit none
  real, intent(out) :: y(n_spec)
  real, intent(in ) :: y0(n_elem)
  real :: yhi

  yhi=y0(Ht)

  y(Hhp) = yhi/4.
  y(Hh0) = yhi/4.
  y(Hcp) = yhi/4.
  y(Hc0) = yhi/4.
  y(ie ) = y(Hhp) + y(HCp)

  return
end subroutine nr_init

!=======================================================================

logical function check_no_conservation(y,y0_in)
  implicit none
  real, intent(in)  :: y(n_spec)
  real, intent(in ) :: y0_in  (n_elem)
  real              :: y0_calc(n_elem)
  integer           :: i

  check_no_conservation = .false.

  y0_calc(Ht)= y(Hhp) + y(Hh0) + y(Hcp) + y(Hc0)

  do i = 1, n_elem
    if ( y0_calc(i) > 1.0001*y0_in(i) ) check_no_conservation = .true.
  end do

end function check_no_conservation

!=======================================================================

end module network

!=======================================================================
