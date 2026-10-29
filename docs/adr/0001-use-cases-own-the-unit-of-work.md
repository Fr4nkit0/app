# Use cases own the unit of work

Repositories never open their own Drift transaction: every write that touches more than one entity (a sale with its payments and container movements, a debt payment with the customer account and the pending change) goes through a use case that opens one unit of work via the `TransactionRunner` port. We chose this over transactions inside each repository because nested, hidden transactions made the atomic boundary of an operation invisible and let the UI write multi-entity changes by calling a repository directly.
