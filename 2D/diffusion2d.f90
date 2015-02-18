!**************************************************************************!
!                                                                          !
!  Module:       DIFFUSION2D.F90                                           !
!                                                                          !
!  Programmer:   Julian M. Toumey                                          !
!                Madison, WI                                               !
!                                                                          !
!  Date:         January 2015                                              !
!                                                                          !
!  Language:     FORTRAN90                                                 !
!                                                                          !
!  Description:  This code solves source-free heat conduction in a 2-D     !
!                plate. The method follows example 7.2 in Versteeg and     !
!                Malalasekera, 2nd ed. The code assumes temporarily        !
!                constant T_E and T_W values and solves along N-S lines    !
!                using the Thomas algorithm.                               !
!                                                                          !
!**************************************************************************!
PROGRAM DIFFUSION2D
IMPLICIT NONE
!
integer IL,JL,ii,jj,kk,iter
parameter (IL=300,JL=400)
real dx,dy,xmax,ymax,x(IL),y(JL)
real aw,ae,as,an,Su,Sp,ap
real qw,k,area,Tn
real a(JL),b(JL),c(JL),d(JL)
real Tsol(JL),resid
real, dimension(JL,IL) :: T,Tprev
real t1,t2
real Fr,Frtemp,Frp
Fr = 0.
Frtemp = 0.
Frp = 0.
!
!...Parameters for iteration
!
resid = 1000.
iter  = 0.
!
!...set up the grid
!
xmax = 30.
dx   = xmax/float(IL)
do ii = 1,IL
   x(ii) = (ii-0.5)*dx
end do
!
ymax = 40.
dy   = ymax/float(JL)
do jj = 2,JL
   y(jj) = (jj-0.5)*dy
end do
!
!...physical properties
!   West heat flux [W/m^2], therm. conduct. [W/m.K], North fixed temp [*C]
!   plate thickness 1 cm, area [m^2], initial temperature 0 [*C] everywhere
!
qw   = 500000.
k    = 1000.
Tn   = 100.
area = 0.001
T    = 0.
!--------------------------------------------------------------------------!
!
!...Begin outer WHILE iterative loop 
!
!--------------------------------------------------------------------------!
call cpu_time(t1)
do while (resid >= 0.0001)
   !   save previous temperature distribution to compare errors
   Tprev = T
   !************************************************************************
   !
   !   Set the residual to zero to begin the summation. 
   !
   !************************************************************************
   resid = 0.
   !-----------------------------------------------------------------------!
   !
   !...West Cells
   !
   !-----------------------------------------------------------------------!
   !
   !   SW Corner
   aw = 0.
   ae = k*area/dx
   as = 0.
   an = k*area/dx
   Sp = 0.
   Su = area*qw
   ap = aw + ae + as + an - Sp
   !
   a(1) = -as
   b(1) =  ap
   c(1) = -an
   d(1) =  Su + ae*T(1,2)
   !
   resid = resid + abs(ae*T(1,2) + an*T(2,1) + Su - ap*T(1,1))
   Frp = Frp + abs(ap*T(1,1))
   !   West Interior cells
   do jj = 2,JL-1
      aw = 0.
      ae = k*area/dx
      as = k*area/dx
      an = k*area/dx
      Sp = 0.
      Su = area*qw
      ap = aw + ae + as + an - Sp
      !
      a(jj) = -as
      b(jj) =  ap
      c(jj) = -an
      d(jj) =  Su + ae*T(jj,2)
      !
      resid = resid + abs(ae*T(jj,2) + an*T(jj+1,1) + as*T(jj-1,1) + Su - ap*T(jj,1))
      Frp = Frp + abs(ap*T(jj,1))
   end do
   !   NW corner
   aw =  0.
   ae =  k*area/dx
   as =  k*area/dx
   an =  0.
   Sp = -2.*k*area/dx
   Su =  area*qw + 2.*k*area*Tn/dx
   ap =  aw + ae + as + an - Sp
   !
   a(JL) = -as
   b(JL) =  ap
   c(JL) = -an
   d(JL) =  Su + ae*T(JL,2)
   !
   resid = resid + abs(ae*T(JL,2) + as*T(JL-1,1) + Su - ap*T(JL,1))
   Frp = Frp + abs(ap*T(JL,1))
   !
   !...solve N-S system with the TDMA
   !
   call thomas(JL,a,b,c,d,Tsol)
   !...Store temperature solution
   T(:,1) = Tsol
   !
   !-----------------------------------------------------------------------!
   !
   !...Interior Cells, marching W to E
   !
   !-----------------------------------------------------------------------!
   do ii = 2,IL-1
      !   South boundary
      aw = k*area/dx
      ae = k*area/dx
      as = 0.
      an = k*area/dx
      Sp = 0
      Su = 0
      ap = aw + ae + as + an - Sp
      !
      a(1) = -as
      b(1) =  ap
      c(1) = -an
      d(1) =  Su + ae*T(1,ii+1) + aw*T(1,ii-1)
      !
      resid = resid + abs(aw*T(1,ii-1) + ae*T(1,ii+1) + an*T(2,ii) + Su - ap*T(1,ii))
      Frp = Frp + abs(ap*T(1,ii))
      !
      do jj = 2,JL-1
         aw = k*area/dx
         ae = k*area/dx
         as = k*area/dx
         an = k*area/dx
         Sp = 0.
         Su = 0.
         ap = aw + ae + as + an - Sp
         !
         a(jj) = -as
         b(jj) =  ap
         c(jj) = -an
         d(jj) =  Su + ae*T(jj,ii+1) + aw*T(jj,ii-1)
        !
        resid = resid + abs(aw*T(jj,ii-1) + ae*T(jj,ii+1) + an*T(jj+1,ii) + as*T(jj-1,ii) + Su - ap*T(jj,ii))
        Frp = Frp + abs(ap*T(jj,ii))
        !
      end do
      !...North boundary
      aw =  k*area/dx
      ae =  k*area/dx
      as =  k*area/dx
      an =  0.
      Sp = -2.*k*area/dx
      Su =  2.*k*area*Tn/dx
      ap = aw + ae + as + an - Sp
      !
      a(JL) = -as
      b(JL) =  ap
      c(JL) = -an
      d(JL) =  Su + ae*T(jj,ii+1) + aw*T(jj,ii-1)
      !
      resid = resid + abs(aw*T(JL,ii-1) + ae*T(JL,ii+1) + as*T(JL-1,ii) + Su - ap*T(JL,ii))
      Frp = Frp + abs(ap*T(JL,ii))
      !
      !...solve N-S system with the TDMA
      !
      call thomas(JL,a,b,c,d,Tsol)
      !...Store temperature solution
      T(:,ii) = Tsol
   end do
   !-----------------------------------------------------------------------!
   !
   !...East Cells
   !
   !-----------------------------------------------------------------------!
   !
   !   SE Corner
   aw = k*area/dx
   ae = 0.
   as = 0.
   an = k*area/dx
   Sp = 0.
   Su = 0.
   ap = aw + ae + as + an - Sp
   !
   a(1) = -as
   b(1) =  ap
   c(1) = -an
   d(1) =  Su + aw*T(1,IL-1)
   !
   resid = resid + abs(aw*T(1,IL-1) + an*T(2,IL) + Su - ap*T(JL,IL))
   Frp = Frp + abs(ap*T(JL,IL))
   !
   do jj = 2,JL-1
      aw = k*area/dx
      ae = 0.
      as = k*area/dx
      an = k*area/dx
      Sp = 0.
      Su = 0.
      ap = aw + ae + as + an - Sp
      !
      a(jj) = -as
      b(jj) =  ap
      c(jj) = -an
      d(jj) =  Su + aw*T(jj,IL-1)
      !
      resid = resid + abs(aw*T(jj,IL-1) + an*T(jj+1,IL) + as*T(jj-1,IL) + Su - ap*T(jj,IL))
      Frp = Frp + abs(ap*T(jj,IL))
   end do
   !...NE corner
   aw =  k*area/dx
   ae =  0.
   as =  k*area/dx
   an =  0.
   Sp = -2.*k*area/dx
   Su =  2.*k*area*Tn/dx
   ap =  aw + ae + as + an - Sp
   !
   a(JL) = -as
   b(JL) =  ap
   c(JL) = -an
   d(JL) =  Su + aw*T(JL,IL-1)
   !
   resid = resid + abs(aw*T(JL,IL-1) + as*T(JL-1,IL) + Su - ap*T(JL,IL))
   Frp = Frp + abs(ap*T(JL,IL))
   !
   !...solve system with the TDMA
   !
   call thomas(JL,a,b,c,d,Tsol)
   !...Store N-S temperature solution
   T(:,IL) = Tsol
   !
   !...Recompute the error, increment the iteration
   !
   !write(*,*)resid,Fr
   resid = resid/Frp
   !
   iter  = iter + 1
   write(6,401)iter,resid
end do
call cpu_time(t2)
!--------------------------------------------------------------------------!
!
!...Write the results to a file
!
!--------------------------------------------------------------------------!
open(unit=7,file='plate_temp.dat',ACTION="write", STATUS="replace")
do jj = JL,1,-1
   write(7,'(1000f12.5)') (T(jj,ii),ii=1,IL)
end do
write(6,201)t2 - t1
201 format(3x,f12.5)
401 format(3x,'*** Iteration : ',i8,3x,'Residual :',f12.7,'  ***')
END