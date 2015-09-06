In this project I model a system of a digital car emergency with a set of different parallel processes that communicate with message passing and shared variables. <br/>
* Process User: this process represents the user actions 
* Process Damage: models in a non-deterministic way possible damages of the car
* Process CarEmergency: models the diagnotisc system, able to detect damages and interacts with external entities (a truck, and a garage and a user credit card)
* Process Truck: models the truck 
* Process Garage: models the garage <br/> 
* Process CreditCard: models the credit card for payments <br/>

There are 3 scenarios in the project, each one models a system with certain contraints or behaviour. <br/>
For each scenario I verifed some properties of correctenss as invariants or as LTL properties. 

### Usage: 
to experiment with the project you need to install [Spin](http://spinroot.com/spin/whatispin.html) model checker. <br\>
I recommand also to install the tool ispin, open the files modeling the propterties and run the checker. <br/>
For more instrunctions, mailto hind.chf@gmail.com :-)
