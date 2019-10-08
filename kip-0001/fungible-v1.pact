
(interface fungible-v1
  " Standard for fungible coins and tokens as specified in KIP-0002. "

  (defun transfer:string
    ( sender:string
      receiver:string
      amount:decimal
    )
    @doc " Transfer AMOUNT between accounts SENDER and RECEIVER. \
         \ Fails if SENDER or RECEIVER accounts do not exist. \
         \ Subject to management by TRANSFER capability. "
    @model [ (property (> amount 0.0))
             (property (!= sender ""))
             (property (!= receiver ""))
             (property (!= sender receiver)) ]
  )

  (defun transfer-create:string
    ( sender:string
      receiver:string
      receiver-guard:guard
      amount:decimal
    )
    @doc " Transfer AMOUNT between accounts SENDER and RECEIVER. \
         \ Fails if SENDER does not exist. If RECEIVER exists, guard \
         \ must match existing value. If RECEIVER does not exist, \
         \ RECEIVER account is created using RECEIVER-GUARD. \
         \ Subject to management by TRANSFER capability."
    @model [ (property (> amount 0.0))
             (property (!= sender ""))
             (property (!= receiver ""))
             (property (!= sender receiver)) ]
  )

  (defun balance:decimal
    ( account:string
    )
    " Get balance for ACCOUNT. Fails if account does not exist."
  )

  (defun details:object
    ( account: string
    )
    " Get an object with 'balance' and 'guard' values for ACCOUNT. \
    \ Fails if account does not exist."
  )

  (defun precision:integer
    ()
    "Return the maximum allowed decimal precision."
  )

  (defun enforce-unit:string
    ( amount:decimal
    )
    " Enforce minimum precision allowed for transactions."
  )

  (defun create-account:string
    ( account:string
      guard:guard
    )
    " Create ACCOUNT with 0.0 balance, with GUARD controlling access."
  )

  (defun rotate:string
    ( account:string
      new-guard:guard
    )
    " Rotate guard for ACCOUNT. Transaction is validated against \
    \ existing guard before installing new guard. "
  )

)
