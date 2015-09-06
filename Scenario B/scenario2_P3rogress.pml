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

bool damage0;

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
	:: caremDamage[i] ! damage;
			if
			:: ( i == 0 ) -> progress: skip
			:: else -> skip;
			fi;
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
	:: caremDamage[i] ? damage -> if :: ( i == 0 )-> damage0 = true :: else -> damage0 = false fi;
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
														garageCarem ?? reply, eval(_pid), garage;																									
	
														caremHandle[i] ! 1;

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


ltl prop3Progress {  ([]<> !np_) -> ([] <> damage0)  }


/*** Spin Verifier: prop3Progress non è soddisfatta (senza weak fairness)
										Damage(0) [pid 12] esegue fino ad arrivare a progress e da lì mai più.
		
		nota: compilare con  gcc -DMEMLIM=1024 -O2 -DXUSAFE -w -o pan pan.c
					eseguire con   ./pan -m1000000  -a -c1 -N prop3Progress

Ecco un ciclo;

<<<<<START OF CYCLE>>>>>
MSC: ~G line 7
 92:	proc  - (prop3Progress) _spin_nvr.tmp:7 (state 10)	[(!(np_))]
Never claim moves to line 7	[(!(np_))]
 93:	proc  8 (Damage) scenario2_P3rogress.pml:51 (state 8)	[(1)]
MSC: ~G line 9
 94:	proc  - (prop3Progress) _spin_nvr.tmp:9 (state 15)	[goto T0_S108]
Never claim moves to line 9	[goto T0_S108]
 95:	proc  8 (Damage) scenario2_P3rogress.pml:51 (state 9)	[(1)]
spin: trail ends after 95 steps
#processes: 15
 95:	proc 14 (HandleRental) scenario2_P3rogress.pml:136 (state 6)
 95:	proc 13 (CreditCard) scenario2_P3rogress.pml:103 (state 3)
 95:	proc 12 (Damage) scenario2_P3rogress.pml:48 (state 3) ----------> progress state 
 95:	proc 11 (CarEmergency) scenario2_P3rogress.pml:65 (state 4)
 95:	proc 10 (HandleRental) scenario2_P3rogress.pml:139 (state 3)
 95:	proc  9 (CreditCard) scenario2_P3rogress.pml:103 (state 3)
 95:	proc  8 (Damage) scenario2_P3rogress.pml:45 (state 10) 
 95:	proc  7 (CarEmergency) scenario2_P3rogress.pml:86 (state 27)
 95:	proc  6 (User) scenario2_P3rogress.pml:29 (state 14)
 95:	proc  5 (User) scenario2_P3rogress.pml:29 (state 14)
 95:	proc  4 (:init:) scenario2_P3rogress.pml:169 (state 4)
 95:	proc  3 (RentalCar) scenario2_P3rogress.pml:155 (state 2)
 95:	proc  2 (Truck) scenario2_P3rogress.pml:125 (state 4)
 95:	proc  1 (Garage) scenario2_P3rogress.pml:117 (state 3)
 95:	proc  0 (Garage) scenario2_P3rogress.pml:114 (state 4)
MSC: ~G line 69
 95:	proc  - (prop3Progress) _spin_nvr.tmp:69 (state 126)
15 processes created
Exit-Status 0



*/





/*** Abilitando la weak fairness la p21Progress è soddisfatta:
		Il risultato di verifica è il seguente: d

spin -a  scenario2_P3rogress.pml
ltl prop3Progress: (! ([] (<> (! (np_))))) || ([] (<> (damage0)))
gcc -DMEMLIM=2048 -O2 -DBITSTATE -DNFAIR=5  -DXUSAFE -DNOREDUCE -w -o pan pan.c
./pan -m1000000  -a -f -c1 -N prop3Progress
Pid: 4042
warning: only one claim defined, -N ignored
Depth=    1371 States=    1e+06 Transitions= 4.01e+06 Memory=    54.538	t=     9.31 R=   1e+05
Depth=    1371 States=    2e+06 Transitions= 8.06e+06 Memory=    54.538	t=     18.7 R=   1e+05
Depth=   20886 States=    3e+06 Transitions= 1.35e+07 Memory=    56.003	t=     31.2 R=   1e+05
Depth=   45953 States=    4e+06 Transitions= 1.96e+07 Memory=    57.956	t=     45.4 R=   9e+04
Depth=  231581 States=    5e+06 Transitions= 2.59e+07 Memory=    71.628	t=     60.4 R=   8e+04
Depth=  375476 States=    6e+06 Transitions= 3.27e+07 Memory=    82.077	t=     76.8 R=   8e+04
Depth=  375476 States=    7e+06 Transitions=  3.8e+07 Memory=    82.077	t=      142 R=   5e+04
Depth=  375476 States=    8e+06 Transitions= 4.45e+07 Memory=    82.077	t=      157 R=   5e+04
Depth=  375476 States=    9e+06 Transitions= 5.07e+07 Memory=    82.077	t=      171 R=   5e+04
Depth=  375476 States=    1e+07 Transitions= 5.73e+07 Memory=    82.077	t=      257 R=   4e+04
Depth=  375476 States=  1.1e+07 Transitions= 6.28e+07 Memory=    82.077	t=      276 R=   4e+04
Depth=  375476 States=  1.2e+07 Transitions= 6.89e+07 Memory=    82.077	t=      291 R=   4e+04
Depth=  375476 States=  1.3e+07 Transitions= 7.52e+07 Memory=    82.077	t=      305 R=   4e+04
Depth=  375476 States=  1.4e+07 Transitions=  8.2e+07 Memory=    82.077	t=      322 R=   4e+04
Depth=  375476 States=  1.5e+07 Transitions= 8.79e+07 Memory=    82.077	t=      372 R=   4e+04
Depth=  375476 States=  1.6e+07 Transitions= 9.39e+07 Memory=    82.077	t=      386 R=   4e+04
Depth=  375476 States=  1.7e+07 Transitions=    1e+08 Memory=    82.077	t=      401 R=   4e+04
Depth=  375476 States=  1.8e+07 Transitions= 1.06e+08 Memory=    82.077	t=      416 R=   4e+04
Depth=  375476 States=  1.9e+07 Transitions= 1.13e+08 Memory=    82.077	t=      434 R=   4e+04
Depth=  375476 States=    2e+07 Transitions= 1.19e+08 Memory=    82.077	t=      487 R=   4e+04
Depth=  375476 States=  2.1e+07 Transitions= 1.25e+08 Memory=    82.077	t=      502 R=   4e+04
Depth=  375476 States=  2.2e+07 Transitions= 1.31e+08 Memory=    82.077	t=      517 R=   4e+04
Depth=  375476 States=  2.3e+07 Transitions= 1.37e+08 Memory=    82.077	t=      561 R=   4e+04
Depth=  375476 States=  2.4e+07 Transitions= 1.43e+08 Memory=    82.077	t=      575 R=   4e+04
Depth=  375476 States=  2.5e+07 Transitions= 1.49e+08 Memory=    82.077	t=      589 R=   4e+04
Depth=  375476 States=  2.6e+07 Transitions= 1.56e+08 Memory=    82.077	t=      605 R=   4e+04
Depth=  375476 States=  2.7e+07 Transitions= 1.61e+08 Memory=    82.077	t=      652 R=   4e+04
Depth=  375476 States=  2.8e+07 Transitions= 1.68e+08 Memory=    82.077	t=      667 R=   4e+04
Depth=  375476 States=  2.9e+07 Transitions= 1.75e+08 Memory=    82.077	t=      682 R=   4e+04
Depth=  375476 States=    3e+07 Transitions= 1.82e+08 Memory=    82.077	t=      698 R=   4e+04
Depth=  375476 States=  3.1e+07 Transitions= 1.88e+08 Memory=    82.077	t=      745 R=   4e+04
Depth=  375476 States=  3.2e+07 Transitions= 1.94e+08 Memory=    82.077	t=      759 R=   4e+04
Depth=  375476 States=  3.3e+07 Transitions=    2e+08 Memory=    82.077	t=      775 R=   4e+04
Depth=  375476 States=  3.4e+07 Transitions= 2.07e+08 Memory=    82.077	t=      790 R=   4e+04
Depth=  375476 States=  3.5e+07 Transitions= 2.14e+08 Memory=    82.077	t=      806 R=   4e+04
Depth=  375476 States=  3.6e+07 Transitions= 2.19e+08 Memory=    82.077	t=      851 R=   4e+04
Depth=  375476 States=  3.7e+07 Transitions= 2.26e+08 Memory=    82.077	t=      867 R=   4e+04
Depth=  375476 States=  3.8e+07 Transitions= 2.33e+08 Memory=    82.077	t=      882 R=   4e+04
Depth=  375476 States=  3.9e+07 Transitions= 2.39e+08 Memory=    82.077	t=      898 R=   4e+04
Depth=  375476 States=    4e+07 Transitions= 2.45e+08 Memory=    82.077	t=      938 R=   4e+04
Depth=  375476 States=  4.1e+07 Transitions= 2.51e+08 Memory=    82.077	t=      953 R=   4e+04
Depth=  375476 States=  4.2e+07 Transitions= 2.57e+08 Memory=    82.077	t=      988 R=   4e+04
Depth=  375476 States=  4.3e+07 Transitions= 2.64e+08 Memory=    82.077	t=    1e+03 R=   4e+04
Depth=  375476 States=  4.4e+07 Transitions=  2.7e+08 Memory=    82.077	t= 1.03e+03 R=   4e+04
Depth=  375476 States=  4.5e+07 Transitions= 2.76e+08 Memory=    82.077	t= 1.05e+03 R=   4e+04
Depth=  375476 States=  4.6e+07 Transitions= 2.82e+08 Memory=    82.077	t= 1.06e+03 R=   4e+04
Depth=  375476 States=  4.7e+07 Transitions= 2.88e+08 Memory=    82.077	t= 1.08e+03 R=   4e+04
Depth=  375476 States=  4.8e+07 Transitions= 2.94e+08 Memory=    82.077	t= 1.09e+03 R=   4e+04
Depth=  375476 States=  4.9e+07 Transitions= 3.01e+08 Memory=    82.077	t= 1.11e+03 R=   4e+04
Depth=  375476 States=    5e+07 Transitions= 3.07e+08 Memory=    82.077	t= 1.12e+03 R=   4e+04
Depth=  375476 States=  5.1e+07 Transitions= 3.13e+08 Memory=    82.077	t= 1.14e+03 R=   4e+04
Depth=  375476 States=  5.2e+07 Transitions= 3.19e+08 Memory=    82.077	t= 1.15e+03 R=   5e+04
Depth=  375476 States=  5.3e+07 Transitions= 3.26e+08 Memory=    82.077	t= 1.17e+03 R=   5e+04
Depth=  375476 States=  5.4e+07 Transitions= 3.32e+08 Memory=    82.077	t= 1.18e+03 R=   5e+04
Depth=  375476 States=  5.5e+07 Transitions= 3.39e+08 Memory=    82.077	t=  1.2e+03 R=   5e+04

(Spin Version 6.2.4 -- 8 March 2013)

Bit statespace search for:
	never claim         	+ (prop3Progress)
	assertion violations	+ (if within scope of claim)
	acceptance   cycles 	+ (fairness enabled)
	invalid end states	- (disabled by never claim)

State-vector 164 byte, depth reached 375476, errors: 0
 48990835 states, stored (5.59257e+07 visited)
2.8867182e+08 states, matched
3.4459751e+08 transitions (= visited+matched)
    14512 atomic steps

hash factor: 2.39993 (best if > 100.)

bits set per state: 3 (-k3)

Stats on memory usage (in Megabytes):
 8222.949	equivalent memory usage for states (stored*(State-vector + overhead))
   16.000	memory used for hash array (-w27)
    3.815	memory used for bit stack
   34.332	memory used for DFS stack (-m1000000)
   27.818	other (proc and chan stacks)
   82.077	total actual memory usage


unreached in proctype User
	scenario2_P3rogress.pml:38, state 17, "-end-"
	(1 of 17 states)
unreached in proctype Damage
	scenario2_P3rogress.pml:54, state 13, "-end-"
	(1 of 13 states)
unreached in proctype CarEmergency
	scenario2_P3rogress.pml:99, state 35, "-end-"
	(1 of 35 states)
unreached in proctype CreditCard
	scenario2_P3rogress.pml:107, state 6, "-end-"
	(1 of 6 states)
unreached in proctype Garage
	scenario2_P3rogress.pml:119, state 7, "-end-"
	(1 of 7 states)
unreached in proctype Truck
	scenario2_P3rogress.pml:131, state 7, "-end-"
	(1 of 7 states)
unreached in proctype HandleRental
	scenario2_P3rogress.pml:149, state 9, "-end-"
	(1 of 9 states)
unreached in proctype RentalCar
	scenario2_P3rogress.pml:159, state 7, "-end-"
	(1 of 7 states)
unreached in init
	(0 of 4 states)
unreached in claim prop3Progress
	_spin_nvr.tmp:16, state 22, "-end-"
	(1 of 22 states)

pan: elapsed time 1.22e+03 seconds
No errors found -- did you verify all claims?

**/
