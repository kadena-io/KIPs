(enforce-pact-version "3.7")

(namespace (read-msg 'ns))

(module poly-fungible-reference GOVERNANCE

  (defschema entry
    id:string
    account:string
    balance:decimal
    guard:guard
    )

  (deftable ledger:{entry})

  (use fungible-util)
  (implements poly-fungible-v1)

  (defschema issuer
    guard:guard
  )

  (deftable issuers:{issuer})

  (defschema supply
    supply:decimal
    )

  (deftable supplies:{supply})

  (defconst ISSUER_KEY "I")

  (defcap GOVERNANCE ()
    (enforce-guard (keyset-ref-guard 'swap-ns-admin)))

  (defcap DEBIT (id:string sender:string)
    (enforce-guard
      (at 'guard
        (read ledger (key id sender)))))

  (defcap CREDIT (id:string receiver:string) true)


  (defcap ISSUE ()
    (enforce-guard (at 'guard (read issuers ISSUER_KEY)))
  )

  (defcap MINT (id:string account:string amount:decimal)
    @managed ;; one-shot for a given amount
    (compose-capability (ISSUE))
  )

  (defcap BURN (id:string account:string amount:decimal)
    @managed ;; one-shot for a given amount
    (compose-capability (ISSUE))
  )

  (defcap URI:bool (id:string uri:string) @event true)

  (defcap SUPPLY:bool (id:string supply:decimal) @event true)

  (defun init-issuer (guard:guard)
    (insert issuers ISSUER_KEY {'guard: guard})
  )

  (defun key ( id:string account:string )
    (format "{}:{}" [id account])
  )

  (defun total-supply:decimal (id:string)
    (with-default-read supplies id
      { 'supply : 0.0 }
      { 'supply := s }
      s)
  )

  (defcap TRANSFER:bool
    ( id:string
      sender:string
      receiver:string
      amount:decimal
    )
    @managed amount TRANSFER-mgr
    (enforce-unit id amount)
    (enforce (> amount 0.0) "Positive amount")
    (compose-capability (DEBIT id sender))
    (compose-capability (CREDIT id receiver))
  )

  (defun TRANSFER-mgr:decimal
    ( managed:decimal
      requested:decimal
    )

    (let ((newbal (- managed requested)))
      (enforce (>= newbal 0.0)
        (format "TRANSFER exceeded for balance {}" [managed]))
      newbal)
  )

  (defconst MINIMUM_PRECISION 12)

  (defun enforce-unit:bool (id:string amount:decimal)
    (enforce
      (= (floor amount (precision id))
         amount)
      "precision violation")
  )

  (defun truncate:decimal (id:string amount:decimal)
    (floor amount (precision id))
  )


  (defun create-account:string
    ( id:string
      account:string
      guard:guard
    )
    (enforce-valid-account account)
    (insert ledger (key id account)
      { "balance" : 0.0
      , "guard"   : guard
      , "id" : id
      , "account" : account
      })
    )

  (defun get-balance:decimal (id:string account:string)
    (at 'balance (read ledger (key id account)))
    )

  (defun details:object{poly-fungible-v1.account-details}
    ( id:string account:string )
    (read ledger (key id account))
    )

  (defun rotate:string (id:string account:string new-guard:guard)
    (with-read ledger (key id account)
      { "guard" := old-guard }

      (enforce-guard old-guard)

      (update ledger (key id account)
        { "guard" : new-guard }))
    )


  (defun precision:integer (id:string)
    MINIMUM_PRECISION)

  (defun transfer:string
    ( id:string
      sender:string
      receiver:string
      amount:decimal
    )

    (enforce (!= sender receiver)
      "sender cannot be the receiver of a transfer")
    (enforce-valid-transfer sender receiver (precision id) amount)


    (with-capability (TRANSFER id sender receiver amount)
      (debit id sender amount)
      (with-read ledger (key id receiver)
        { "guard" := g }
        (credit id receiver g amount))
      )
    )

  (defun transfer-create:string
    ( id:string
      sender:string
      receiver:string
      receiver-guard:guard
      amount:decimal
    )

    (enforce (!= sender receiver)
      "sender cannot be the receiver of a transfer")
    (enforce-valid-transfer sender receiver (precision id) amount)

    (with-capability (TRANSFER id sender receiver amount)
      (debit id sender amount)
      (credit id receiver receiver-guard amount))
    )

  (defun mint:string
    ( id:string
      account:string
      guard:guard
      amount:decimal
    )
    (with-capability (MINT id account amount)
      (with-capability (CREDIT id account)
        (credit id account guard amount)))
  )

  (defun burn:string
    ( id:string
      account:string
      amount:decimal
    )
    (with-capability (BURN id account amount)
      (with-capability (DEBIT id account)
        (debit id account amount)))
  )

  (defun debit:string
    ( id:string
      account:string
      amount:decimal
    )

    (require-capability (DEBIT id account))

    (enforce-unit id amount)

    (with-read ledger (key id account)
      { "balance" := balance }

      (enforce (<= amount balance) "Insufficient funds")

      (update ledger (key id account)
        { "balance" : (- balance amount) }
        ))
    (update-supply id (- amount))
  )


  (defun credit:string
    ( id:string
      account:string
      guard:guard
      amount:decimal
    )

    (require-capability (CREDIT id account))

    (enforce-unit id amount)

    (with-default-read ledger (key id account)
      { "balance" : 0.0, "guard" : guard }
      { "balance" := balance, "guard" := retg }
      (enforce (= retg guard)
        "account guards do not match")

      (write ledger (key id account)
        { "balance" : (+ balance amount)
        , "guard"   : retg
        , "id"   : id
        , "account" : account
        })

      (update-supply id amount)
      ))

  (defun update-supply (id:string amount:decimal)
    (with-default-read supplies id
      { 'supply: 0.0 }
      { 'supply := s }
      (write supplies id {'supply: (+ s amount)}))
  )

  (defpact transfer-crosschain:string
    ( id:string
      sender:string
      receiver:string
      receiver-guard:guard
      target-chain:string
      amount:decimal )
    (step (enforce false "cross chain not supported"))
    )

  (defun get-ids ()
    "Get all token identifiers"
    (keys supplies))

  (defun uri:string (id:string) "Unsupported" "")

)
