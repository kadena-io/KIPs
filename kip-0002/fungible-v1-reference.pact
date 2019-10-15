
(module fungible-v1-reference GOV
  "Minimal implementation of 'fungible-v1' standard."

  (implements fungible-v1)

  (defschema account-schema
    balance:decimal
    guard:guard)

  (deftable ledger:{account-schema})

  (defcap GOV () true)

  (defcap DEBIT (sender:string amount:decimal)
    "Debit is protected by SENDER guard."
    (enforce-guard (at 'guard (read ledger sender)))
    (enforce (!= sender "") "valid sender")
  )

  (defcap CREDIT (receiver:string amount:decimal)
    "Credit marker guard."
    (enforce (!= receiver "") "valid receiver")
  )

  (defcap TRANSFER:bool
    ( sender:string
      receiver:string
      amount:decimal
    )
    @managed TRANSFER-mgr
    (enforce (!= sender receiver) "same sender and receiver")
    (enforce-unit amount)
    (compose-capability (DEBIT sender amount))
    (compose-capability (CREDIT receiver amount))
  )

  (defun TRANSFER-mgr:object{fungible-v1.transfer-schema}
    ( managed:object{fungible-v1.transfer-schema}
      requested:object{fungible-v1.transfer-schema}
    )
    (enforce (= (at 'sender managed) (at 'sender requested)) "sender match")
    (enforce (= (at 'receiver managed) (at 'receiver requested)) "sender match")
    (let* ((bal:decimal (at 'amount managed))
           (amt:decimal (at 'amount requested))
           (rem:decimal (- bal amt)))
      (enforce (>= rem 0.0) (format "TRANSFER exceeded for balance {}" bal))
      (+ { 'amount: rem } managed))
  )

  (defun transfer:string
    ( sender:string
      receiver:string
      amount:decimal
      )
    (transfer-create
     sender
     receiver
     (at 'guard (read ledger sender))
     amount)
  )

  (defun transfer-create:string
    ( sender:string
      receiver:string
      receiver-guard:guard
      amount:decimal
    )
    (with-capability (TRANSFER sender receiver amount)
      (debit sender amount)
      (credit receiver receiver-guard amount)
    )
  )

  (defun debit (sender:string amount:decimal)
    (require-capability (DEBIT sender amount))
    (with-read ledger sender
      { 'balance:= bal }
      (enforce (>= bal amount) "Insufficient funds")
      (update ledger sender
        { 'balance: (- bal amount)
        }))
  )

  (defun credit (receiver:string receiver-guard:guard amount:decimal)
    (require-capability (CREDIT receiver amount))
    (with-default-read ledger receiver
      { 'balance: 0.0
      , 'guard: receiver-guard }
      { 'balance := rbal
      , 'guard := rguard }
      (enforce (= rguard receiver-guard) "Invalid receiver guard")

      (write ledger receiver
             { 'balance: (+ rbal amount)
             , 'guard: rguard
             }))
  )

  (defschema spv-schema
    receiver:string
    receiver-guard:guard
    amount:decimal)

  (defpact transfer-chain:string
    ( sender:string
      receiver:string
      receiver-guard:guard
      target-chain:string
      amount:decimal
    )
    @model [ (property (> amount 0.0))
             (property (!= sender ""))
             (property (!= receiver ""))
             (property (!= sender receiver))
             (property (!= target-chain ""))
           ]
   (step
     (with-capability (TRANSFER sender receiver amount)

       (enforce (!= "" target-chain) "empty target-chain")
       (enforce (!= (at 'chain-id (chain-data)) target-chain)
         "cannot run cross-chain transfers to the same chain")

       (enforce-unit amount)

       ;; step 1 - debit sender on current chain
       (debit sender amount)

       (yield
         (let ((v:object{spv-schema}
                { "receiver" : receiver
                , "receiver-guard" : receiver-guard
                , "amount" : amount
                }))
            v)
         target-chain)))

   (step
     (resume
       { "receiver" := receiver
       , "receiver-guard" := receiver-guard
       , "amount" := amount
       }
       (with-capability (CREDIT receiver amount)
         (credit receiver receiver-guard amount))
       ))
   )

  (defun get-balance:decimal
    ( account:string
    )
    (at 'balance (read ledger account))
  )

  (defun details:object{fungible-v1.account-details}
    ( account:string
    )
    (with-read ledger account
      { 'balance:= b
      , 'guard:= g
      }
      { 'balance: b
      , 'guard: g
      , 'account: account
      })
  )

  (defun precision:integer
    ()
    12
  )

  (defun enforce-unit:bool
    ( amount:decimal
    )
    (enforce (> amount 0.0) "Amount must be positive.")
    (enforce
      (= (floor amount (precision)) amount)
      "Minimum precision failed")
  )

  (defun create-account:string
    ( account:string
      guard:guard
    )
    (insert ledger account {'balance: 0.0, 'guard:guard})
    "Account created"
  )

  (defun rotate:string
    ( account:string
      new-guard:guard
    )
    (enforce-guard (at 'guard (read ledger account)))
    (update ledger account { 'guard: new-guard })
  )

)
