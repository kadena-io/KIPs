(enforce-pact-version "3.7")

(namespace (read-msg 'ns))

(interface poly-fungible-v1

  (defschema account-details
    @doc
      " Account details: token ID, account name, balance, and guard."
    token:string
    account:string
    balance:decimal
    guard:guard)

  (defcap TRANSFER:bool
    ( token:string
      sender:string
      receiver:string
      amount:decimal
    )
    @doc
      " Manage transferring AMOUNT of TOKEN from SENDER to RECEIVER. \
      \ As event, also used to notify burn and create."
    @managed amount TRANSFER-mgr
  )

  (defun TRANSFER-mgr:decimal
    ( managed:decimal
      requested:decimal
    )
    @doc " Manages TRANSFER cap AMOUNT where MANAGED is the installed quantity \
         \ and REQUESTED is the quantity attempting to be granted."
  )

  (defun precision:integer (token:string)
    @doc
      " Return maximum decimal precision for TOKEN."
  )

  (defun enforce-unit:bool
    ( token:string
      amount:decimal
    )
    @doc
      " Enforce that AMOUNT meets minimum precision allowed for TOKEN."
  )

  (defun create-account:string
    ( token:string
      account:string
      guard:guard
    )
    @doc
      " Create ACCOUNT for TOKEN with 0.0 balance, with GUARD controlling access."
    @model
      [ (property (!= token ""))
        (property (!= account ""))
      ]
  )

  (defun get-balance:decimal
    ( token:string
      account:string
    )
    @doc
      " Get balance of TOKEN for ACCOUNT. Fails if account does not exist."
  )

  (defun details:object{account-details}
    ( token:string
      account:string
    )
    @doc
      " Get details of ACCOUNT under TOKEN. Fails if account does not exist."
  )

  (defun rotate:string
    ( token:string
      account:string
      new-guard:guard )
    @doc
      " Rotate guard for ACCOUNT for TOKEN to NEW-GUARD, validating against existing guard."
    @model
      [ (property (!= token ""))
        (property (!= account ""))
      ]

  )

  (defun transfer:string
    ( token:string
      sender:string
      receiver:string
      amount:decimal
    )
    @doc
      " Transfer AMOUNT of TOKEN between accounts SENDER and RECEIVER. \
      \ Fails if SENDER does not exist. Managed by TRANSFER."
    @model
      [ (property (> amount 0.0))
        (property (!= token ""))
        (property (!= sender ""))
        (property (!= receiver ""))
        (property (!= sender receiver))
      ]
  )

  (defun transfer-create:string
    ( token:string
      sender:string
      receiver:string
      receiver-guard:guard
      amount:decimal
    )
    @doc
      " Transfer AMOUNT of TOKEN between accounts SENDER and RECEIVER. \
      \ If RECEIVER exists, RECEIVER-GUARD must match existing guard; \
      \ if RECEIVER does not exist, account is created. \
      \ Managed by TRANSFER."
    @model
      [ (property (> amount 0.0))
        (property (!= token ""))
        (property (!= sender ""))
        (property (!= receiver ""))
        (property (!= sender receiver))
      ]
  )

  (defpact transfer-crosschain:string
    ( token:string
      sender:string
      receiver:string
      receiver-guard:guard
      target-chain:string
      amount:decimal
    )
    @doc
      " Transfer AMOUNT of TOKEN between accounts SENDER on source chain \
      \ and RECEIVER on TARGET-CHAIN. If RECEIVER exists, RECEIVER-GUARD \
      \ must match existing guard. If RECEIVER does not exist, account is created."
    @model
      [ (property (> amount 0.0))
        (property (!= token ""))
        (property (!= sender ""))
        (property (!= receiver ""))
        (property (!= target-chain ""))
      ]
  )

)
