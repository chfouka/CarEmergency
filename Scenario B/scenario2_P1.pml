bool subscriber[2] = false;
mtype = { request, reply, release, damage };	

chan caremUser[2] = [0] of { mtype, bit };
chan caremDamage[2] = [0] of { mtype };
chan caremCreditcard[2] = [0] of { mtype }; 
chan caremTruck = [0] of {mtype}
chan caremHandle[2] = [0] of {bit}
chan caremRental = [0] of {mtype}

chan caremGarage = [2] of { mtype, byte };	
chan garageCarem = [2] of {mtype, byte, byte};

byte numUtentiTruck = 0;
byte numUtentiGarage1 = 0;
byte numUtentiGarage2 = 0;
byte numUtentiRental = 0;
/*le seguenti variabili inizializzate a 0 causano un errore nell'invariante:
	vengono inizializzate a 256 perché nel sistema ci meno di 256 processi attivi
*/
byte pidGarage1 = 256;
byte pidGarage2 = 256;


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

proctype CreditCard( bit i ){
	end:
	do
	:: caremCreditcard[i] ? request-> caremCreditcard[i] ! reply
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
	bit u;
	byte garage;
	byte truck;
	run HandleRental( i );

	end:
	do
	:: caremDamage[i] ? damage ->
														if
														:: !subscriber[i] ->
																						caremUser[i] ! request( 1 ) ;
																						caremUser[i] ? reply( u );
																						if
																						:: !u -> goto end
																						::  u -> goto wantServices
																						fi	
														:: subscriber[i] ->	 goto wantServices
														fi;
														wantServices: 
														caremCreditcard[i] ! request;
														caremCreditcard[i] ? reply;

														caremGarage ! request, _pid;
														atomic{
														garageCarem ?? reply, eval(_pid), garage;														
													  if 
														::( garage == pidGarage1 )-> numUtentiGarage1 ++
														:: else -> numUtentiGarage2 ++ 
														fi;
														}

														caremHandle[i] ! 1;

														caremTruck ! request;
														atomic{
														caremTruck ? reply;
														numUtentiTruck ++;}


														/*transport and release*/
														atomic{
														numUtentiTruck --;
														caremTruck ! release ;
														}
														/*Use garage*/

														/*Release garage*/
														atomic{
														if 
														::( garage == pidGarage1 )-> numUtentiGarage1 --
														:: else -> numUtentiGarage2 -- 
														fi;
														caremGarage ! release, garage;
														}
														caremHandle[i] ? _;
	od

}



active [2] proctype Garage( ){
	byte ideCarem;

	atomic{
	if :: ( pidGarage1 == 256  )	-> pidGarage1 = _pid :: else -> pidGarage2 = _pid fi
	};

	end:
	do
	::caremGarage ? request, ideCarem -> 
																	 garageCarem ! reply, ideCarem, _pid ;
																	 caremGarage ?? release, eval(_pid) ; 
	od
}


active proctype Truck( ){
	end:
	do
	::caremTruck ? request -> 
													 caremTruck ! reply;
													 caremTruck ? release; 
	od

}


proctype HandleRental( bit i ){
	end:
	do
	::caremHandle[i] ? _ ->
											caremRental ! request ;
											atomic {
											caremRental ? reply;
											numUtentiRental ++
											};
																						
											 /*use */
											
											/*release*/
											atomic{
											numUtentiRental --;
											caremRental ! release ;
											}
											/*synch with CarEmergency*/
											caremHandle[i] ! 1;
	od
}

active proctype RentalCar( ){

	end:
	do
	:: caremRental ? request -> caremRental ! reply; 
															caremRental ? release ; 
	od
}



init{
	atomic{
		run User( 0 ); 
		run User( 1 );
	}

}

active proctype invariant( ){
do
:: assert ( numUtentiGarage1 <= 1 && numUtentiGarage2 <= 1 && numUtentiRental <= 1 && numUtentiTruck <=1 )
od

}


/** Spin safety verification: nessun errore trovato, invariante soddisfatto

spin -a  scenario2_P1.pml
gcc -DMEMLIM=1024 -O2 -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
./pan -m1000000  -c1
Pid: 2859

(Spin Version 6.2.4 -- 8 March 2013)
	+ Partial Order Reduction

Full statespace search for:
	never claim         	- (not selected)
	assertion violations	+
	cycle checks       	- (disabled by -DSAFETY)
	invalid end states	+

State-vector 164 byte, depth reached 21358, errors: 0
   554341 states, stored
  1224806 states, matched
  1779147 transitions (= stored+matched)
   165297 atomic steps
hash conflicts:      7731 (resolved)

Stats on memory usage (in Megabytes):
   93.044	equivalent memory usage for states (stored*(State-vector + overhead))
   46.790	actual memory usage for states (compression: 50.29%)
         	state-vector as stored = 77 byte + 12 byte overhead
   64.000	memory used for hash table (-w24)
   34.332	memory used for DFS stack (-m1000000)
  145.012	total actual memory usage


unreached in proctype User
	scenario2_P1.pml:46, state 17, "-end-"
	(1 of 17 states)
unreached in proctype CreditCard
	scenario2_P1.pml:54, state 6, "-end-"
	(1 of 6 states)
unreached in proctype Damage
	scenario2_P1.pml:64, state 8, "-end-"
	(1 of 8 states)
unreached in proctype CarEmergency
	scenario2_P1.pml:125, state 47, "-end-"
	(1 of 47 states)
unreached in proctype Garage
	scenario2_P1.pml:142, state 14, "-end-"
	(1 of 14 states)
unreached in proctype Truck
	scenario2_P1.pml:153, state 7, "-end-"
	(1 of 7 states)
unreached in proctype HandleRental
	scenario2_P1.pml:176, state 13, "-end-"
	(1 of 13 states)
unreached in proctype RentalCar
	scenario2_P1.pml:185, state 7, "-end-"
	(1 of 7 states)
unreached in init
	(0 of 4 states)
unreached in proctype invariant
	scenario2_P1.pml:202, state 5, "-end-"
	(1 of 5 states)

pan: elapsed time 3.92 seconds
No errors found -- did you verify all claims?


*/


