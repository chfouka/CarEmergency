bool subscriber[2] = false;
mtype = { Pisa, Lucca, Livorno, Firenze };
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
 bit u;
 byte index;
 byte garage;
 run HandleRental( i );

 end:
 do
 :: caremDamage[i] ? damage ->
              if
              :: location = Lucca;  index = LU
              :: location = Pisa;   index = PI
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
 byte index;
 
 if
 :: d_step{location = Lucca; garageServed[LU] = true}
 :: d_step{location = Pisa; garageServed[PI] = true}
 :: d_step{location = Livorno; garageServed[LI] = true}
 :: d_step{location = Firenze; garageServed[FI] = true}
 fi;
 

 end:
 do
 ::caremGarage ? request, loCarem, ideCarem ->
                   if :: (loCarem == Pisa ) ->index = PI
                     :: (loCarem == Lucca) -> index = LU
                     :: (loCarem == Livorno)-> index = LI
                     ::(loCarem == Firenze)-> index = FI
                   fi;
                   if
                   :: ( loCarem == location ) ->
                         garageCarem ! reply, ideCarem, _pid, 1 ; 
                         caremGarage ?? release, _, eval(_pid) ;
                   /*se invece index è servita si rimette il messaggio nel canale*/
                   :: (loCarem != location && garageServed[index]) ->
                         caremGarage ! request, loCarem, ideCarem 

                   :: else -> garageCarem ! reply, ideCarem, _pid, 0;
                   fi
 od 
}

active proctype Truck( ){
 mtype location1;
 mtype location2;
 mtype loCarem;

 if
 :: d_step{location1 = Lucca; truckServed[LU] = true}
 :: d_step{location1 = Pisa; truckServed[PI] = true}
 :: d_step{location1 = Livorno; truckServed[LI] = true}
 :: d_step{location1 = Firenze; truckServed[FI] = true}
 fi;

 if
 :: d_step{location2 = Lucca; truckServed[LU] = true}
 :: d_step{location2 = Pisa; truckServed[PI] = true}
 :: d_step{location2 = Livorno; truckServed[LI] = true}
 :: d_step{location2 = Firenze; truckServed[FI] = true}
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



/** SPin verification: assert violata

nota: compilare con gcc -DMEMLIM=3000 -O2 -DBITSTATE -DXUSAFE -DSAFETY -DNOCLAIM -w -o pan pan.c
   eseguire con : ./pan -m10000000  -c1

warning: in questo scenario la verifica di spin solleva un errore in quanto la massima 
    profondità nella visita depth first al grafo degli stati è stata raggiunta. 
    Non è stato possibile aumentare tale limite in quanto la macchina su sui sono state 
    effettuate le verifiche non dispone di memoria sufficiente.
    Tuttavia, anche in presenza di tale errore, Spin ha individuato una traccia
    in cui l'assert solleva un errore:

spin: scenario3_Ploc2Var.pml:66, redundant skip
using statement merging
Starting User with pid 5
  1: proc  4 (:init:) scenario3_Ploc2Var.pml:266 (state 1) [(run User(0))]
Starting User with pid 6
  2: proc  4 (:init:) scenario3_Ploc2Var.pml:267 (state 2) [(run User(1))]
  3: proc  2 (RentalCar) scenario3_Ploc2Var.pml:203 (state 1) [location1 = Lucca]
  4: proc  2 (RentalCar) scenario3_Ploc2Var.pml:210 (state 7) [location2 = Lucca]
  5: proc  6 (User) scenario3_Ploc2Var.pml:33 (state 1) [subscriber[i] = 0]
Starting CarEmergency with pid 7
  6: proc  6 (User) scenario3_Ploc2Var.pml:38 (state 5) [(run CarEmergency(i))]
Starting Damage with pid 8
  7: proc  6 (User) scenario3_Ploc2Var.pml:39 (state 6) [(run Damage(i))]
Starting CreditCard with pid 9
  8: proc  6 (User) scenario3_Ploc2Var.pml:40 (state 7) [(run CreditCard(i))]
  9: proc  8 (Damage) scenario3_Ploc2Var.pml:65 (state 1) [(1)]
Starting HandleRental with pid 10
 10: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:77 (state 1) [(run HandleRental(i))]
 11: proc  8 (Damage) scenario3_Ploc2Var.pml:65 (state 2) [caremDamage[i]!damage]
 12: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:81 (state 2) [caremDamage[i]?damage]
 13: proc  8 (Damage) scenario3_Ploc2Var.pml:65 (state 1) [(1)]
 14: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:83 (state 3) [location = Lucca]
 14: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:83 (state 4) [index = 1]
 15: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:89 (state 13) [(!(subscriber[i]))]
 16: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:90 (state 14) [caremUser[i]!request,1]
 17: proc  6 (User) scenario3_Ploc2Var.pml:45 (state 9) [caremUser[i]?request,_]
 18: proc  6 (User) scenario3_Ploc2Var.pml:47 (state 10) [caremUser[i]!reply,1]
 19: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:91 (state 15) [caremUser[i]?reply,u]
 20: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:94 (state 18) [(u)]
 21: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:99 (state 26) [caremHandle[i]!location,1]
 22: proc 10 (HandleRental) scenario3_Ploc2Var.pml:179 (state 1) [caremHandle[i]?loCarem,_]
 23: proc 10 (HandleRental) scenario3_Ploc2Var.pml:180 (state 2) [caremRental!request,loCarem]
 24: proc  2 (RentalCar) scenario3_Ploc2Var.pml:218 (state 13) [caremRental?request,loCarem]
 25: proc  2 (RentalCar) scenario3_Ploc2Var.pml:220 (state 14) [(((loCarem==location1)||(loCarem==location2)))]
 26: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:100 (state 27) [caremCreditcard[i]!request]
 27: proc  9 (CreditCard) scenario3_Ploc2Var.pml:56 (state 1) [caremCreditcard[i]?request]
 28: proc  9 (CreditCard) scenario3_Ploc2Var.pml:56 (state 2) [caremCreditcard[i]!reply]
 29: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:101 (state 28) [caremCreditcard[i]?reply]
 30: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:104 (state 29) [caremGarage!request,location,_pid]
 31: proc  5 (User) scenario3_Ploc2Var.pml:33 (state 1) [subscriber[i] = 0]
Starting CarEmergency with pid 11
 32: proc  5 (User) scenario3_Ploc2Var.pml:38 (state 5) [(run CarEmergency(i))]
Starting Damage with pid 12
 33: proc  5 (User) scenario3_Ploc2Var.pml:39 (state 6) [(run Damage(i))]
Starting CreditCard with pid 13
 34: proc  5 (User) scenario3_Ploc2Var.pml:40 (state 7) [(run CreditCard(i))]
 35: proc 12 (Damage) scenario3_Ploc2Var.pml:65 (state 1) [(1)]
Starting HandleRental with pid 14
 36: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:77 (state 1) [(run HandleRental(i))]
 37: proc 12 (Damage) scenario3_Ploc2Var.pml:65 (state 2) [caremDamage[i]!damage]
 38: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:81 (state 2) [caremDamage[i]?damage]
 39: proc 12 (Damage) scenario3_Ploc2Var.pml:65 (state 1) [(1)]
 40: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:83 (state 3) [location = Lucca]
 40: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:83 (state 4) [index = 1]
 41: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:89 (state 13) [(!(subscriber[i]))]
 42: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:90 (state 14) [caremUser[i]!request,1]
 43: proc  5 (User) scenario3_Ploc2Var.pml:45 (state 9) [caremUser[i]?request,_]
 44: proc  5 (User) scenario3_Ploc2Var.pml:47 (state 10) [caremUser[i]!reply,1]
 45: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:91 (state 15) [caremUser[i]?reply,u]
 46: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:94 (state 18) [(u)]
 47: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:99 (state 26) [caremHandle[i]!location,1]
 48: proc 14 (HandleRental) scenario3_Ploc2Var.pml:179 (state 1) [caremHandle[i]?loCarem,_]
 49: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:100 (state 27) [caremCreditcard[i]!request]
 50: proc 13 (CreditCard) scenario3_Ploc2Var.pml:56 (state 1) [caremCreditcard[i]?request]
 51: proc 13 (CreditCard) scenario3_Ploc2Var.pml:56 (state 2) [caremCreditcard[i]!reply]
 52: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:101 (state 28) [caremCreditcard[i]?reply]
 53: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:104 (state 29) [caremGarage!request,location,_pid]
 54: proc  3 (Truck) scenario3_Ploc2Var.pml:234 (state 3) [location1 = Lucca]
 54: proc  3 (Truck) scenario3_Ploc2Var.pml:234 (state 2) [truckServed[1] = 1]
 55: proc  3 (Truck) scenario3_Ploc2Var.pml:241 (state 17) [location2 = Lucca]
 55: proc  3 (Truck) scenario3_Ploc2Var.pml:241 (state 16) [truckServed[1] = 1]
 56: proc  2 (RentalCar) scenario3_Ploc2Var.pml:221 (state 15) [caremRental!reply,1]
 57: proc 10 (HandleRental) scenario3_Ploc2Var.pml:181 (state 3) [caremRental?reply,r]
 58: proc 10 (HandleRental) scenario3_Ploc2Var.pml:184 (state 6) [else]
 59: proc 10 (HandleRental) scenario3_Ploc2Var.pml:188 (state 7) [caremRental!release,loCarem]
 60: proc  2 (RentalCar) scenario3_Ploc2Var.pml:222 (state 16) [caremRental?release,_]
 61: proc 14 (HandleRental) scenario3_Ploc2Var.pml:180 (state 2) [caremRental!request,loCarem]
 62: proc  2 (RentalCar) scenario3_Ploc2Var.pml:218 (state 13) [caremRental?request,loCarem]
 63: proc  2 (RentalCar) scenario3_Ploc2Var.pml:220 (state 14) [(((loCarem==location1)||(loCarem==location2)))]
 64: proc  2 (RentalCar) scenario3_Ploc2Var.pml:221 (state 15) [caremRental!reply,1]
 65: proc 14 (HandleRental) scenario3_Ploc2Var.pml:181 (state 3) [caremRental?reply,r]
 66: proc 14 (HandleRental) scenario3_Ploc2Var.pml:184 (state 6) [else]
 67: proc  1 (Garage) scenario3_Ploc2Var.pml:149 (state 12) [location = Firenze]
 67: proc  1 (Garage) scenario3_Ploc2Var.pml:149 (state 11) [garageServed[3] = 1]
 68: proc  1 (Garage) scenario3_Ploc2Var.pml:155 (state 15) [caremGarage?request,loCarem,ideCarem]
 69: proc  1 (Garage) scenario3_Ploc2Var.pml:157 (state 18) [((loCarem==Lucca))]
 69: proc  1 (Garage) scenario3_Ploc2Var.pml:157 (state 19) [index = 1]
 70: proc 14 (HandleRental) scenario3_Ploc2Var.pml:188 (state 7) [caremRental!release,loCarem]
 71: proc  2 (RentalCar) scenario3_Ploc2Var.pml:222 (state 16) [caremRental?release,_]
 72: proc  1 (Garage) scenario3_Ploc2Var.pml:168 (state 31) [else]
 73: proc  1 (Garage) scenario3_Ploc2Var.pml:168 (state 32) [garageCarem!reply,ideCarem,_pid,0]
 74: proc  0 (Garage) scenario3_Ploc2Var.pml:146 (state 3) [location = Lucca]
 74: proc  0 (Garage) scenario3_Ploc2Var.pml:146 (state 2) [garageServed[1] = 1]
 75: proc  1 (Garage) scenario3_Ploc2Var.pml:155 (state 15) [caremGarage?request,loCarem,ideCarem]
 76: proc  1 (Garage) scenario3_Ploc2Var.pml:157 (state 18) [((loCarem==Lucca))]
 76: proc  1 (Garage) scenario3_Ploc2Var.pml:157 (state 19) [index = 1]
 77: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:105 (state 30) [garageCarem??reply,eval(_pid),garage,u]
 78: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:107 (state 31) [(!(u))]
 79: proc 10 (HandleRental) scenario3_Ploc2Var.pml:191 (state 8) [caremHandle[i]!loCarem,1]
 80: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:107 (state 32) [caremHandle[i]?_,_]
spin: scenario3_Ploc2Var.pml:108, Error: assertion violated
spin: text of failed assertion: assert(!(garageServed[index]))
#processes: 15
 81: proc 14 (HandleRental) scenario3_Ploc2Var.pml:191 (state 8)
 81: proc 13 (CreditCard) scenario3_Ploc2Var.pml:55 (state 3)
 81: proc 12 (Damage) scenario3_Ploc2Var.pml:65 (state 2)
 81: proc 11 (CarEmergency) scenario3_Ploc2Var.pml:105 (state 30)
 81: proc 10 (HandleRental) scenario3_Ploc2Var.pml:178 (state 11)
 81: proc  9 (CreditCard) scenario3_Ploc2Var.pml:55 (state 3)
 81: proc  8 (Damage) scenario3_Ploc2Var.pml:65 (state 2)
 81: proc  7 (CarEmergency) scenario3_Ploc2Var.pml:108 (state 33)
 81: proc  6 (User) scenario3_Ploc2Var.pml:44 (state 14)
 81: proc  5 (User) scenario3_Ploc2Var.pml:44 (state 14)
 81: proc  4 (:init:) scenario3_Ploc2Var.pml:270 (state 4)
 81: proc  3 (Truck) scenario3_Ploc2Var.pml:250 (state 37)
 81: proc  2 (RentalCar) scenario3_Ploc2Var.pml:217 (state 21)
 81: proc  1 (Garage) scenario3_Ploc2Var.pml:161 (state 33)
 81: proc  0 (Garage) scenario3_Ploc2Var.pml:154 (state 35)
15 processes created
Exit-Status 0

*/
