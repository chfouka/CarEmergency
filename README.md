## Info:
In this project I model a system of a digital car emergency with a set of different parallel processes that communicate with message passing and shared variables. <br/>
Process User: this process represents the user actions <br/>
Process Damage: models in a non-deterministic way possible damages of the car <br/>
Process CarEmergency: models the diagnotisc system, able to detect damages and interacts with external entities (a truck, and a garage and a user credit card) <br/>
Process Truck: models the truck <br/>
Process Garage: models the garage <br/> 
Process CreditCard: models the credit card for payments <br/>

There are 3 scenarios in the project, each one models a system with certain contraints or behaviour. <br/>
For each scenario I verifed some properties of correctenss as invariants or as LTL properties. 

### Usage: 
to experiment with the project you need to install [Spin](http://spinroot.com/spin/whatispin.html) model checker. <br\>
I recommend to install the tool ispin, which provide a simple GUI to spin. <br/>
Open the files modeling the propterties and run the checker. These files have the suffixes P1/P2 etc. in the project <br/>
For more instrunctions, mailto hind.chf@gmail.com :-)
