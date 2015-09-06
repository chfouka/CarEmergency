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

														caremHandle[i] ! 1;

														caremGarage ! request, _pid;
														garageCarem ?? reply, eval(_pid), garage;														
													  
														caremTruck ! request;											
														caremTruck ? reply;
														
														/*transport and release*/
														caremTruck ! release ;
													
														/*Use garage*/

														/*Release garage*/									
														caremGarage ! release, garage;

														caremHandle[i] ? _;
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
											caremRental ? reply;

																						
											 /*use */
											
											/*release*/
											caremRental ! release ;

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



/** Invalid end states verification: esito positivo:

spin -a  scenario2.pml
gcc -DMEMLIM=1024 -O2 -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
./pan -m1000000  -c1
Pid: 2744
Depth=   61708 States=    1e+06 Transitions= 2.97e+06 Memory=   174.797	t=     6.16 R=   2e+05

(Spin Version 6.2.4 -- 8 March 2013)
	+ Partial Order Reduction

Full statespace search for:
	never claim         	- (not selected)
	assertion violations	+
	cycle checks       	- (disabled by -DSAFETY)
	invalid end states	+

State-vector 152 byte, depth reached 61708, errors: 0
  1159904 states, stored
  2325423 states, matched
  3485327 transitions (= stored+matched)
     4457 atomic steps
hash conflicts:     31834 (resolved)

Stats on memory usage (in Megabytes):
  181.412	equivalent memory usage for states (stored*(State-vector + overhead))
   88.765	actual memory usage for states (compression: 48.93%)
         	state-vector as stored = 68 byte + 12 byte overhead
   64.000	memory used for hash table (-w24)
   34.332	memory used for DFS stack (-m1000000)
  187.004	total actual memory usage


unreached in proctype User
	scenario2.pml:37, state 17, "-end-"
	(1 of 17 states)
unreached in proctype Damage
	scenario2.pml:48, state 8, "-end-"
	(1 of 8 states)
unreached in proctype CarEmergency
	scenario2.pml:93, state 29, "-end-"
	(1 of 29 states)
unreached in proctype CreditCard
	scenario2.pml:101, state 6, "-end-"
	(1 of 6 states)
unreached in proctype Garage
	scenario2.pml:113, state 7, "-end-"
	(1 of 7 states)
unreached in proctype Truck
	scenario2.pml:126, state 7, "-end-"
	(1 of 7 states)
unreached in proctype HandleRental
	scenario2.pml:146, state 9, "-end-"
	(1 of 9 states)
unreached in proctype RentalCar
	scenario2.pml:156, state 7, "-end-"
	(1 of 7 states)
unreached in init
	(0 of 4 states)

pan: elapsed time 7.25 seconds
No errors found -- did you verify all claims?


**/

