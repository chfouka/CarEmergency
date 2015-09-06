bool subscriber = false;

mtype = { request, reply, release, damage }; 

chan caremUser = [0] of { mtype, bit };
chan caremDamage = [0] of { mtype };
chan caremCreditcard = [0] of {mtype}; 
chan caremGarage = [0] of {mtype, bit}; 
chan caremTruck = [0] of {mtype, bit}; 
chan caremRental = [0] of {mtype, bit};
chan caremHandle = [0] of { bit };

bool busyGarage = true; /*le busy all'inizio devono essere true senno' proprietà assert non si soddisfa.*/
bool busyTruck = true;
bool busyRental = true;

init{
 run User();
}


proctype User( ) {

 if
 :: subscriber = 0
 :: subscriber = 1
 fi;

 atomic{
  run CarEmergency( );
  run Damage( );
  run CreditCard( );
  run Truck( );
  run Garage( );
  run HandleRental( );
  run RentalCar( );
 }
 
 if
 :: !subscriber -> end: caremUser ? request,_ ;
              if
              :: caremUser ! reply( 1 ) 
              :: caremUser ! reply( 0 ) 
              fi
 :: else ->skip
 fi
} 


proctype Damage( ){
 if
 :: caremDamage ! damage;
 :: skip
 fi
}



proctype CarEmergency( ){
 bit x;
 bit y; 
 end:
  caremDamage ? damage -> 
            if
            :: !subscriber ->
                    caremUser ! request( 1 ) ;
                    caremUser ? reply( x );
                    if
                    :: !x -> goto endfail1
                    ::  x -> goto wantServices                                  
                    fi 

            :: subscriber -> goto wantServices;
            fi;
            wantServices:

            caremCreditcard ! request;
            caremCreditcard ? reply;   
                       
            caremGarage ! request( 1 );
            caremGarage ? reply( x ); 
            if
            :: !x -> goto endfail
            :: else -> skip
            fi;   
            
            caremHandle ! 1;                            

            caremTruck ! request( 1 );
            caremTruck ? reply( y );
            if
            :: !y && x -> caremGarage ! release( 1 );  caremHandle ? _ ; goto endfail
            :: else -> skip
            fi;
            /*use services*/


            /*release services*/                                    
            caremGarage ! release( 1 );
            caremTruck ! release ( 1 );                           
            caremHandle ? _ ;                                             
            goto success;
 
 endfail1:
 goto endend;

 endfail:
 assert(busyGarage || busyTruck );
 goto endend;  

 success: skip;               

 endend:
 skip
}

proctype CreditCard( ) { 
 end:
 caremCreditcard ? request ->  caremCreditcard ! reply
                
}


proctype Garage(  ){
 bit x;

 if
 :: busyGarage = 0
 :: busyGarage = 1
 fi;

 end:
 caremGarage ? request, x ->
              
                
                  if
                  :: busyGarage -> caremGarage ! reply( 0 )
                  :: !busyGarage ->   caremGarage ! reply ( 1 );
                            caremGarage ? release, _ ;                              
                  fi
              
}

proctype Truck( ){
 bit x;

 if
 ::busyTruck = 0
 ::busyTruck = 1
 fi;

 end:
 caremTruck ? request, x ->
                  if
                  :: busyTruck -> caremTruck ! reply( 0 )
                  :: !busyTruck ->  caremTruck ! reply ( 1 ); 
                           caremTruck ? release, _ ; 
                  fi

}

proctype HandleRental( ){
 bit y;
  end:
 caremHandle ? _ -> 
          caremRental ! request( 1 );
          caremRental ? reply( y );              
          if
          :: !y -> caremHandle ! 0; goto endend
          :: else ->  skip
          fi; 
          /* use, release, synchronize */

          caremRental ! release( 1 );
          caremHandle ! 1;


 endend: skip
}


proctype RentalCar( ){
 bit x;

 if
 :: busyRental = 0
 :: busyRental = 1
 fi;
 

 end:
 caremRental ? request, x ->
             
            
                 if
                 :: busyRental -> caremRental ! reply( 0 )
                 :: !busyRental -> caremRental ! reply ( 1 );
                          caremRental ? release, _; 
                 fi
}





/*** Spin safety verification: assert non violata

spin -a  scenario1_P2.pml
gcc -DMEMLIM=1024 -O2  -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
./pan -m10000  -c1
Pid: 4619

(Spin Version 6.2.4 -- 8 March 2013)
 + Partial Order Reduction

Full statespace search for:
 never claim          - (not selected)
 assertion violations +
 cycle checks        - (disabled by -DSAFETY)
 invalid end states +

State-vector 96 byte, depth reached 68, errors: 0
     2201 states, stored
     2276 states, matched
     4477 transitions (= stored+matched)
       12 atomic steps
hash conflicts:         0 (resolved)

Stats on memory usage (in Megabytes):
    0.227 equivalent memory usage for states (stored*(State-vector + overhead))
    0.282 actual memory usage for states
   64.000 memory used for hash table (-w24)
    0.343 memory used for DFS stack (-m10000)
   64.539 total actual memory usage


unreached in init
 (0 of 2 states)
unreached in proctype User
 (0 of 23 states)
unreached in proctype Damage
 (0 of 5 states)
unreached in proctype CarEmergency
 (0 of 46 states)
unreached in proctype CreditCard
 (0 of 3 states)
unreached in proctype Garage
 (0 of 13 states)
unreached in proctype Truck
 (0 of 13 states)
unreached in proctype HandleRental
 (0 of 14 states)
unreached in proctype RentalCar
 (0 of 13 states)

pan: elapsed time 0.01 seconds
No errors found -- did you verify all claims?

*/
