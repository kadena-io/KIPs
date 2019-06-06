
(interface fungible-token-v1

  @doc
  " FungibleToken represents a transferrable undifferentiated token. \
  \ Authors: Stuart Popejoy, Emily Pillmore"


  (defun transfer:string
    (
      sender:string
      reciever:string
      receiver-guard:guard
      amount:decimal
    )

    @doc
    " Transfer AMOUNT between accounts SENDER and RECEIVER on the \
    \ same chain. Creates RECEIVER account using RECEIVER-GUARD if \
    \ account does not already exist."

    @model [
      (property (> amount 0.0))
    ]
  )

  (defun transfer-to:string
    (
      sender:string
      reciever:string
      amount:decimal
    )

    @doc
    " Transfer AMOUNT between accounts SENDER and RECEIVER on the \
    \ same chain. Fails if RECEIVER account does not already exist."

    @model [
      (property (> amount 0.0))
    ]
  )

  (defun create-account:string
    (
      account:string
      guard:guard
    )

    @doc
    " Create ACCOUNT with GUARD and zero balance. Fails if account \
    \ already exists."
  )

  (defun get-balance:decimal
    (
      account:string
    )

    @doc
    " Get balance for ACCOUNT. Fails if account does not exist."

    @model [
      (property (result >= 0.0))
    ]
  )


)
