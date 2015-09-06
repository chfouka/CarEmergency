bool subscriber[2] = false;
mtype = { Pisa, Livorno, Lucca, Firenze };
mtype = { request, reply, release, damage }; 

chan caremUser[2] = [0] of { mtype, bit };
chan caremDamage[2] = [0] of { mtype };
chan caremCreditcard[2] = [0] of { mtype }; 
chan caremTruck = [0] of {mtype, mtype}
chan caremHandle[2] = [0] of {mtype, bit}
chan caremRental = [0] of {mtype, mtype}

chan caremGarage = [2] of { mtype, mtype, byte }; 
chan garageCarem = [2] of {mtype, byte, byte, bit};

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
 bit u;
 byte garage;
 run HandleRental( i );

 end:
 do
 :: caremDamage[i] ? damage ->
              if
              :: location = Lucca
              :: location = Pisa
              :: location = Livorno
              :: location = Firenze
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
              :: !u -> goto end                 
              :: else->skip
              fi;

              caremHandle[i] ! location, 1;              
   
              caremTruck ! request, location;
              caremTruck ? reply, u;
              if 
              :: !u -> caremHandle[i] ? _, _; caremGarage ! release, location, garage; goto end
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
 :: location = Lucca
 :: location = Pisa
 :: location = Livorno
 :: location = Firenze
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
 byte loCarem;
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



/***** Invalid end state verification: risultato positivo   


spin -a  scenario3.pml
gcc -DMEMLIM=2048  -O2 -DBITSTATE -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
./pan -m10000000  -c1
Pid: 2499
Depth=  316837 States=    1e+06 Transitions= 2.53e+06 Memory=   413.860 t=     3.25 R=   3e+05
Depth=  316837 States=    2e+06 Transitions=  5.2e+06 Memory=   413.860 t=     6.85 R=   3e+05
Depth=  316837 States=    3e+06 Transitions= 7.74e+06 Memory=   413.958 t=     10.3 R=   3e+05
Depth=  316837 States=    4e+06 Transitions= 1.02e+07 Memory=   413.958 t=     13.6 R=   3e+05
Depth=  316837 States=    5e+06 Transitions= 1.28e+07 Memory=   413.958 t=       17 R=   3e+05
Depth=  316837 States=    6e+06 Transitions= 1.52e+07 Memory=   413.958 t=     20.2 R=   3e+05
Depth=  316837 States=    7e+06 Transitions= 1.78e+07 Memory=   413.958 t=     25.1 R=   3e+05
Depth=  316837 States=    8e+06 Transitions= 2.03e+07 Memory=   413.958 t=     28.5 R=   3e+05
Depth=  316837 States=    9e+06 Transitions= 2.27e+07 Memory=   413.958 t=     31.8 R=   3e+05
Depth=  316837 States=    1e+07 Transitions= 2.52e+07 Memory=   413.958 t=       35 R=   3e+05
Depth=  316837 States=  1.1e+07 Transitions= 2.79e+07 Memory=   413.958 t=     38.7 R=   3e+05
Depth=  316837 States=  1.2e+07 Transitions= 3.04e+07 Memory=   413.958 t=       42 R=   3e+05
Depth=  316837 States=  1.3e+07 Transitions= 3.29e+07 Memory=   413.958 t=     45.5 R=   3e+05
Depth=  316837 States=  1.4e+07 Transitions= 3.54e+07 Memory=   413.958 t=     48.8 R=   3e+05
Depth=  316837 States=  1.5e+07 Transitions= 3.79e+07 Memory=   413.958 t=     52.2 R=   3e+05
Depth=  316837 States=  1.6e+07 Transitions= 4.02e+07 Memory=   413.958 t=     55.5 R=   3e+05
Depth=  316837 States=  1.7e+07 Transitions= 4.27e+07 Memory=   413.958 t=     58.9 R=   3e+05
Depth=  323781 States=  1.8e+07 Transitions= 4.49e+07 Memory=   413.958 t=     62.2 R=   3e+05
Depth=  688157 States=  1.9e+07 Transitions= 4.73e+07 Memory=   414.251 t=     65.2 R=   3e+05
Depth=  718811 States=    2e+07 Transitions= 4.99e+07 Memory=   414.251 t=     68.5 R=   3e+05
Depth=  718811 States=  2.1e+07 Transitions= 5.26e+07 Memory=   414.251 t=     72.4 R=   3e+05
Depth=  718811 States=  2.2e+07 Transitions= 5.51e+07 Memory=   414.251 t=     75.8 R=   3e+05
Depth=  718811 States=  2.3e+07 Transitions= 5.73e+07 Memory=   414.251 t=     79.2 R=   3e+05
Depth=  718811 States=  2.4e+07 Transitions= 5.99e+07 Memory=   414.251 t=       84 R=   3e+05
Depth=  718811 States=  2.5e+07 Transitions= 6.22e+07 Memory=   414.251 t=       88 R=   3e+05
Depth=  718811 States=  2.6e+07 Transitions= 6.45e+07 Memory=   414.251 t=     91.5 R=   3e+05
Depth=  718811 States=  2.7e+07 Transitions=  6.7e+07 Memory=   414.251 t=     95.3 R=   3e+05
Depth=  718811 States=  2.8e+07 Transitions= 6.92e+07 Memory=   414.251 t=       99 R=   3e+05
Depth=  718811 States=  2.9e+07 Transitions= 7.14e+07 Memory=   414.251 t=      103 R=   3e+05
Depth=  718811 States=    3e+07 Transitions= 7.38e+07 Memory=   414.251 t=      107 R=   3e+05
Depth=  718811 States=  3.1e+07 Transitions= 7.62e+07 Memory=   414.251 t=      111 R=   3e+05
Depth=  718811 States=  3.2e+07 Transitions= 7.85e+07 Memory=   414.251 t=      115 R=   3e+05
Depth=  718811 States=  3.3e+07 Transitions= 8.07e+07 Memory=   414.251 t=      118 R=   3e+05
Depth=  718811 States=  3.4e+07 Transitions= 8.29e+07 Memory=   414.251 t=      122 R=   3e+05
Depth=  718811 States=  3.5e+07 Transitions= 8.51e+07 Memory=   414.251 t=      126 R=   3e+05
Depth=  718811 States=  3.6e+07 Transitions= 8.73e+07 Memory=   414.251 t=      130 R=   3e+05
Depth=  718811 States=  3.7e+07 Transitions= 8.96e+07 Memory=   414.251 t=      135 R=   3e+05
Depth=  718811 States=  3.8e+07 Transitions= 9.18e+07 Memory=   414.251 t=      139 R=   3e+05
Depth=  718811 States=  3.9e+07 Transitions= 9.39e+07 Memory=   414.251 t=      143 R=   3e+05
Depth=  718811 States=    4e+07 Transitions= 9.61e+07 Memory=   414.251 t=      148 R=   3e+05
Depth=  718811 States=  4.1e+07 Transitions= 9.82e+07 Memory=   414.251 t=      153 R=   3e+05
Depth=  718811 States=  4.2e+07 Transitions=    1e+08 Memory=   414.251 t=      157 R=   3e+05
Depth=  718811 States=  4.3e+07 Transitions= 1.03e+08 Memory=   414.251 t=      161 R=   3e+05
Depth=  718811 States=  4.4e+07 Transitions= 1.05e+08 Memory=   414.251 t=      165 R=   3e+05
Depth=  718811 States=  4.5e+07 Transitions= 1.07e+08 Memory=   414.251 t=      170 R=   3e+05
Depth=  718811 States=  4.6e+07 Transitions= 1.09e+08 Memory=   414.251 t=      174 R=   3e+05
Depth=  718811 States=  4.7e+07 Transitions= 1.11e+08 Memory=   414.251 t=      179 R=   3e+05
Depth=  718811 States=  4.8e+07 Transitions= 1.13e+08 Memory=   414.251 t=      183 R=   3e+05
Depth=  718811 States=  4.9e+07 Transitions= 1.15e+08 Memory=   414.251 t=      188 R=   3e+05
Depth=  718811 States=    5e+07 Transitions= 1.17e+08 Memory=   414.251 t=      192 R=   3e+05

(Spin Version 6.2.4 -- 8 March 2013)
 + Partial Order Reduction

Bit statespace search for:
 never claim          - (not selected)
 assertion violations +
 cycle checks        - (disabled by -DSAFETY)
 invalid end states +

State-vector 180 byte, depth reached 718811, errors: 0
 50821105 states, stored
 68133163 states, matched
1.1895427e+08 transitions (= stored+matched)
    16247 atomic steps

hash factor: 2.64098 (best if > 100.)

bits set per state: 3 (-k3)

Stats on memory usage (in Megabytes):
 8917.888 equivalent memory usage for states (stored*(State-vector + overhead))
   16.000 memory used for hash array (-w27)
   16.000 memory used for bit stack
  381.470 memory used for DFS stack (-m10000000)
  414.251 total actual memory usage


unreached in proctype User
 scenario3.pml:36, state 17, "-end-"
 (1 of 17 states)
unreached in proctype Damage
 scenario3.pml:48, state 8, "-end-"
 (1 of 8 states)
unreached in proctype CarEmergency
 scenario3.pml:107, state 49, "-end-"
 (1 of 49 states)
unreached in proctype CreditCard
 scenario3.pml:115, state 6, "-end-"
 (1 of 6 states)
unreached in proctype Garage
 scenario3.pml:141, state 18, "-end-"
 (1 of 18 states)
unreached in proctype Truck
 scenario3.pml:176, state 24, "-end-"
 (1 of 24 states)
unreached in proctype HandleRental
 scenario3.pml:201, state 14, "-end-"
 (1 of 14 states)
unreached in proctype RentalCar
 scenario3.pml:234, state 24, "-end-"
 (1 of 24 states)
unreached in init
 (0 of 4 states)

pan: elapsed time 196 seconds
No errors found -- did you verify all claims?


**/
