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

byte numUtentiTruck = 0;
byte numUtentiGarage1 = 0;
byte numUtentiGarage2 = 0;
byte numUtentiRental = 0;
/*Lasciare il valore iniziale a 0 non va bene
Nel modello non si raggiungono mai 256 processi attivi.*/
byte pidGarage1 = 256 ; 
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
														:: subscriber[i] ->	 goto wantServices
														fi;
														wantServices: 

														caremCreditcard[i] ! request;
														caremCreditcard[i] ? reply;
														

														caremGarage ! request, location, _pid;
														atomic {
														garageCarem ?? reply, eval(_pid), garage, u;
														if 
														:: !u -> goto end																 
														:: else-> skip
														fi;
			  										if 
														::( garage == pidGarage1 )-> numUtentiGarage1 ++
														:: else -> numUtentiGarage2 ++ 
														fi;
														}

														caremHandle[i] ! location, 1;

														caremTruck ! request, location;
														atomic{
														caremTruck ? reply, u;
														if 
														:: !u -> caremHandle[i] ? _, _; 
																		if :: ( garage == pidGarage1 ) -> numUtentiGarage1 -- 
																			 :: else -> numUtentiGarage2 -- 
																		fi;
																		caremGarage ! release, location, garage; 
																		goto end
														:: else-> numUtentiTruck ++;
														fi;
														}
													  /*transport and release*/
														atomic{
														numUtentiTruck --;
													  caremTruck ! release, 1 ;
														}
														/*Use garage*/

														/*Release garage*/
														atomic{
														if 
														::( garage == pidGarage1 )-> numUtentiGarage1 --
														:: else -> numUtentiGarage2 -- 
														fi;
														caremGarage ! release, location, garage;
														}

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

	
	atomic{
	if :: ( pidGarage1 == 256  )	-> pidGarage1 = _pid :: else -> pidGarage2 = _pid fi
	};
	
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
											atomic{
											caremRental ? reply, r;
											if 
											:: !r -> caremHandle[i] ! loCarem, 1; goto end
											:: else -> numUtentiRental ++
											fi
											};
										 /*use */
								
										 /*release*/
										 atomic{
										 numUtentiRental -- ;
										 caremRental ! release, loCarem ;
										 }
								
									   /*synch with CarEmergency*/
									   caremHandle[i] ! loCarem, 1;
							
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

active proctype invariant( ){
do
:: assert ( numUtentiGarage1 <= 1 && numUtentiGarage2 <= 1 && numUtentiRental <= 1 && numUtentiTruck <=1 )
od

}


/** Spin safety verification: nessun errore trovato, invariante soddisfatto

spin -a  scenario3_P1.pml
gcc -DMEMLIM=2048  -O2 -DBITSTATE -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
./pan -m10000000  -c1
Pid: 2330
Depth=  330666 States=    1e+06 Transitions= 3.02e+06 Memory=   413.860	t=     3.86 R=   3e+05
Depth=  699435 States=    2e+06 Transitions= 5.58e+06 Memory=   414.349	t=     7.79 R=   3e+05
Depth= 1208164 States=    3e+06 Transitions=  8.3e+06 Memory=   414.739	t=     11.1 R=   3e+05
Depth= 1619849 States=    4e+06 Transitions= 1.12e+07 Memory=   415.130	t=     14.6 R=   3e+05
Depth= 1864578 States=    5e+06 Transitions= 1.42e+07 Memory=   415.228	t=       18 R=   3e+05
Depth= 2151174 States=    6e+06 Transitions= 1.73e+07 Memory=   415.423	t=     21.4 R=   3e+05
Depth= 2332534 States=    7e+06 Transitions= 2.02e+07 Memory=   415.618	t=     24.6 R=   3e+05
Depth= 2332830 States=    8e+06 Transitions= 2.33e+07 Memory=   415.618	t=     28.1 R=   3e+05
Depth= 2332830 States=    9e+06 Transitions=  2.7e+07 Memory=   415.618	t=     32.4 R=   3e+05
Depth= 2332830 States=    1e+07 Transitions= 3.08e+07 Memory=   415.618	t=     37.9 R=   3e+05
Depth= 2332830 States=  1.1e+07 Transitions= 3.35e+07 Memory=   415.618	t=     41.2 R=   3e+05
Depth= 2332830 States=  1.2e+07 Transitions= 3.63e+07 Memory=   415.618	t=     44.6 R=   3e+05
Depth= 2332830 States=  1.3e+07 Transitions= 3.92e+07 Memory=   415.618	t=     47.9 R=   3e+05
Depth= 2332830 States=  1.4e+07 Transitions= 4.22e+07 Memory=   415.618	t=     51.2 R=   3e+05
Depth= 2332830 States=  1.5e+07 Transitions= 4.54e+07 Memory=   415.618	t=     54.9 R=   3e+05
Depth= 2332830 States=  1.6e+07 Transitions= 4.89e+07 Memory=   415.618	t=     59.3 R=   3e+05
Depth= 2332830 States=  1.7e+07 Transitions= 5.28e+07 Memory=   415.618	t=     64.6 R=   3e+05
Depth= 2332830 States=  1.8e+07 Transitions= 5.53e+07 Memory=   415.618	t=     68.3 R=   3e+05
Depth= 2332830 States=  1.9e+07 Transitions=  5.8e+07 Memory=   415.618	t=     71.8 R=   3e+05
Depth= 2332830 States=    2e+07 Transitions=  6.1e+07 Memory=   415.618	t=     75.2 R=   3e+05
Depth= 2332830 States=  2.1e+07 Transitions=  6.4e+07 Memory=   415.618	t=     78.9 R=   3e+05
Depth= 2332830 States=  2.2e+07 Transitions= 6.71e+07 Memory=   415.618	t=     82.8 R=   3e+05
Depth= 2332830 States=  2.3e+07 Transitions=  7.1e+07 Memory=   415.618	t=     88.1 R=   3e+05
Depth= 2332830 States=  2.4e+07 Transitions= 7.38e+07 Memory=   415.618	t=     92.1 R=   3e+05
Depth= 2332830 States=  2.5e+07 Transitions= 7.68e+07 Memory=   415.618	t=     96.2 R=   3e+05
Depth= 2332830 States=  2.6e+07 Transitions= 7.97e+07 Memory=   415.618	t=      100 R=   3e+05
Depth= 2332830 States=  2.7e+07 Transitions= 8.25e+07 Memory=   415.618	t=      104 R=   3e+05
Depth= 2332830 States=  2.8e+07 Transitions= 8.54e+07 Memory=   415.618	t=      108 R=   3e+05
Depth= 2332830 States=  2.9e+07 Transitions= 8.86e+07 Memory=   415.618	t=      112 R=   3e+05
Depth= 2332830 States=    3e+07 Transitions= 9.13e+07 Memory=   415.618	t=      116 R=   3e+05
Depth= 2332830 States=  3.1e+07 Transitions= 9.41e+07 Memory=   415.618	t=      119 R=   3e+05
Depth= 2332830 States=  3.2e+07 Transitions= 9.71e+07 Memory=   415.618	t=      123 R=   3e+05
Depth= 2332830 States=  3.3e+07 Transitions= 1.01e+08 Memory=   415.618	t=      128 R=   3e+05
Depth= 2332830 States=  3.4e+07 Transitions= 1.04e+08 Memory=   415.618	t=      132 R=   3e+05
Depth= 2332830 States=  3.5e+07 Transitions= 1.07e+08 Memory=   415.618	t=      137 R=   3e+05
Depth= 2332830 States=  3.6e+07 Transitions=  1.1e+08 Memory=   415.618	t=      141 R=   3e+05
Depth= 2332830 States=  3.7e+07 Transitions= 1.13e+08 Memory=   415.618	t=      146 R=   3e+05
Depth= 2332830 States=  3.8e+07 Transitions= 1.16e+08 Memory=   415.618	t=      150 R=   3e+05
Depth= 2332830 States=  3.9e+07 Transitions= 1.19e+08 Memory=   415.618	t=      155 R=   3e+05
Depth= 2332830 States=    4e+07 Transitions= 1.22e+08 Memory=   415.618	t=      160 R=   3e+05
Depth= 2332830 States=  4.1e+07 Transitions= 1.25e+08 Memory=   415.618	t=      164 R=   2e+05
Depth= 2332830 States=  4.2e+07 Transitions= 1.28e+08 Memory=   415.618	t=      169 R=   2e+05
Depth= 2332830 States=  4.3e+07 Transitions= 1.31e+08 Memory=   415.618	t=      174 R=   2e+05
Depth= 2332830 States=  4.4e+07 Transitions= 1.34e+08 Memory=   415.618	t=      179 R=   2e+05
Depth= 2332830 States=  4.5e+07 Transitions= 1.37e+08 Memory=   415.618	t=      184 R=   2e+05
Depth= 2332830 States=  4.6e+07 Transitions= 1.41e+08 Memory=   415.618	t=      189 R=   2e+05
Depth= 2332830 States=  4.7e+07 Transitions= 1.44e+08 Memory=   415.618	t=      195 R=   2e+05
Depth= 2332830 States=  4.8e+07 Transitions= 1.47e+08 Memory=   415.618	t=      200 R=   2e+05
Depth= 2332830 States=  4.9e+07 Transitions=  1.5e+08 Memory=   415.618	t=      205 R=   2e+05
Depth= 2332830 States=    5e+07 Transitions= 1.53e+08 Memory=   415.618	t=      210 R=   2e+05
Depth= 2332830 States=  5.1e+07 Transitions= 1.56e+08 Memory=   415.618	t=      216 R=   2e+05
Depth= 2332830 States=  5.2e+07 Transitions= 1.59e+08 Memory=   415.618	t=      221 R=   2e+05
Depth= 2332830 States=  5.3e+07 Transitions= 1.62e+08 Memory=   415.618	t=      226 R=   2e+05
Depth= 2332830 States=  5.4e+07 Transitions= 1.65e+08 Memory=   415.618	t=      232 R=   2e+05
Depth= 2332830 States=  5.5e+07 Transitions= 1.68e+08 Memory=   415.618	t=      237 R=   2e+05

(Spin Version 6.2.4 -- 8 March 2013)
	+ Partial Order Reduction

Bit statespace search for:
	never claim         	- (not selected)
	assertion violations	+
	cycle checks       	- (disabled by -DSAFETY)
	invalid end states	+

State-vector 192 byte, depth reached 2332830, errors: 0
 55242614 states, stored
1.1346031e+08 states, matched
1.6870292e+08 transitions (= stored+matched)
  8232687 atomic steps

hash factor: 2.4296 (best if > 100.)

bits set per state: 3 (-k3)

Stats on memory usage (in Megabytes):
10325.959	equivalent memory usage for states (stored*(State-vector + overhead))
   16.000	memory used for hash array (-w27)
   16.000	memory used for bit stack
  381.470	memory used for DFS stack (-m10000000)
    2.071	other (proc and chan stacks)
  415.618	total actual memory usage


unreached in proctype User
	scenario3_P1.pml:44, state 17, "-end-"
	(1 of 17 states)
unreached in proctype Damage
	scenario3_P1.pml:56, state 8, "-end-"
	(1 of 8 states)
unreached in proctype CarEmergency
	scenario3_P1.pml:138, state 72, "-end-"
	(1 of 72 states)
unreached in proctype CreditCard
	scenario3_P1.pml:147, state 6, "-end-"
	(1 of 6 states)
unreached in proctype Garage
	scenario3_P1.pml:178, state 25, "-end-"
	(1 of 25 states)
unreached in proctype Truck
	scenario3_P1.pml:213, state 24, "-end-"
	(1 of 24 states)
unreached in proctype HandleRental
	scenario3_P1.pml:243, state 19, "-end-"
	(1 of 19 states)
unreached in proctype RentalCar
	scenario3_P1.pml:275, state 24, "-end-"
	(1 of 24 states)
unreached in init
	(0 of 4 states)
unreached in proctype invariant
	scenario3_P1.pml:292, state 5, "-end-"
	(1 of 5 states)

pan: elapsed time 239 seconds
No errors found -- did you verify all claims?


*/
