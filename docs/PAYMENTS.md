# Payments deferred

Payments are outside the active scope of this component library. Current work
focuses on reading and writing explicitly supported card profiles, Delphi packages,
examples and stability. EMV inspection reads card data; it does not authorize,
submit or settle transactions.

After the read/write components have been validated and stabilized, payment work
can be reconsidered as a separate integration: a concrete terminal/provider first,
and a separately maintained direct NFC kernel where a reader, scheme and processor
support it. There is no payment API, provider adapter or transaction kernel in the
current packages, and no planned payment implementation in the next batches.
