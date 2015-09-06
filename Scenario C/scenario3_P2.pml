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
               if :: ( i == 0 ) -> damage0 = true :: else -> damage0 = false fi;
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


ltl prop21 { [] <> damage0 }



/**** SPin never claim verification:
   prop21 (senza weak airness) non è soddisfatta. Un ciclo è trovato: Damage(0) mai schedulato.
  
  nota: compilare con   gcc -DMEMLIM=2048 -O2 -DBITSTATE -DXUSAFE -w -o pan pan.c
     eseguire con   ./pan -m10000000  -a -c1 -N prop21

<<<<<START OF CYCLE>>>>>
151: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
152: proc  1 (Garage) scenario3_P2.pml:138 (state 7) [caremGarage?request,loCarem,ideCarem]
153: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
154: proc  1 (Garage) scenario3_P2.pml:140 (state 8) [((loCarem==location))]
155: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
156: proc  1 (Garage) scenario3_P2.pml:141 (state 9) [garageCarem!reply,ideCarem,_pid,1]
157: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
158: proc  7 (CarEmergency) scenario3_P2.pml:87 (state 31) [garageCarem??reply,eval(_pid),garage,u]
159: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
160: proc  7 (CarEmergency) scenario3_P2.pml:90 (state 34) [else]
161: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
162: proc  7 (CarEmergency) scenario3_P2.pml:90 (state 35) [(1)]
163: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
164: proc  7 (CarEmergency) scenario3_P2.pml:93 (state 38) [caremHandle[i]!location,1]
165: proc 10 (HandleRental) scenario3_P2.pml:191 (state 1) [caremHandle[i]?loCarem,_]
166: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
167: proc 10 (HandleRental) scenario3_P2.pml:192 (state 2) [caremRental!request,loCarem]
168: proc  3 (RentalCar) scenario3_P2.pml:230 (state 13) [caremRental?request,loCarem]
169: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
170: proc  3 (RentalCar) scenario3_P2.pml:232 (state 14) [(((loCarem==location1)||(loCarem==location2)))]
171: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
172: proc  7 (CarEmergency) scenario3_P2.pml:95 (state 39) [caremTruck!request,location]
173: proc  2 (Truck) scenario3_P2.pml:173 (state 13) [caremTruck?request,loCarem]
174: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
175: proc  2 (Truck) scenario3_P2.pml:175 (state 14) [(((loCarem==location1)||(loCarem==location2)))]
176: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
177: proc  2 (Truck) scenario3_P2.pml:176 (state 15) [caremTruck!reply,1]
178: proc  7 (CarEmergency) scenario3_P2.pml:96 (state 40) [caremTruck?reply,u]
179: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
180: proc  7 (CarEmergency) scenario3_P2.pml:99 (state 45) [else]
181: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
182: proc  7 (CarEmergency) scenario3_P2.pml:99 (state 46) [(1)]
183: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
184: proc  7 (CarEmergency) scenario3_P2.pml:102 (state 49) [caremTruck!release,1]
185: proc  2 (Truck) scenario3_P2.pml:177 (state 16) [caremTruck?release,_]
186: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
187: proc  7 (CarEmergency) scenario3_P2.pml:107 (state 50) [caremGarage!release,location,garage]
188: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
189: proc  3 (RentalCar) scenario3_P2.pml:233 (state 15) [caremRental!reply,1]
190: proc 10 (HandleRental) scenario3_P2.pml:193 (state 3) [caremRental?reply,r]
191: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
192: proc 10 (HandleRental) scenario3_P2.pml:196 (state 6) [else]
193: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
194: proc  1 (Garage) scenario3_P2.pml:142 (state 10) [caremGarage??release,_,eval(_pid)]
195: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
196: proc 10 (HandleRental) scenario3_P2.pml:200 (state 7) [caremRental!release,loCarem]
197: proc  3 (RentalCar) scenario3_P2.pml:234 (state 16) [caremRental?release,_]
198: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
199: proc 10 (HandleRental) scenario3_P2.pml:203 (state 8) [caremHandle[i]!loCarem,1]
200: proc  7 (CarEmergency) scenario3_P2.pml:109 (state 51) [caremHandle[i]?_,_]
201: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
202: proc  8 (Damage) scenario3_P2.pml:47 (state 2) [caremDamage[i]!damage]
203: proc  7 (CarEmergency) scenario3_P2.pml:62 (state 2) [caremDamage[i]?damage]
204: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
205: proc  8 (Damage) scenario3_P2.pml:47 (state 1) [(1)]
206: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
207: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 5) [else]
208: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
209: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 6) [damage0 = 0]
210: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
211: proc  7 (CarEmergency) scenario3_P2.pml:65 (state 9) [location = Lucca]
212: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
213: proc  7 (CarEmergency) scenario3_P2.pml:71 (state 15) [(!(subscriber[i]))]
214: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
215: proc  7 (CarEmergency) scenario3_P2.pml:72 (state 16) [caremUser[i]!request,1]
216: proc  6 (User) scenario3_P2.pml:32 (state 9) [caremUser[i]?request,_]
217: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
218: proc  6 (User) scenario3_P2.pml:34 (state 10) [caremUser[i]!reply,1]
219: proc  7 (CarEmergency) scenario3_P2.pml:73 (state 17) [caremUser[i]?reply,u]
220: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
221: proc  7 (CarEmergency) scenario3_P2.pml:76 (state 20) [(u)]
222: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
223: proc  7 (CarEmergency) scenario3_P2.pml:82 (state 28) [caremCreditcard[i]!request]
224: proc  9 (CreditCard) scenario3_P2.pml:117 (state 1) [caremCreditcard[i]?request]
225: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
226: proc  9 (CreditCard) scenario3_P2.pml:117 (state 2) [caremCreditcard[i]!reply]
227: proc  7 (CarEmergency) scenario3_P2.pml:83 (state 29) [caremCreditcard[i]?reply]
228: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
229: proc  7 (CarEmergency) scenario3_P2.pml:86 (state 30) [caremGarage!request,location,_pid]
spin: trail ends after 229 steps
#processes: 15
229: proc 14 (HandleRental) scenario3_P2.pml:190 (state 11)
229: proc 13 (CreditCard) scenario3_P2.pml:116 (state 3)
229: proc 12 (Damage) scenario3_P2.pml:47 (state 2)
229: proc 11 (CarEmergency) scenario3_P2.pml:63 (state 4)
229: proc 10 (HandleRental) scenario3_P2.pml:190 (state 11)
229: proc  9 (CreditCard) scenario3_P2.pml:116 (state 3)
229: proc  8 (Damage) scenario3_P2.pml:47 (state 2)
229: proc  7 (CarEmergency) scenario3_P2.pml:87 (state 31)
229: proc  6 (User) scenario3_P2.pml:31 (state 14)
229: proc  5 (User) scenario3_P2.pml:31 (state 14)
229: proc  4 (:init:) scenario3_P2.pml:248 (state 4)
229: proc  3 (RentalCar) scenario3_P2.pml:229 (state 21)
229: proc  2 (Truck) scenario3_P2.pml:172 (state 21)
229: proc  1 (Garage) scenario3_P2.pml:137 (state 15)
229: proc  0 (Garage) scenario3_P2.pml:137 (state 15)
MSC: ~G line 8
229: proc  - (prop21) _spin_nvr.tmp:8 (state 16)
15 processes created
Exit-Status 0

*/


/* Anche con weak fairness forzata, Damage(0) [con pid 12] esegue sempre il ramo else->skip 
 dunque prop21 continua a non valere. 
 
 nota:  weak fairness non è compatibile con la partial order reduction. Dev'essere disabilitata.
     compilare con:  gcc -DMEMLIM=2048 -O2 -DNFAIR=5 -DBITSTATE -DXUSAFE -w -o pan pan.c
     eseguire con : eseguire con   ./pan -m10000000  -a -c1 -N prop21


<<<<<START OF CYCLE>>>>>
 90: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
 91: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 6) [damage0 = 0]
 92: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
 93: proc  7 (CarEmergency) scenario3_P2.pml:68 (state 12) [location = Firenze]
 94: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
 95: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
 96: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
 97: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
 98: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
 99: proc  7 (CarEmergency) scenario3_P2.pml:71 (state 15) [(!(subscriber[i]))]
100: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
101: proc  7 (CarEmergency) scenario3_P2.pml:72 (state 16) [caremUser[i]!request,1]
102: proc  6 (User) scenario3_P2.pml:32 (state 9) [caremUser[i]?request,_]
103: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
104: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
105: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
106: proc  8 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
107: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
108: proc  8 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
109: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
110: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
111: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
112: proc  6 (User) scenario3_P2.pml:35 (state 11) [caremUser[i]!reply,0]
113: proc  7 (CarEmergency) scenario3_P2.pml:73 (state 17) [caremUser[i]?reply,u]
114: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
115: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
116: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
117: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
118: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
119: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
120: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
121: proc  7 (CarEmergency) scenario3_P2.pml:75 (state 18) [(!(u))]
122: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
123: proc  8 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
124: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
125: proc  8 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
126: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
127: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
128: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
129: proc  8 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
130: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
131: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
132: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
133: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
134: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
135: proc  8 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
136: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
137: proc  8 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
138: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
139: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
140: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
141: proc  8 (Damage) scenario3_P2.pml:47 (state 1) [(1)]
142: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
143: proc  8 (Damage) scenario3_P2.pml:47 (state 2) [caremDamage[i]!damage]
144: proc  7 (CarEmergency) scenario3_P2.pml:62 (state 2) [caremDamage[i]?damage]
145: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
146: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 5) [else]
147: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
148: proc  8 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
149: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
150: proc  8 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
151: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
152: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 6) [damage0 = 0]
153: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
154: proc  7 (CarEmergency) scenario3_P2.pml:65 (state 9) [location = Lucca]
155: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
156: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
157: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
158: proc  7 (CarEmergency) scenario3_P2.pml:71 (state 15) [(!(subscriber[i]))]
159: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
160: proc  7 (CarEmergency) scenario3_P2.pml:72 (state 16) [caremUser[i]!request,1]
161: proc  6 (User) scenario3_P2.pml:32 (state 9) [caremUser[i]?request,_]
162: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
163: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
164: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
165: proc  8 (Damage) scenario3_P2.pml:47 (state 1) [(1)]
166: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
167: proc  6 (User) scenario3_P2.pml:35 (state 11) [caremUser[i]!reply,0]
168: proc  7 (CarEmergency) scenario3_P2.pml:73 (state 17) [caremUser[i]?reply,u]
169: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
170: proc  7 (CarEmergency) scenario3_P2.pml:75 (state 18) [(!(u))]
171: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
172: proc  8 (Damage) scenario3_P2.pml:47 (state 2) [caremDamage[i]!damage]
173: proc  7 (CarEmergency) scenario3_P2.pml:62 (state 2) [caremDamage[i]?damage]
174: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
175: proc  8 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
176: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
177: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 5) [else]
178: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
179: proc  8 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
180: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
181: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
182: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
183: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
184: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
185: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
186: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
187: proc  8 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
188: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
189: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 6) [damage0 = 0]
190: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
191: proc  8 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
192: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
193: proc  7 (CarEmergency) scenario3_P2.pml:65 (state 9) [location = Lucca]
194: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
195: proc  7 (CarEmergency) scenario3_P2.pml:71 (state 15) [(!(subscriber[i]))]
196: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
197: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
198: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
199: proc  8 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
200: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
201: proc  7 (CarEmergency) scenario3_P2.pml:72 (state 16) [caremUser[i]!request,1]
202: proc  6 (User) scenario3_P2.pml:32 (state 9) [caremUser[i]?request,_]
203: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
204: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
205: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
206: proc  6 (User) scenario3_P2.pml:35 (state 11) [caremUser[i]!reply,0]
207: proc  7 (CarEmergency) scenario3_P2.pml:73 (state 17) [caremUser[i]?reply,u]
208: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
209: proc  8 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
210: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
211: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
212: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
213: proc  7 (CarEmergency) scenario3_P2.pml:75 (state 18) [(!(u))]
214: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
215: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
216: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
217: proc 12 (Damage) scenario3_P2.pml:48 (state 4) [(1)]
218: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
219: proc  8 (Damage) scenario3_P2.pml:47 (state 1) [(1)]
220: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
221: proc  8 (Damage) scenario3_P2.pml:47 (state 2) [caremDamage[i]!damage]
222: proc  7 (CarEmergency) scenario3_P2.pml:62 (state 2) [caremDamage[i]?damage]
223: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
224: proc  8 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
225: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
226: proc 12 (Damage) scenario3_P2.pml:48 (state 3) [(1)]
227: proc  - (prop21) _spin_nvr.tmp:2 (state 8) [DO]
228: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 5) [else]
spin: trail ends after 228 steps
#processes: 15
228: proc 14 (HandleRental) scenario3_P2.pml:190 (state 11)
228: proc 13 (CreditCard) scenario3_P2.pml:116 (state 3)
228: proc 12 (Damage) scenario3_P2.pml:48 (state 4)
228: proc 11 (CarEmergency) scenario3_P2.pml:61 (state 52)
228: proc 10 (HandleRental) scenario3_P2.pml:190 (state 11)
228: proc  9 (CreditCard) scenario3_P2.pml:116 (state 3)
228: proc  8 (Damage) scenario3_P2.pml:48 (state 4)
228: proc  7 (CarEmergency) scenario3_P2.pml:63 (state 6)
228: proc  6 (User) scenario3_P2.pml:31 (state 14)
228: proc  5 (User) scenario3_P2.pml:31 (state 14)
228: proc  4 (:init:) scenario3_P2.pml:248 (state 4)
228: proc  3 (RentalCar) scenario3_P2.pml:229 (state 21)
228: proc  2 (Truck) scenario3_P2.pml:172 (state 21)
228: proc  1 (Garage) scenario3_P2.pml:137 (state 15)
228: proc  0 (Garage) scenario3_P2.pml:137 (state 15)
228: proc  - (prop21) _spin_nvr.tmp:2 (state 8)
15 processes created
Exit-Status 0

*/


