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
														:: location = Lucca; index = LU
														:: location = Pisa; index = PI
														:: location = Livorno; index =  LI
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
														:: subscriber[i] ->	 goto wantServices
														fi;
														wantServices: 

														caremCreditcard[i] ! request;
														caremCreditcard[i] ? reply;
														

														caremGarage ! request, location, _pid;
														garageCarem ?? reply, eval(_pid), garage, u;
														if 
														:: !u -> goto end																 
														:: else-> skip
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
														success: assert( garageServed[index] && truckServed[index] );
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



/*** Spin safety verification: l'assert è soddisfatta

spin -a  scenario3_Ploc1.pml
gcc -DMEMLIM=3000 -O2 -DBITSTATE -DNFAIR=5 -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
./pan -m10000000  -c1
Pid: 3636
Depth=  333982 States=    1e+06 Transitions= 2.52e+06 Memory=   414.153	t=      3.2 R=   3e+05
Depth=  333982 States=    2e+06 Transitions= 5.18e+06 Memory=   414.153	t=     6.82 R=   3e+05
Depth=  333982 States=    3e+06 Transitions=  7.9e+06 Memory=   414.153	t=     10.4 R=   3e+05
Depth=  333982 States=    4e+06 Transitions= 1.04e+07 Memory=   414.153	t=     13.5 R=   3e+05
Depth=  333982 States=    5e+06 Transitions= 1.31e+07 Memory=   414.153	t=     17.1 R=   3e+05
Depth=  333982 States=    6e+06 Transitions= 1.58e+07 Memory=   414.153	t=     20.7 R=   3e+05
Depth=  333982 States=    7e+06 Transitions= 1.84e+07 Memory=   414.153	t=     24.2 R=   3e+05
Depth=  333982 States=    8e+06 Transitions=  2.1e+07 Memory=   414.153	t=     27.4 R=   3e+05
Depth=  333982 States=    9e+06 Transitions= 2.36e+07 Memory=   414.153	t=     30.8 R=   3e+05
Depth=  333982 States=    1e+07 Transitions= 2.61e+07 Memory=   414.153	t=     34.1 R=   3e+05
Depth=  333982 States=  1.1e+07 Transitions= 2.87e+07 Memory=   414.153	t=     37.6 R=   3e+05
Depth=  333982 States=  1.2e+07 Transitions= 3.13e+07 Memory=   414.153	t=     41.1 R=   3e+05
Depth=  333982 States=  1.3e+07 Transitions= 3.38e+07 Memory=   414.153	t=     44.7 R=   3e+05
Depth=  333982 States=  1.4e+07 Transitions= 3.64e+07 Memory=   414.153	t=     48.2 R=   3e+05
Depth=  333982 States=  1.5e+07 Transitions= 3.88e+07 Memory=   414.153	t=     51.7 R=   3e+05
Depth=  333982 States=  1.6e+07 Transitions= 4.13e+07 Memory=   414.153	t=     55.1 R=   3e+05
Depth=  333982 States=  1.7e+07 Transitions= 4.37e+07 Memory=   414.153	t=     58.6 R=   3e+05
Depth=  333982 States=  1.8e+07 Transitions= 4.63e+07 Memory=   414.153	t=     62.1 R=   3e+05
Depth=  333982 States=  1.9e+07 Transitions= 4.89e+07 Memory=   414.153	t=     65.5 R=   3e+05
Depth=  333982 States=    2e+07 Transitions= 5.14e+07 Memory=   414.153	t=     68.8 R=   3e+05
Depth=  333982 States=  2.1e+07 Transitions= 5.41e+07 Memory=   414.153	t=     72.1 R=   3e+05
Depth=  333982 States=  2.2e+07 Transitions= 5.66e+07 Memory=   414.153	t=     75.6 R=   3e+05
Depth=  333982 States=  2.3e+07 Transitions=  5.9e+07 Memory=   414.153	t=     79.1 R=   3e+05
Depth=  333982 States=  2.4e+07 Transitions= 6.16e+07 Memory=   414.153	t=     82.5 R=   3e+05
Depth=  333982 States=  2.5e+07 Transitions= 6.42e+07 Memory=   414.153	t=       86 R=   3e+05
Depth=  333982 States=  2.6e+07 Transitions= 6.66e+07 Memory=   414.153	t=     89.8 R=   3e+05
Depth=  333982 States=  2.7e+07 Transitions= 6.89e+07 Memory=   414.153	t=     93.6 R=   3e+05
Depth=  333982 States=  2.8e+07 Transitions= 7.13e+07 Memory=   414.153	t=     97.5 R=   3e+05
Depth=  333982 States=  2.9e+07 Transitions= 7.36e+07 Memory=   414.153	t=      101 R=   3e+05
Depth=  333982 States=    3e+07 Transitions= 7.58e+07 Memory=   414.153	t=      106 R=   3e+05
Depth=  333982 States=  3.1e+07 Transitions= 7.81e+07 Memory=   414.153	t=      110 R=   3e+05
Depth=  333982 States=  3.2e+07 Transitions= 8.04e+07 Memory=   414.153	t=      114 R=   3e+05
Depth=  333982 States=  3.3e+07 Transitions= 8.27e+07 Memory=   414.153	t=      118 R=   3e+05
Depth=  333982 States=  3.4e+07 Transitions= 8.52e+07 Memory=   414.153	t=      122 R=   3e+05
Depth=  333982 States=  3.5e+07 Transitions= 8.75e+07 Memory=   414.153	t=      126 R=   3e+05
Depth=  333982 States=  3.6e+07 Transitions= 8.97e+07 Memory=   414.153	t=      130 R=   3e+05
Depth=  333982 States=  3.7e+07 Transitions= 9.22e+07 Memory=   414.153	t=      135 R=   3e+05
Depth=  333982 States=  3.8e+07 Transitions= 9.45e+07 Memory=   414.153	t=      139 R=   3e+05
Depth=  333982 States=  3.9e+07 Transitions= 9.69e+07 Memory=   414.153	t=      144 R=   3e+05
Depth=  333982 States=    4e+07 Transitions= 9.93e+07 Memory=   414.153	t=      149 R=   3e+05
Depth=  333982 States=  4.1e+07 Transitions= 1.02e+08 Memory=   414.153	t=      153 R=   3e+05
Depth=  333982 States=  4.2e+07 Transitions= 1.04e+08 Memory=   414.153	t=      158 R=   3e+05
Depth=  333982 States=  4.3e+07 Transitions= 1.06e+08 Memory=   414.153	t=      162 R=   3e+05
Depth=  333982 States=  4.4e+07 Transitions= 1.08e+08 Memory=   414.153	t=      167 R=   3e+05
Depth=  333982 States=  4.5e+07 Transitions=  1.1e+08 Memory=   414.153	t=      171 R=   3e+05
Depth=  333982 States=  4.6e+07 Transitions= 1.12e+08 Memory=   414.153	t=      176 R=   3e+05
Depth=  333982 States=  4.7e+07 Transitions= 1.15e+08 Memory=   414.153	t=      180 R=   3e+05
Depth=  333982 States=  4.8e+07 Transitions= 1.17e+08 Memory=   414.153	t=      185 R=   3e+05
Depth=  333982 States=  4.9e+07 Transitions= 1.19e+08 Memory=   414.153	t=      189 R=   3e+05
Depth=  333982 States=    5e+07 Transitions= 1.21e+08 Memory=   414.153	t=      194 R=   3e+05
Depth=  333982 States=  5.1e+07 Transitions= 1.23e+08 Memory=   414.153	t=      198 R=   3e+05
Depth=  333982 States=  5.2e+07 Transitions= 1.25e+08 Memory=   414.153	t=      203 R=   3e+05
Depth=  333982 States=  5.3e+07 Transitions= 1.27e+08 Memory=   414.153	t=      207 R=   3e+05
Depth=  333982 States=  5.4e+07 Transitions=  1.3e+08 Memory=   414.153	t=      212 R=   3e+05

(Spin Version 6.2.4 -- 8 March 2013)
	+ Partial Order Reduction

Bit statespace search for:
	never claim         	- (not selected)
	assertion violations	+
	cycle checks       	- (disabled by -DSAFETY)
	invalid end states	+

State-vector 188 byte, depth reached 333982, errors: 0
 54833257 states, stored
 76726611 states, matched
1.3155987e+08 transitions (= stored+matched)
    68577 atomic steps

hash factor: 2.44774 (best if > 100.)

bits set per state: 3 (-k3)

Stats on memory usage (in Megabytes):
10040.269	equivalent memory usage for states (stored*(State-vector + overhead))
   16.000	memory used for hash array (-w27)
   16.000	memory used for bit stack
  381.470	memory used for DFS stack (-m10000000)
  414.153	total actual memory usage


unreached in proctype User
	scenario3_Ploc1.pml:46, state 17, "-end-"
	(1 of 17 states)
unreached in proctype Damage
	scenario3_Ploc1.pml:58, state 8, "-end-"
	(1 of 8 states)
unreached in proctype CarEmergency
	scenario3_Ploc1.pml:120, state 54, "-end-"
	(1 of 54 states)
unreached in proctype CreditCard
	scenario3_Ploc1.pml:128, state 6, "-end-"
	(1 of 6 states)
unreached in proctype Garage
	scenario3_Ploc1.pml:153, state 22, "-end-"
	(1 of 22 states)
unreached in proctype Truck
	scenario3_Ploc1.pml:189, state 32, "-end-"
	(1 of 32 states)
unreached in proctype HandleRental
	scenario3_Ploc1.pml:213, state 14, "-end-"
	(1 of 14 states)
unreached in proctype RentalCar
	scenario3_Ploc1.pml:245, state 24, "-end-"
	(1 of 24 states)
unreached in init
	(0 of 4 states)

pan: elapsed time 216 seconds
No errors found -- did you verify all claims?


*/


