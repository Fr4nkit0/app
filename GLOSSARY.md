# Marilin delivery

The mobile app a driver uses to run a day of water and soda delivery: stops, sales, payments and returnable containers.

## People and the day

**Driver**:
The person who runs the route of the day with the app. The only user of this app.
_Avoid_: Seller, salesman, user

**Stop**:
One customer on the route of the day, in the order the driver visits them.
_Avoid_: Delivery point, waypoint

**Visit**:
What happened at a stop: its sales, payments, container returns and outcome.
_Avoid_: Delivery, call

## Containers

**Container type**:
A kind of returnable container (for example a 20L water jug or a soda siphon), defined by the server's catalog.
_Avoid_: Bottle type, BIDON/SIFON as concepts

**Custody**:
How many containers of each container type a customer holds that belong to the business.
_Avoid_: Container balance, envases en préstamo

**Container movement**:
A record of containers delivered to and returned by a customer, which changes their custody.
_Avoid_: Container transaction

**Container return**:
Containers a customer hands back to the driver, with or without a sale.
_Avoid_: Devolución, pickup

## Money

**Customer account**:
The money a customer owes the business, built from their sales on credit and their payments.
_Avoid_: Balance, wallet, debt record

**Debt**:
The positive amount of a customer account.
_Avoid_: Saldo (when it means debt)

**Payment split**:
How one amount is paid across cash and transfer.
_Avoid_: Payment method (when both are used), Mixto

## Sync

**Pending change**:
A local write the server has not accepted yet.
_Avoid_: Outbox item, queued change

**Reconciliation**:
Combining what the server sent with the pending changes, so neither side's movements are lost.
_Avoid_: Merge, overwrite
