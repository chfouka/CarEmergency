bool subscriber[2] = false;
mtype = { request, reply, release, damage }; 
mtype = { Pisa, Livorno, Lucca, Firenze };

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
   if
   :: ( i == 0 ) -> progress: skip
   :: else -> skip;
   fi;
 :: 1 -> skip
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
 :: caremDamage[i] ? damage -> if :: ( i == 0 )-> damage0 = true :: else -> damage0 = false fi;
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
              :: !u ->  goto end                 
              :: else->skip
              fi;
              
              caremHandle[i] ! location, 1;

              caremTruck ! request, location;
              caremTruck ? reply, u;
              if 
              :: !u -> caremHandle[i] ? _, _; 
                   caremGarage ! release, location, garage; 
                    goto end
              :: else-> skip
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


ltl prop3Progress{ ([]<> !np_) -> ([] <> damage0)  }

/*** Spin Verifier: prop3Progress non è soddisfatta (senza weak fairness)
          Damage(0) esegue fino ad arrivare a progress e da lì mai più.
  
  nota: compilare con   gcc -DMEMLIM=3000 -O2 -DBITSTATE -DXUSAFE -w -o pan pan.c
     eseguire con   ./pan -m10000000  -a -c1 -N prop21Progress


Ecco un ciclo:


<<<<<START OF CYCLE>>>>>
MSC: ~G line 7
159: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
160: proc  1 (Garage) scenario3_P3ogress.pml:143 (state 7) [caremGarage?request,loCarem,ideCarem]
MSC: ~G line 9
161: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
162: proc  1 (Garage) scenario3_P3ogress.pml:145 (state 8) [((loCarem==location))]
MSC: ~G line 7
163: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
164: proc  1 (Garage) scenario3_P3ogress.pml:146 (state 9) [garageCarem!reply,ideCarem,_pid,1]
MSC: ~G line 9
165: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
166: proc  7 (CarEmergency) scenario3_P3ogress.pml:90 (state 31) [garageCarem??reply,eval(_pid),garage,u]
MSC: ~G line 7
167: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
168: proc  7 (CarEmergency) scenario3_P3ogress.pml:93 (state 34) [else]
MSC: ~G line 9
169: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
170: proc  7 (CarEmergency) scenario3_P3ogress.pml:93 (state 35) [(1)]
MSC: ~G line 7
171: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
172: proc  7 (CarEmergency) scenario3_P3ogress.pml:96 (state 38) [caremHandle[i]!location,1]
173: proc 10 (HandleRental) scenario3_P3ogress.pml:196 (state 1) [caremHandle[i]?loCarem,_]
MSC: ~G line 9
174: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
175: proc 10 (HandleRental) scenario3_P3ogress.pml:197 (state 2) [caremRental!request,loCarem]
176: proc  3 (RentalCar) scenario3_P3ogress.pml:235 (state 13) [caremRental?request,loCarem]
MSC: ~G line 7
177: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
178: proc  3 (RentalCar) scenario3_P3ogress.pml:237 (state 14) [(((loCarem==location1)||(loCarem==location2)))]
MSC: ~G line 9
179: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
180: proc  7 (CarEmergency) scenario3_P3ogress.pml:98 (state 39) [caremTruck!request,location]
181: proc  2 (Truck) scenario3_P3ogress.pml:177 (state 13) [caremTruck?request,loCarem]
MSC: ~G line 7
182: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
183: proc  2 (Truck) scenario3_P3ogress.pml:179 (state 14) [(((loCarem==location1)||(loCarem==location2)))]
MSC: ~G line 9
184: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
185: proc  3 (RentalCar) scenario3_P3ogress.pml:238 (state 15) [caremRental!reply,1]
186: proc 10 (HandleRental) scenario3_P3ogress.pml:198 (state 3) [caremRental?reply,r]
MSC: ~G line 7
187: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
188: proc 10 (HandleRental) scenario3_P3ogress.pml:201 (state 6) [else]
MSC: ~G line 9
189: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
190: proc 10 (HandleRental) scenario3_P3ogress.pml:205 (state 7) [caremRental!release,loCarem]
191: proc  3 (RentalCar) scenario3_P3ogress.pml:239 (state 16) [caremRental?release,_]
MSC: ~G line 7
192: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
193: proc  2 (Truck) scenario3_P3ogress.pml:180 (state 15) [caremTruck!reply,1]
194: proc  7 (CarEmergency) scenario3_P3ogress.pml:99 (state 40) [caremTruck?reply,u]
MSC: ~G line 9
195: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
196: proc  7 (CarEmergency) scenario3_P3ogress.pml:104 (state 45) [else]
MSC: ~G line 7
197: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
198: proc  7 (CarEmergency) scenario3_P3ogress.pml:104 (state 46) [(1)]
MSC: ~G line 9
199: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
200: proc  7 (CarEmergency) scenario3_P3ogress.pml:107 (state 49) [caremTruck!release,1]
201: proc  2 (Truck) scenario3_P3ogress.pml:181 (state 16) [caremTruck?release,_]
MSC: ~G line 7
202: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
203: proc  7 (CarEmergency) scenario3_P3ogress.pml:112 (state 50) [caremGarage!release,location,garage]
MSC: ~G line 9
204: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
205: proc 10 (HandleRental) scenario3_P3ogress.pml:208 (state 8) [caremHandle[i]!loCarem,1]
206: proc  7 (CarEmergency) scenario3_P3ogress.pml:114 (state 51) [caremHandle[i]?_,_]
MSC: ~G line 7
207: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
208: proc  8 (Damage) scenario3_P3ogress.pml:46 (state 2) [caremDamage[i]!damage]
209: proc  7 (CarEmergency) scenario3_P3ogress.pml:66 (state 2) [caremDamage[i]?damage]
MSC: ~G line 9
210: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
211: proc  7 (CarEmergency) scenario3_P3ogress.pml:66 (state 5) [else]
MSC: ~G line 7
212: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
213: proc  8 (Damage) scenario3_P3ogress.pml:49 (state 5) [else]
MSC: ~G line 9
214: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
215: proc  8 (Damage) scenario3_P3ogress.pml:49 (state 6) [(1)]
MSC: ~G line 7
216: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
217: proc  8 (Damage) scenario3_P3ogress.pml:46 (state 1) [(1)]
MSC: ~G line 9
218: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
219: proc  7 (CarEmergency) scenario3_P3ogress.pml:66 (state 6) [damage0 = 0]
MSC: ~G line 7
220: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
221: proc  7 (CarEmergency) scenario3_P3ogress.pml:68 (state 9) [location = Lucca]
MSC: ~G line 9
222: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
223: proc  7 (CarEmergency) scenario3_P3ogress.pml:74 (state 15) [(!(subscriber[i]))]
MSC: ~G line 7
224: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
225: proc  7 (CarEmergency) scenario3_P3ogress.pml:75 (state 16) [caremUser[i]!request,1]
226: proc  6 (User) scenario3_P3ogress.pml:31 (state 9) [caremUser[i]?request,_]
MSC: ~G line 9
227: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
228: proc  6 (User) scenario3_P3ogress.pml:33 (state 10) [caremUser[i]!reply,1]
229: proc  7 (CarEmergency) scenario3_P3ogress.pml:76 (state 17) [caremUser[i]?reply,u]
MSC: ~G line 7
230: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
231: proc  7 (CarEmergency) scenario3_P3ogress.pml:79 (state 20) [(u)]
MSC: ~G line 9
232: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
233: proc  7 (CarEmergency) scenario3_P3ogress.pml:85 (state 28) [caremCreditcard[i]!request]
234: proc  9 (CreditCard) scenario3_P3ogress.pml:122 (state 1) [caremCreditcard[i]?request]
MSC: ~G line 7
235: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
236: proc  9 (CreditCard) scenario3_P3ogress.pml:122 (state 2) [caremCreditcard[i]!reply]
237: proc  7 (CarEmergency) scenario3_P3ogress.pml:86 (state 29) [caremCreditcard[i]?reply]
MSC: ~G line 9
238: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
239: proc  7 (CarEmergency) scenario3_P3ogress.pml:89 (state 30) [caremGarage!request,location,_pid]
MSC: ~G line 7
240: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
241: proc  1 (Garage) scenario3_P3ogress.pml:147 (state 10) [caremGarage??release,_,eval(_pid)]
MSC: ~G line 9
242: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
243: proc  1 (Garage) scenario3_P3ogress.pml:143 (state 7) [caremGarage?request,loCarem,ideCarem]
MSC: ~G line 7
244: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
245: proc  1 (Garage) scenario3_P3ogress.pml:145 (state 8) [((loCarem==location))]
MSC: ~G line 9
246: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
247: proc  1 (Garage) scenario3_P3ogress.pml:146 (state 9) [garageCarem!reply,ideCarem,_pid,1]
MSC: ~G line 7
248: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
249: proc  7 (CarEmergency) scenario3_P3ogress.pml:90 (state 31) [garageCarem??reply,eval(_pid),garage,u]
MSC: ~G line 9
250: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
251: proc  7 (CarEmergency) scenario3_P3ogress.pml:93 (state 34) [else]
MSC: ~G line 7
252: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
253: proc  7 (CarEmergency) scenario3_P3ogress.pml:93 (state 35) [(1)]
MSC: ~G line 9
254: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
255: proc  7 (CarEmergency) scenario3_P3ogress.pml:96 (state 38) [caremHandle[i]!location,1]
256: proc 10 (HandleRental) scenario3_P3ogress.pml:196 (state 1) [caremHandle[i]?loCarem,_]
MSC: ~G line 7
257: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
258: proc 10 (HandleRental) scenario3_P3ogress.pml:197 (state 2) [caremRental!request,loCarem]
259: proc  3 (RentalCar) scenario3_P3ogress.pml:235 (state 13) [caremRental?request,loCarem]
MSC: ~G line 9
260: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
261: proc  3 (RentalCar) scenario3_P3ogress.pml:237 (state 14) [(((loCarem==location1)||(loCarem==location2)))]
MSC: ~G line 7
262: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
263: proc  7 (CarEmergency) scenario3_P3ogress.pml:98 (state 39) [caremTruck!request,location]
264: proc  2 (Truck) scenario3_P3ogress.pml:177 (state 13) [caremTruck?request,loCarem]
MSC: ~G line 9
265: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
266: proc  2 (Truck) scenario3_P3ogress.pml:179 (state 14) [(((loCarem==location1)||(loCarem==location2)))]
MSC: ~G line 7
267: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
268: proc  2 (Truck) scenario3_P3ogress.pml:180 (state 15) [caremTruck!reply,1]
269: proc  7 (CarEmergency) scenario3_P3ogress.pml:99 (state 40) [caremTruck?reply,u]
MSC: ~G line 9
270: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
271: proc  7 (CarEmergency) scenario3_P3ogress.pml:104 (state 45) [else]
MSC: ~G line 7
272: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
273: proc  7 (CarEmergency) scenario3_P3ogress.pml:104 (state 46) [(1)]
MSC: ~G line 9
274: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
275: proc  7 (CarEmergency) scenario3_P3ogress.pml:107 (state 49) [caremTruck!release,1]
276: proc  2 (Truck) scenario3_P3ogress.pml:181 (state 16) [caremTruck?release,_]
MSC: ~G line 7
277: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
278: proc  7 (CarEmergency) scenario3_P3ogress.pml:112 (state 50) [caremGarage!release,location,garage]
MSC: ~G line 9
279: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
280: proc  3 (RentalCar) scenario3_P3ogress.pml:238 (state 15) [caremRental!reply,1]
281: proc 10 (HandleRental) scenario3_P3ogress.pml:198 (state 3) [caremRental?reply,r]
MSC: ~G line 7
282: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
283: proc 10 (HandleRental) scenario3_P3ogress.pml:201 (state 6) [else]
MSC: ~G line 9
284: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
285: proc  1 (Garage) scenario3_P3ogress.pml:147 (state 10) [caremGarage??release,_,eval(_pid)]
MSC: ~G line 7
286: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
287: proc 10 (HandleRental) scenario3_P3ogress.pml:205 (state 7) [caremRental!release,loCarem]
288: proc  3 (RentalCar) scenario3_P3ogress.pml:239 (state 16) [caremRental?release,_]
MSC: ~G line 9
289: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
290: proc 10 (HandleRental) scenario3_P3ogress.pml:208 (state 8) [caremHandle[i]!loCarem,1]
291: proc  7 (CarEmergency) scenario3_P3ogress.pml:114 (state 51) [caremHandle[i]?_,_]
MSC: ~G line 7
292: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
293: proc  8 (Damage) scenario3_P3ogress.pml:46 (state 2) [caremDamage[i]!damage]
294: proc  7 (CarEmergency) scenario3_P3ogress.pml:66 (state 2) [caremDamage[i]?damage]
MSC: ~G line 9
295: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
296: proc  7 (CarEmergency) scenario3_P3ogress.pml:66 (state 5) [else]
MSC: ~G line 7
297: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
298: proc  8 (Damage) scenario3_P3ogress.pml:49 (state 5) [else]
MSC: ~G line 9
299: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
300: proc  8 (Damage) scenario3_P3ogress.pml:49 (state 6) [(1)]
MSC: ~G line 7
301: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
302: proc  8 (Damage) scenario3_P3ogress.pml:46 (state 1) [(1)]
MSC: ~G line 9
303: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
304: proc  7 (CarEmergency) scenario3_P3ogress.pml:66 (state 6) [damage0 = 0]
MSC: ~G line 7
305: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
306: proc  7 (CarEmergency) scenario3_P3ogress.pml:68 (state 9) [location = Lucca]
MSC: ~G line 9
307: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
308: proc  7 (CarEmergency) scenario3_P3ogress.pml:74 (state 15) [(!(subscriber[i]))]
MSC: ~G line 7
309: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
310: proc  7 (CarEmergency) scenario3_P3ogress.pml:75 (state 16) [caremUser[i]!request,1]
311: proc  6 (User) scenario3_P3ogress.pml:31 (state 9) [caremUser[i]?request,_]
MSC: ~G line 9
312: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
313: proc  6 (User) scenario3_P3ogress.pml:33 (state 10) [caremUser[i]!reply,1]
314: proc  7 (CarEmergency) scenario3_P3ogress.pml:76 (state 17) [caremUser[i]?reply,u]
MSC: ~G line 7
315: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
316: proc  7 (CarEmergency) scenario3_P3ogress.pml:79 (state 20) [(u)]
MSC: ~G line 9
317: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
318: proc  7 (CarEmergency) scenario3_P3ogress.pml:85 (state 28) [caremCreditcard[i]!request]
319: proc  9 (CreditCard) scenario3_P3ogress.pml:122 (state 1) [caremCreditcard[i]?request]
MSC: ~G line 7
320: proc  - (prop21Progress) _spin_nvr.tmp:7 (state 10) [(!(np_))]
Never claim moves to line 7 [(!(np_))]
321: proc  9 (CreditCard) scenario3_P3ogress.pml:122 (state 2) [caremCreditcard[i]!reply]
322: proc  7 (CarEmergency) scenario3_P3ogress.pml:86 (state 29) [caremCreditcard[i]?reply]
MSC: ~G line 9
323: proc  - (prop21Progress) _spin_nvr.tmp:9 (state 15) [goto T0_S108]
Never claim moves to line 9 [goto T0_S108]
324: proc  7 (CarEmergency) scenario3_P3ogress.pml:89 (state 30) [caremGarage!request,location,_pid]
spin: trail ends after 324 steps
#processes: 15
324: proc 14 (HandleRental) scenario3_P3ogress.pml:195 (state 11)
324: proc 13 (CreditCard) scenario3_P3ogress.pml:121 (state 3)
324: proc 12 (Damage) scenario3_P3ogress.pml:48 (state 4)  -------------> è nello stato progress
324: proc 11 (CarEmergency) scenario3_P3ogress.pml:66 (state 4)
324: proc 10 (HandleRental) scenario3_P3ogress.pml:195 (state 11)
324: proc  9 (CreditCard) scenario3_P3ogress.pml:121 (state 3)
324: proc  8 (Damage) scenario3_P3ogress.pml:46 (state 2)
324: proc  7 (CarEmergency) scenario3_P3ogress.pml:90 (state 31)
324: proc  6 (User) scenario3_P3ogress.pml:30 (state 14)
324: proc  5 (User) scenario3_P3ogress.pml:30 (state 14)
324: proc  4 (:init:) scenario3_P3ogress.pml:251 (state 4)
324: proc  3 (RentalCar) scenario3_P3ogress.pml:234 (state 21)
324: proc  2 (Truck) scenario3_P3ogress.pml:176 (state 21)
324: proc  1 (Garage) scenario3_P3ogress.pml:142 (state 15)
324: proc  0 (Garage) scenario3_P3ogress.pml:142 (state 15)
MSC: ~G line 69
324: proc  - (prop21Progress) _spin_nvr.tmp:69 (state 126)
15 processes created
Exit-Status 0


***/



/*** Abilitando la weak fairness la p21Progress è soddisfatta:
  Il risultato di verifica è il seguente:



spin -a  scenario3_P3ogress.pml
ltl prop21Progress: (! ([] (<> (! (np_))))) || ([] (<> (damage0)))
gcc -DMEMLIM=3000 -O2 -DBITSTATE -DNFAIR=5 -DXUSAFE -DNOREDUCE -w -o pan pan.c
./pan -m10000000  -a -f -c1 -N prop21Progress
Pid: 3378
warning: only one claim defined, -N ignored
Depth=    1951 States=    1e+06 Transitions= 2.06e+06 Memory=   397.763 t=     6.07 R=   2e+05
Depth=    1951 States=    2e+06 Transitions= 4.14e+06 Memory=   397.763 t=     12.2 R=   2e+05
Depth=    1951 States=    3e+06 Transitions= 6.25e+06 Memory=   397.763 t=     18.4 R=   2e+05
Depth=    1951 States=    4e+06 Transitions= 8.39e+06 Memory=   397.763 t=     24.6 R=   2e+05
Depth=    2050 States=    5e+06 Transitions= 1.06e+07 Memory=   397.763 t=     30.9 R=   2e+05
Depth=    2050 States=    6e+06 Transitions= 1.28e+07 Memory=   397.763 t=       37 R=   2e+05
Depth=    2050 States=    7e+06 Transitions= 1.49e+07 Memory=   397.763 t=     43.2 R=   2e+05
Depth=    2050 States=    8e+06 Transitions=  1.7e+07 Memory=   397.763 t=     49.4 R=   2e+05
Depth=    2050 States=    9e+06 Transitions= 1.93e+07 Memory=   397.763 t=     55.6 R=   2e+05
Depth=    2050 States=    1e+07 Transitions= 2.14e+07 Memory=   397.763 t=     61.8 R=   2e+05
Depth=    2050 States=  1.1e+07 Transitions= 2.36e+07 Memory=   397.763 t=     67.9 R=   2e+05
Depth=    2050 States=  1.2e+07 Transitions= 2.57e+07 Memory=   397.763 t=     74.1 R=   2e+05
Depth=    2050 States=  1.3e+07 Transitions= 2.79e+07 Memory=   397.763 t=     80.5 R=   2e+05
Depth=    2050 States=  1.4e+07 Transitions= 3.01e+07 Memory=   397.763 t=     86.7 R=   2e+05
Depth=    2050 States=  1.5e+07 Transitions= 3.22e+07 Memory=   397.763 t=     93.1 R=   2e+05
Depth=    2050 States=  1.6e+07 Transitions= 3.44e+07 Memory=   397.763 t=     99.3 R=   2e+05
Depth=    2050 States=  1.7e+07 Transitions= 3.74e+07 Memory=   397.763 t=      107 R=   2e+05
Depth=    2050 States=  1.8e+07 Transitions= 4.14e+07 Memory=   397.763 t=      115 R=   2e+05
Depth=    2050 States=  1.9e+07 Transitions= 4.36e+07 Memory=   397.763 t=      121 R=   2e+05
Depth=    2050 States=    2e+07 Transitions= 4.57e+07 Memory=   397.763 t=      128 R=   2e+05
Depth=    2050 States=  2.1e+07 Transitions= 4.79e+07 Memory=   397.763 t=      134 R=   2e+05
Depth=    2050 States=  2.2e+07 Transitions= 5.02e+07 Memory=   397.763 t=      140 R=   2e+05
Depth=    2050 States=  2.3e+07 Transitions= 5.23e+07 Memory=   397.763 t=      147 R=   2e+05
Depth=    2050 States=  2.4e+07 Transitions= 5.45e+07 Memory=   397.763 t=      153 R=   2e+05
Depth=    2050 States=  2.5e+07 Transitions= 5.67e+07 Memory=   397.763 t=      159 R=   2e+05
Depth=    2050 States=  2.6e+07 Transitions=  5.9e+07 Memory=   397.763 t=      166 R=   2e+05
Depth=    2050 States=  2.7e+07 Transitions= 6.12e+07 Memory=   397.763 t=      172 R=   2e+05
Depth=    2050 States=  2.8e+07 Transitions= 6.33e+07 Memory=   397.763 t=      179 R=   2e+05
Depth=    2050 States=  2.9e+07 Transitions= 6.56e+07 Memory=   397.763 t=      185 R=   2e+05
Depth=    2050 States=    3e+07 Transitions= 6.79e+07 Memory=   397.763 t=      191 R=   2e+05
Depth=    2050 States=  3.1e+07 Transitions= 7.01e+07 Memory=   397.763 t=      198 R=   2e+05
Depth=    2050 States=  3.2e+07 Transitions= 7.33e+07 Memory=   397.763 t=      205 R=   2e+05
Depth=    2050 States=  3.3e+07 Transitions= 7.68e+07 Memory=   397.763 t=      213 R=   2e+05
Depth=    2050 States=  3.4e+07 Transitions=  7.9e+07 Memory=   397.763 t=      220 R=   2e+05
Depth=    2050 States=  3.5e+07 Transitions= 8.13e+07 Memory=   397.763 t=      226 R=   2e+05
Depth=    2050 States=  3.6e+07 Transitions= 8.35e+07 Memory=   397.763 t=      232 R=   2e+05
Depth=    2050 States=  3.7e+07 Transitions= 8.58e+07 Memory=   397.763 t=      239 R=   2e+05
Depth=    2050 States=  3.8e+07 Transitions= 8.81e+07 Memory=   397.763 t=      246 R=   2e+05
Depth=    2050 States=  3.9e+07 Transitions= 9.07e+07 Memory=   397.763 t=      252 R=   2e+05
Depth=    2050 States=    4e+07 Transitions= 9.33e+07 Memory=   397.763 t=      259 R=   2e+05
Depth=    2050 States=  4.1e+07 Transitions=  9.6e+07 Memory=   397.763 t=      266 R=   2e+05
Depth=    2050 States=  4.2e+07 Transitions= 9.93e+07 Memory=   397.763 t=      274 R=   2e+05
Depth=    2050 States=  4.3e+07 Transitions= 1.02e+08 Memory=   397.763 t=      281 R=   2e+05
Depth=    2050 States=  4.4e+07 Transitions= 1.04e+08 Memory=   397.763 t=      288 R=   2e+05
Depth=    2050 States=  4.5e+07 Transitions= 1.06e+08 Memory=   397.763 t=      294 R=   2e+05
Depth=    2050 States=  4.6e+07 Transitions= 1.09e+08 Memory=   397.763 t=      302 R=   2e+05
Depth=    2050 States=  4.7e+07 Transitions= 1.13e+08 Memory=   397.763 t=      310 R=   2e+05
Depth=    2050 States=  4.8e+07 Transitions= 1.16e+08 Memory=   397.763 t=      318 R=   2e+05
Depth=    2050 States=  4.9e+07 Transitions= 1.19e+08 Memory=   397.763 t=      326 R=   2e+05
Depth=    2050 States=    5e+07 Transitions= 1.22e+08 Memory=   397.763 t=      335 R=   1e+05
Depth=    2050 States=  5.1e+07 Transitions= 1.25e+08 Memory=   397.763 t=      344 R=   1e+05
Depth=    2050 States=  5.2e+07 Transitions= 1.28e+08 Memory=   397.763 t=      352 R=   1e+05
Depth=    2050 States=  5.3e+07 Transitions= 1.31e+08 Memory=   397.763 t=      361 R=   1e+05
Depth=    2050 States=  5.4e+07 Transitions= 1.34e+08 Memory=   397.763 t=      370 R=   1e+05
Depth=    2050 States=  5.5e+07 Transitions= 1.38e+08 Memory=   397.763 t=      379 R=   1e+05
Depth=    2050 States=  5.6e+07 Transitions= 1.41e+08 Memory=   397.763 t=      389 R=   1e+05
Depth=    2050 States=  5.7e+07 Transitions= 1.45e+08 Memory=   397.763 t=      399 R=   1e+05
Depth=    2050 States=  5.8e+07 Transitions= 1.49e+08 Memory=   397.763 t=      409 R=   1e+05
Depth=    2050 States=  5.9e+07 Transitions= 1.53e+08 Memory=   397.763 t=      419 R=   1e+05
Depth=    2050 States=    6e+07 Transitions= 1.56e+08 Memory=   397.763 t=      429 R=   1e+05
Depth=    2050 States=  6.1e+07 Transitions=  1.6e+08 Memory=   397.763 t=      439 R=   1e+05
Depth=    2050 States=  6.2e+07 Transitions= 1.64e+08 Memory=   397.763 t=      450 R=   1e+05
Depth=    2050 States=  6.3e+07 Transitions= 1.68e+08 Memory=   397.763 t=      462 R=   1e+05
Depth=    2050 States=  6.4e+07 Transitions= 1.72e+08 Memory=   397.763 t=      472 R=   1e+05
Depth=    2050 States=  6.5e+07 Transitions= 1.77e+08 Memory=   397.763 t=      482 R=   1e+05
Depth=    2050 States=  6.6e+07 Transitions= 1.82e+08 Memory=   397.763 t=      493 R=   1e+05
Depth=    2050 States=  6.7e+07 Transitions= 1.88e+08 Memory=   397.763 t=      504 R=   1e+05
Depth=    2050 States=  6.8e+07 Transitions= 1.94e+08 Memory=   397.763 t=      516 R=   1e+05
Depth=    2050 States=  6.9e+07 Transitions=    2e+08 Memory=   397.763 t=      529 R=   1e+05
Depth=    2050 States=    7e+07 Transitions= 2.05e+08 Memory=   397.763 t=      541 R=   1e+05
Depth=    2050 States=  7.1e+07 Transitions= 2.11e+08 Memory=   397.763 t=      553 R=   1e+05
Depth=    2050 States=  7.2e+07 Transitions= 2.18e+08 Memory=   397.763 t=      567 R=   1e+05
Depth=    2050 States=  7.3e+07 Transitions= 2.24e+08 Memory=   397.763 t=      581 R=   1e+05

(Spin Version 6.2.4 -- 8 March 2013)

Bit statespace search for:
 never claim          + (prop21Progress)
 assertion violations + (if within scope of claim)
 acceptance   cycles  + (fairness enabled)
 invalid end states - (disabled by never claim)

State-vector 192 byte, depth reached 2050, errors: 0
 68661837 states, stored (7.33518e+07 visited)
1.5295447e+08 states, matched
2.2630624e+08 transitions (= visited+matched)
   117436 atomic steps

hash factor: 1.82978 (best if > 100.)

bits set per state: 3 (-k3)

Stats on memory usage (in Megabytes):
13358.130 equivalent memory usage for states (stored*(State-vector + overhead))
   16.000 memory used for hash array (-w27)
   38.147 memory used for bit stack
  343.323 memory used for DFS stack (-m10000000)
  397.763 total actual memory usage


unreached in proctype User
 scenario3_P3ogress.pml:39, state 17, "-end-"
 (1 of 17 states)
unreached in proctype Damage
 scenario3_P3ogress.pml:55, state 16, "-end-"
 (1 of 16 states)
unreached in proctype CarEmergency
 scenario3_P3ogress.pml:117, state 55, "-end-"
 (1 of 55 states)
unreached in proctype CreditCard
 scenario3_P3ogress.pml:125, state 6, "-end-"
 (1 of 6 states)
unreached in proctype Garage
 scenario3_P3ogress.pml:151, state 18, "-end-"
 (1 of 18 states)
unreached in proctype Truck
 scenario3_P3ogress.pml:186, state 24, "-end-"
 (1 of 24 states)
unreached in proctype HandleRental
 scenario3_P3ogress.pml:211, state 14, "-end-"
 (1 of 14 states)
unreached in proctype RentalCar
 scenario3_P3ogress.pml:243, state 24, "-end-"
 (1 of 24 states)
unreached in init
 (0 of 4 states)
unreached in claim prop21Progress
 _spin_nvr.tmp:16, state 22, "-end-"
 (1 of 22 states)

pan: elapsed time 587 seconds
No errors found -- did you verify all claims?

*/

