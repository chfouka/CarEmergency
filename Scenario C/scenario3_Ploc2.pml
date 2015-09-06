
/** Proprietà : se una richiesta di servizio fallisce allora la località del damage non è servita dal servizio
        richiesto (garage oppure truck). */

bool subscriber[2] = false;
mtype = { Pisa, Lucca, Livorno, Firenze };
mtype = { request, reply, release, damage }; 

/*comunicazione 1-1 oppure un solo servizio => rendez-vous channel*/
chan caremUser[2] = [0] of { mtype, bit };
chan caremDamage[2] = [0] of { mtype };
chan caremCreditcard[2] = [0] of { mtype }; 
chan caremTruck = [0] of {mtype, mtype}
chan caremHandle[2] = [0] of {mtype, bit}
chan caremRental = [0] of {mtype, mtype}

/*ci sono due server => buffered channel*/
chan caremGarage = [2] of { mtype, mtype, byte }; 
chan garageCarem = [2] of {mtype, byte, byte, bit};


#define PI 0
#define LU 1
#define LI 2
#define FI 3

bool truckServed[4] = false;
bool garageServed[4] = false;


proctype User( bit i ){
 if
 :: subscriber[i] = false
 :: subscriber[i] = true
 fi;
  
 atomic{
  run CarEmergency( i );
  run Damage( i );
  run CreditCard( i ); 
  }
 
 end:
 do
 :: caremUser[i] ? request, _ ->
              if
              ::caremUser[i] ! reply( 1 )
              ::caremUser[i] ! reply( 0 )
              fi
 od
}



proctype Damage( bit i ){
 
 end:
 do
 :: 1 -> caremDamage[i] ! damage; 
 :: 1 -> skip
 od

}


proctype CarEmergency( bit i ){
 mtype location;
 byte index;
 bit u;
 byte garage;
 run HandleRental( i );

 end:
 do
 :: caremDamage[i] ? damage ->
              if
              :: location = Lucca;  index = LU
              :: location = Pisa;   index = PI;
              :: location = Livorno; index = LI
              :: location = Firenze; index = FI
              fi;
              if
              :: !subscriber[i] ->
                      caremUser[i] ! request( 1 ) ;
                      caremUser[i] ? reply( u );
                      if
                      :: !u -> goto end
                      ::  u -> goto wantServices
                      fi 
              :: subscriber[i] ->  goto wantServices
              fi;
              wantServices: 

              caremCreditcard[i] ! request;
              caremCreditcard[i] ? reply;
              

              caremGarage ! request, location, _pid;
              garageCarem ?? reply, eval(_pid), garage, u;
              if 
              :: ( !u )-> 
                 assert( !garageServed[index] );
                 goto end    
              :: else->skip
              fi;          
              
              caremHandle[i] ! location, 1;
   
              caremTruck ! request, location;
              caremTruck ? reply, u;
              if 
              ::( !u )-> caremHandle[i] ? _, _; caremGarage ! release, location, garage; 
                assert( !truckServed[index] );
                goto end
              :: else->skip
              fi;

               /*transport and release*/
               caremTruck ! release, 1 ;
              
              /*Use garage*/

              /*Release garage*/
              caremGarage ! release, location, garage;
              /*synch with handle*/
              caremHandle[i] ? _, _;

 od

}

proctype CreditCard( bit i ){
 end:
 do
 :: caremCreditcard[i] ? request-> caremCreditcard[i] ! reply
 od

}

active [2] proctype Garage( ){
 byte ideCarem;
 mtype location;
 mtype loCarem;
 
 if
 :: location = Lucca; garageServed[LU] = true
 :: location = Pisa; garageServed[PI] = true
 :: location = Livorno; garageServed[LI] = true
 :: location = Firenze; garageServed[FI] = true
 fi;


 end:
 do
 ::caremGarage ? request, loCarem, ideCarem -> 
                   if
                   :: ( loCarem == location ) ->
                         garageCarem ! reply, ideCarem, _pid, 1 ; 
                         caremGarage ?? release, _, eval(_pid) ; 
                   :: (loCarem != location ) -> garageCarem ! reply, ideCarem, _pid, 0;
                   fi
 od 
}

active proctype Truck( ){
 mtype location1;
 mtype location2;
 mtype loCarem;

 if
 :: location1 = Lucca; truckServed[LU] = true
 :: location1 = Pisa; truckServed[PI] = true
 :: location1 = Livorno; truckServed[LI] = true
 :: location1 = Firenze; truckServed[FI] = true
 fi;

 if
 :: location2 = Lucca; truckServed[LU] = true
 :: location2 = Pisa; truckServed[PI] = true
 :: location2 = Livorno; truckServed[LI] = true
 :: location2 = Firenze; truckServed[FI] = true
 fi;



 end:
 do
 ::caremTruck ? request, loCarem -> 
              if 
              :: (loCarem == location1 || loCarem == location2 ) ->
                 caremTruck ! reply, 1; 
                 caremTruck ? release, _ ; 
              :: else -> caremTruck ! reply, 0;
              fi
 od

}


proctype HandleRental( bit i ){
 mtype loCarem;
 bit r;

 end:
 do
 ::caremHandle[i] ? loCarem, _->
           caremRental ! request, loCarem;
           caremRental ? reply, r;
           if 
           :: !r -> caremHandle[i] ! loCarem, 1;
           :: else ->
              /*use */
           
              /*release*/
              caremRental ! release, loCarem ;
           
               /*synch with CarEmergency*/
               caremHandle[i] ! loCarem, 1;
           fi
 od
}

active proctype RentalCar( ){
 mtype location1;
 mtype location2;
 mtype loCarem;


 if
 :: location1 = Lucca
 :: location1 = Pisa
 :: location1 = Livorno
 :: location1 = Firenze
 fi;

 if
 :: location2 = Lucca
 :: location2 = Pisa
 :: location2 = Livorno
 :: location2 = Firenze
 fi;

 end:
 do
 :: caremRental ? request, loCarem -> 
               if
               :: ( loCarem == location1 || loCarem == location2 ) ->
                 caremRental ! reply, 1; 
                caremRental ? release, _ ; 
               :: else -> caremRental ! reply, 0; 
               fi
 od
}



init{
   atomic{
  run User( 0 ); 
  run User( 1 );
 }

}

/*

SPin verification: assert violata

nota: compilare con gcc -DMEMLIM=3000 -O2 -DBITSTATE -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c 
   eseguire con ./pan -m1000000 

Ecco una traccia:

spin: scenario3_Ploc2.pml:60, redundant skip
using statement merging
Starting User with pid 5
  1: proc  4 (:init:) scenario3_Ploc2.pml:259 (state 1) [(run User(0))]
Starting User with pid 6
  2: proc  4 (:init:) scenario3_Ploc2.pml:260 (state 2) [(run User(1))]
  3: proc  3 (RentalCar) scenario3_Ploc2.pml:230 (state 1) [location1 = Lucca]
  4: proc  3 (RentalCar) scenario3_Ploc2.pml:237 (state 7) [location2 = Lucca]
  5: proc  2 (Truck) scenario3_Ploc2.pml:171 (state 1) [location1 = Lucca]
  6: proc  1 (Garage) scenario3_Ploc2.pml:146 (state 1) [location = Lucca]
  7: proc  0 (Garage) scenario3_Ploc2.pml:147 (state 3) [location = Pisa]
  8: proc  5 (User) scenario3_Ploc2.pml:34 (state 2) [subscriber[i] = 1]
Starting CarEmergency with pid 7
  9: proc  5 (User) scenario3_Ploc2.pml:38 (state 5) [(run CarEmergency(i))]
Starting Damage with pid 8
 10: proc  5 (User) scenario3_Ploc2.pml:39 (state 6) [(run Damage(i))]
Starting CreditCard with pid 9
 11: proc  5 (User) scenario3_Ploc2.pml:40 (state 7) [(run CreditCard(i))]
 12: proc  8 (Damage) scenario3_Ploc2.pml:59 (state 1) [(1)]
Starting HandleRental with pid 10
 13: proc  7 (CarEmergency) scenario3_Ploc2.pml:71 (state 1) [(run HandleRental(i))]
 14: proc  8 (Damage) scenario3_Ploc2.pml:59 (state 2) [caremDamage[i]!damage]
 15: proc  7 (CarEmergency) scenario3_Ploc2.pml:75 (state 2) [caremDamage[i]?damage]
 16: proc  8 (Damage) scenario3_Ploc2.pml:59 (state 1) [(1)]
 17: proc  7 (CarEmergency) scenario3_Ploc2.pml:77 (state 3) [location = Lucca]
 17: proc  7 (CarEmergency) scenario3_Ploc2.pml:77 (state 4) [index = 1]
 18: proc  7 (CarEmergency) scenario3_Ploc2.pml:90 (state 22) [(subscriber[i])]
 19: proc  7 (CarEmergency) scenario3_Ploc2.pml:94 (state 26) [caremCreditcard[i]!request]
 20: proc  9 (CreditCard) scenario3_Ploc2.pml:135 (state 1) [caremCreditcard[i]?request]
 21: proc  9 (CreditCard) scenario3_Ploc2.pml:135 (state 2) [caremCreditcard[i]!reply]
 22: proc  7 (CarEmergency) scenario3_Ploc2.pml:95 (state 27) [caremCreditcard[i]?reply]
 23: proc  7 (CarEmergency) scenario3_Ploc2.pml:98 (state 28) [caremGarage!request,location,_pid]
 24: proc  2 (Truck) scenario3_Ploc2.pml:171 (state 2) [truckServed[1] = 1]
 25: proc  2 (Truck) scenario3_Ploc2.pml:178 (state 11) [location2 = Lucca]
 26: proc  6 (User) scenario3_Ploc2.pml:33 (state 1) [subscriber[i] = 0]
Starting CarEmergency with pid 11
 27: proc  6 (User) scenario3_Ploc2.pml:38 (state 5) [(run CarEmergency(i))]
Starting Damage with pid 12
 28: proc  6 (User) scenario3_Ploc2.pml:39 (state 6) [(run Damage(i))]
Starting CreditCard with pid 13
 29: proc  6 (User) scenario3_Ploc2.pml:40 (state 7) [(run CreditCard(i))]
 30: proc 12 (Damage) scenario3_Ploc2.pml:59 (state 1) [(1)]
Starting HandleRental with pid 14
 31: proc 11 (CarEmergency) scenario3_Ploc2.pml:71 (state 1) [(run HandleRental(i))]
 32: proc  2 (Truck) scenario3_Ploc2.pml:178 (state 12) [truckServed[1] = 1]
 33: proc 12 (Damage) scenario3_Ploc2.pml:59 (state 2) [caremDamage[i]!damage]
 34: proc 11 (CarEmergency) scenario3_Ploc2.pml:75 (state 2) [caremDamage[i]?damage]
 35: proc 12 (Damage) scenario3_Ploc2.pml:59 (state 1) [(1)]
 36: proc 11 (CarEmergency) scenario3_Ploc2.pml:77 (state 3) [location = Lucca]
 36: proc 11 (CarEmergency) scenario3_Ploc2.pml:77 (state 4) [index = 1]
 37: proc  1 (Garage) scenario3_Ploc2.pml:146 (state 2) [garageServed[1] = 1]
 38: proc 11 (CarEmergency) scenario3_Ploc2.pml:83 (state 13) [(!(subscriber[i]))]
 39: proc  1 (Garage) scenario3_Ploc2.pml:155 (state 11) [caremGarage?request,loCarem,ideCarem]
 40: proc  1 (Garage) scenario3_Ploc2.pml:157 (state 12) [((loCarem==location))]
 41: proc 11 (CarEmergency) scenario3_Ploc2.pml:84 (state 14) [caremUser[i]!request,1]
 42: proc  6 (User) scenario3_Ploc2.pml:45 (state 9) [caremUser[i]?request,_]
 43: proc  6 (User) scenario3_Ploc2.pml:47 (state 10) [caremUser[i]!reply,1]
 44: proc 11 (CarEmergency) scenario3_Ploc2.pml:85 (state 15) [caremUser[i]?reply,u]
 45: proc 11 (CarEmergency) scenario3_Ploc2.pml:88 (state 18) [(u)]
 46: proc 11 (CarEmergency) scenario3_Ploc2.pml:94 (state 26) [caremCreditcard[i]!request]
 47: proc 13 (CreditCard) scenario3_Ploc2.pml:135 (state 1) [caremCreditcard[i]?request]
 48: proc  1 (Garage) scenario3_Ploc2.pml:158 (state 13) [garageCarem!reply,ideCarem,_pid,1]
 49: proc  0 (Garage) scenario3_Ploc2.pml:147 (state 4) [garageServed[0] = 1]
 50: proc  7 (CarEmergency) scenario3_Ploc2.pml:99 (state 29) [garageCarem??reply,eval(_pid),garage,u]
 51: proc  7 (CarEmergency) scenario3_Ploc2.pml:104 (state 33) [else]
 52: proc  7 (CarEmergency) scenario3_Ploc2.pml:104 (state 34) [(1)]
 53: proc 13 (CreditCard) scenario3_Ploc2.pml:135 (state 2) [caremCreditcard[i]!reply]
 54: proc 11 (CarEmergency) scenario3_Ploc2.pml:95 (state 27) [caremCreditcard[i]?reply]
 55: proc 11 (CarEmergency) scenario3_Ploc2.pml:98 (state 28) [caremGarage!request,location,_pid]
 56: proc  7 (CarEmergency) scenario3_Ploc2.pml:107 (state 37) [caremHandle[i]!location,1]
 57: proc 10 (HandleRental) scenario3_Ploc2.pml:206 (state 1) [caremHandle[i]?loCarem,_]
 58: proc  0 (Garage) scenario3_Ploc2.pml:155 (state 11) [caremGarage?request,loCarem,ideCarem]
 59: proc  0 (Garage) scenario3_Ploc2.pml:160 (state 15) [((loCarem!=location))]
 60: proc  0 (Garage) scenario3_Ploc2.pml:160 (state 16) [garageCarem!reply,ideCarem,_pid,0]
 61: proc 11 (CarEmergency) scenario3_Ploc2.pml:99 (state 29) [garageCarem??reply,eval(_pid),garage,u]
 62: proc 11 (CarEmergency) scenario3_Ploc2.pml:101 (state 30) [(!(u))]
spin: scenario3_Ploc2.pml:102, Error: assertion violated
spin: text of failed assertion: assert(!(garageServed[index]))
#processes: 15
 63: proc 14 (HandleRental) scenario3_Ploc2.pml:205 (state 11)
 63: proc 13 (CreditCard) scenario3_Ploc2.pml:134 (state 3)
 63: proc 12 (Damage) scenario3_Ploc2.pml:59 (state 2)
 63: proc 11 (CarEmergency) scenario3_Ploc2.pml:102 (state 31)
 63: proc 10 (HandleRental) scenario3_Ploc2.pml:207 (state 2)
 63: proc  9 (CreditCard) scenario3_Ploc2.pml:134 (state 3)
 63: proc  8 (Damage) scenario3_Ploc2.pml:59 (state 2)
 63: proc  7 (CarEmergency) scenario3_Ploc2.pml:109 (state 38)
 63: proc  6 (User) scenario3_Ploc2.pml:44 (state 14)
 63: proc  5 (User) scenario3_Ploc2.pml:44 (state 14)
 63: proc  4 (:init:) scenario3_Ploc2.pml:263 (state 4)
 63: proc  3 (RentalCar) scenario3_Ploc2.pml:244 (state 21)
 63: proc  2 (Truck) scenario3_Ploc2.pml:187 (state 29)
 63: proc  1 (Garage) scenario3_Ploc2.pml:159 (state 14)
 63: proc  0 (Garage) scenario3_Ploc2.pml:154 (state 19)
15 processes created
Exit-Status 0
*/


/** Si osservi che commentando l'assert su garage, l'asser su truck è verificata:

spin -a  scenario3_Ploc2.pml
gcc -DMEMLIM=3000 -O2 -DBITSTATE -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
./pan -m10000000  -c1
Pid: 10935
Depth=  335774 States=    1e+06 Transitions= 2.52e+06 Memory=   414.153 t=     3.18 R=   3e+05
Depth=  335774 States=    2e+06 Transitions= 5.18e+06 Memory=   414.153 t=     6.67 R=   3e+05
Depth=  335774 States=    3e+06 Transitions= 7.91e+06 Memory=   414.153 t=     10.2 R=   3e+05
Depth=  335774 States=    4e+06 Transitions= 1.04e+07 Memory=   414.153 t=     13.3 R=   3e+05
Depth=  335774 States=    5e+06 Transitions= 1.31e+07 Memory=   414.153 t=     16.9 R=   3e+05
Depth=  335774 States=    6e+06 Transitions= 1.58e+07 Memory=   414.153 t=     20.6 R=   3e+05
Depth=  335774 States=    7e+06 Transitions= 1.84e+07 Memory=   414.153 t=     24.1 R=   3e+05
Depth=  335774 States=    8e+06 Transitions=  2.1e+07 Memory=   414.153 t=     27.3 R=   3e+05
Depth=  335774 States=    9e+06 Transitions= 2.37e+07 Memory=   414.153 t=     30.7 R=   3e+05
Depth=  335774 States=    1e+07 Transitions= 2.61e+07 Memory=   414.153 t=     33.9 R=   3e+05
Depth=  335774 States=  1.1e+07 Transitions= 2.87e+07 Memory=   414.153 t=     37.5 R=   3e+05
Depth=  335774 States=  1.2e+07 Transitions= 3.12e+07 Memory=   414.153 t=     40.9 R=   3e+05
Depth=  335774 States=  1.3e+07 Transitions= 3.38e+07 Memory=   414.153 t=     44.4 R=   3e+05
Depth=  335774 States=  1.4e+07 Transitions= 3.64e+07 Memory=   414.153 t=     47.9 R=   3e+05
Depth=  335774 States=  1.5e+07 Transitions= 3.88e+07 Memory=   414.153 t=     51.2 R=   3e+05
Depth=  335774 States=  1.6e+07 Transitions= 4.13e+07 Memory=   414.153 t=     54.7 R=   3e+05
Depth=  335774 States=  1.7e+07 Transitions= 4.38e+07 Memory=   414.153 t=       58 R=   3e+05
Depth=  335774 States=  1.8e+07 Transitions= 4.63e+07 Memory=   414.153 t=     61.4 R=   3e+05
Depth=  335774 States=  1.9e+07 Transitions= 4.89e+07 Memory=   414.153 t=     65.1 R=   3e+05
Depth=  335774 States=    2e+07 Transitions= 5.15e+07 Memory=   414.153 t=     68.4 R=   3e+05
Depth=  335774 States=  2.1e+07 Transitions= 5.42e+07 Memory=   414.153 t=     71.7 R=   3e+05
Depth=  335774 States=  2.2e+07 Transitions= 5.66e+07 Memory=   414.153 t=     75.1 R=   3e+05
Depth=  335774 States=  2.3e+07 Transitions= 5.91e+07 Memory=   414.153 t=     78.6 R=   3e+05
Depth=  335774 States=  2.4e+07 Transitions= 6.16e+07 Memory=   414.153 t=     81.9 R=   3e+05
Depth=  335774 States=  2.5e+07 Transitions= 6.42e+07 Memory=   414.153 t=     85.5 R=   3e+05
Depth=  335774 States=  2.6e+07 Transitions= 6.66e+07 Memory=   414.153 t=     90.3 R=   3e+05
Depth=  335774 States=  2.7e+07 Transitions= 6.89e+07 Memory=   414.153 t=     94.1 R=   3e+05
Depth=  335774 States=  2.8e+07 Transitions= 7.13e+07 Memory=   414.153 t=     97.9 R=   3e+05
Depth=  335774 States=  2.9e+07 Transitions= 7.36e+07 Memory=   414.153 t=      102 R=   3e+05
Depth=  335774 States=    3e+07 Transitions=  7.6e+07 Memory=   414.153 t=      105 R=   3e+05
Depth=  335774 States=  3.1e+07 Transitions= 7.86e+07 Memory=   414.153 t=      109 R=   3e+05
Depth=  335774 States=  3.2e+07 Transitions= 8.09e+07 Memory=   414.153 t=      113 R=   3e+05
Depth=  335774 States=  3.3e+07 Transitions= 8.33e+07 Memory=   414.153 t=      117 R=   3e+05
Depth=  335774 States=  3.4e+07 Transitions= 8.57e+07 Memory=   414.153 t=      121 R=   3e+05
Depth=  335774 States=  3.5e+07 Transitions= 8.81e+07 Memory=   414.153 t=      125 R=   3e+05
Depth=  335774 States=  3.6e+07 Transitions= 9.06e+07 Memory=   414.153 t=      129 R=   3e+05
Depth=  335774 States=  3.7e+07 Transitions= 9.28e+07 Memory=   414.153 t=      134 R=   3e+05
Depth=  335774 States=  3.8e+07 Transitions=  9.5e+07 Memory=   414.153 t=      138 R=   3e+05
Depth=  335774 States=  3.9e+07 Transitions= 9.72e+07 Memory=   414.153 t=      142 R=   3e+05
Depth=  335774 States=    4e+07 Transitions= 9.94e+07 Memory=   414.153 t=      147 R=   3e+05
Depth=  335774 States=  4.1e+07 Transitions= 1.02e+08 Memory=   414.153 t=      151 R=   3e+05
Depth=  335774 States=  4.2e+07 Transitions= 1.04e+08 Memory=   414.153 t=      155 R=   3e+05
Depth=  335774 States=  4.3e+07 Transitions= 1.06e+08 Memory=   414.153 t=      160 R=   3e+05
Depth=  335774 States=  4.4e+07 Transitions= 1.08e+08 Memory=   414.153 t=      164 R=   3e+05
Depth=  335774 States=  4.5e+07 Transitions=  1.1e+08 Memory=   414.153 t=      169 R=   3e+05
Depth=  335774 States=  4.6e+07 Transitions= 1.13e+08 Memory=   414.153 t=      173 R=   3e+05
Depth=  335774 States=  4.7e+07 Transitions= 1.15e+08 Memory=   414.153 t=      177 R=   3e+05
Depth=  335774 States=  4.8e+07 Transitions= 1.17e+08 Memory=   414.153 t=      182 R=   3e+05
Depth=  335774 States=  4.9e+07 Transitions= 1.19e+08 Memory=   414.153 t=      186 R=   3e+05
Depth=  335774 States=    5e+07 Transitions= 1.21e+08 Memory=   414.153 t=      191 R=   3e+05
Depth=  335774 States=  5.1e+07 Transitions= 1.23e+08 Memory=   414.153 t=      196 R=   3e+05
Depth=  335774 States=  5.2e+07 Transitions= 1.25e+08 Memory=   414.153 t=      201 R=   3e+05
Depth=  335774 States=  5.3e+07 Transitions= 1.28e+08 Memory=   414.153 t=      205 R=   3e+05
Depth=  335774 States=  5.4e+07 Transitions=  1.3e+08 Memory=   414.153 t=      210 R=   3e+05

(Spin Version 6.2.4 -- 8 March 2013)
 + Partial Order Reduction

Bit statespace search for:
 never claim          - (not selected)
 assertion violations +
 cycle checks        - (disabled by -DSAFETY)
 invalid end states +

State-vector 184 byte, depth reached 335774, errors: 0
 54264234 states, stored
 76137809 states, matched
1.3040204e+08 transitions (= stored+matched)
    60845 atomic steps

hash factor: 2.47341 (best if > 100.)

bits set per state: 3 (-k3)

Stats on memory usage (in Megabytes):
 9729.076 equivalent memory usage for states (stored*(State-vector + overhead))
   16.000 memory used for hash array (-w27)
   16.000 memory used for bit stack
  381.470 memory used for DFS stack (-m10000000)
  414.153 total actual memory usage


unreached in proctype User
 scenario3_Ploc2.pml:51, state 17, "-end-"
 (1 of 17 states)
unreached in proctype CreditCard
 scenario3_Ploc2.pml:59, state 6, "-end-"
 (1 of 6 states)
unreached in proctype Damage
 scenario3_Ploc2.pml:69, state 8, "-end-"
 (1 of 8 states)
unreached in proctype CarEmergency
 scenario3_Ploc2.pml:141, state 54, "-end-"
 (1 of 54 states)
unreached in proctype Garage
 scenario3_Ploc2.pml:166, state 22, "-end-"
 (1 of 22 states)
unreached in proctype HandleRental
 scenario3_Ploc2.pml:189, state 14, "-end-"
 (1 of 14 states)
unreached in proctype RentalCar
 scenario3_Ploc2.pml:222, state 24, "-end-"
 (1 of 24 states)
unreached in proctype Truck
 scenario3_Ploc2.pml:256, state 32, "-end-"
 (1 of 32 states)
unreached in init
 (0 of 4 states)

pan: elapsed time 211 seconds
No errors found -- did you verify all claims?

*/
        
        



