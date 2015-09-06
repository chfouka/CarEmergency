bool subscriber = false;
bool authorization = false;

mtype = { request, reply, release, damage };	
chan caremUser = [0] of { mtype, bit };

chan caremDamage = [0] of { mtype };
chan caremHandle = [0] of { bit };
chan caremRental = [0] of { mtype, bit };

chan caremCreditcard = [0] of { mtype}; 
chan caremGarage[2] = [0] of { mtype, bit };
chan caremTruck[2] = [0] of { mtype, bit };	



bool busyGarage[2] = true; /*le busy all'inizio devono essere true senno' proprietà 2 non si soddisfa.*/
bool busyTruck[2] = true;
bool busyRental = true;
bool prenotatoGarage[2];
bool prenotatoTruck[2];
bool prenotatoRental;


#define busygarage (busyGarage[0] && busyGarage[1])
#define busytruck ( busyTruck[0] && busyTruck[1] )

#define prenotatogarage ( prenotatoGarage[0] || prenotatoGarage[1] )
#define prenotatotruck ( prenotatoTruck[0] || prenotatoTruck[1] )

init{
	run User( );
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
		run Truck( 0 );
		run Truck( 1 );
		run Garage( 0 );
		run Garage( 1 );
		run HandleRental( );
		run RentalCar( );
	}
	
	if
	:: !subscriber -> end: caremUser ? request,_ ;
														if
														:: atomic { authorization = true; caremUser ! reply( 1 ) }
														:: atomic{ authorization = false; caremUser ! reply( 0 ) }
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
	bit g0,g1;
	bit t0,t1;
	
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

												:: subscriber ->	goto wantServices;
												fi;
												
												wantServices:
												assert( subscriber || authorization );

												caremCreditcard ! request;
												caremCreditcard ? reply;																										
												caremGarage[0] ! request( 1 );
												caremGarage[0] ? reply( g0 );
												if
												:: !g0 -> caremGarage[1] ! request( 1 ); caremGarage[1] ? reply, g1
												:: g0 -> goto reqOther
												fi;
													
												if
												:: !g1 ->  goto endfail
												:: else -> skip
												fi;			

												reqOther:
												caremHandle ! 1;													
												caremTruck[0] ! request( 1 );
												caremTruck[0] ? reply( t0 );
												if
												:: !t0 -> caremTruck[1] ! request( 1 ); caremTruck[1] ? reply, t1
												:: t0 -> skip
												fi;

												if
												:: !t0 && !t1 && g0 -> caremGarage[0] ! release( 1 ); caremHandle ? _ ; goto endfail
												:: !t0 && !t1 && g1 -> caremGarage[1] ! release( 1 ); caremHandle ? _ ; goto endfail							
												:: else -> skip
												fi;
												/*use services*/


												/*release services*/																								
												if
												:: g0  -> caremGarage[0] ! release( 1 );
												:: g1  -> caremGarage[1] ! release( 1 );
												:: else ->skip
												fi;
												if
												:: t0 -> caremTruck[0] ! release ( 1 )
												:: t1 -> caremTruck[1] ! release( 1 )																											
												::else->skip
												fi;
												caremHandle ? _ ;																																													
												goto success;
	endfail1:
	goto endend;

	endfail:
	assert(busygarage || busytruck ) ;
	goto endend;		

	success: skip;															

	endend:
	assert( !prenotatogarage && !prenotatotruck && !prenotatoRental )
}



proctype CreditCard( ) {
	
	end:
	caremCreditcard ? request -> caremCreditcard ! reply
						
}

proctype Garage( bit i ){

	bit x;

	if
	:: busyGarage[i] = false;
	:: busyGarage[i] = true;
	fi;
	
	end:
	caremGarage[i] ? request, x ->
														
															 
																		if
																		:: busyGarage[i] -> caremGarage[i] ! reply( 0 )
																		:: !busyGarage[i] ->  prenotatoGarage[i] = 1; caremGarage[i] ! reply ( 1 );
																				atomic{ caremGarage[i] ? release, _ ; prenotatoGarage[i] = 0}																										
																		fi
														
}

proctype Truck( bit i ){
	bit x;

	if
	::busyTruck[i] = false
	::busyTruck[i] = true
	fi;
	
	end:
	caremTruck[i] ? request, x ->
																		if
																		:: busyTruck[i] -> caremTruck[i] ! reply( 0 )
																		:: !busyTruck[i] ->  prenotatoTruck[i] = 1; caremTruck[i] ! reply ( 1 ); 
																				atomic { caremTruck[i] ? release, _ ; prenotatoTruck[i] = 0}
																		fi

}

proctype HandleRental( ){

	bit y;

  end:
	caremHandle ? _-> 	
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
																	:: !busyRental -> prenotatoRental = 1; caremRental ! reply ( 1 );
																			atomic{ caremRental ? release, _; prenotatoRental = 0 }
																	fi
}



/*** Spin Safety verification

spin -a  scenario1_moreServ.pml
gcc -DMEMLIM=1024 -O2  -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
./pan -m10000  -c1
Pid: 4820

(Spin Version 6.2.4 -- 8 March 2013)
	+ Partial Order Reduction

Full statespace search for:
	never claim         	- (not selected)
	assertion violations	+
	cycle checks       	- (disabled by -DSAFETY)
	invalid end states	+

State-vector 132 byte, depth reached 93, errors: 0
    28562 states, stored
    45989 states, matched
    74551 transitions (= stored+matched)
      502 atomic steps
hash conflicts:       128 (resolved)

Stats on memory usage (in Megabytes):
    3.922	equivalent memory usage for states (stored*(State-vector + overhead))
    1.840	actual memory usage for states (compression: 46.90%)
         	state-vector as stored = 56 byte + 12 byte overhead
   64.000	memory used for hash table (-w24)
    0.343	memory used for DFS stack (-m10000)
   66.101	total actual memory usage


unreached in init
	(0 of 2 states)
unreached in proctype User
	(0 of 29 states)
unreached in proctype Damage
	(0 of 5 states)
unreached in proctype CarEmergency
	(0 of 79 states)
unreached in proctype CreditCard
	(0 of 3 states)
unreached in proctype Garage
	(0 of 16 states)
unreached in proctype Truck
	(0 of 16 states)
unreached in proctype HandleRental
	(0 of 14 states)
unreached in proctype RentalCar
	(0 of 16 states)

pan: elapsed time 0.11 seconds
No errors found -- did you verify all claims?


**/
