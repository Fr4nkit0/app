# Reconciliation is server value plus pending changes

When a sync download arrives, both the customer account and custody are set to the value the server sent plus the local pending changes the server has not accepted yet. Before this, custody skipped the server value entirely while a customer had anything unsent, so office-side adjustments could stay invisible to the driver until the queue drained; one rule for both ledgers keeps the server authoritative without losing local movements.
