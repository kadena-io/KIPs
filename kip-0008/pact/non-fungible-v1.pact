
(namespace (read-msg 'ns))

(interface non-fungible-v1

  "KIP-0008 Non-fungible token standard."

  ;;
  ;; Events/Capabilities
  ;;

  (defcap TRANSFER:bool
      ( sender:string
        receiver:string
        id:string )
    @doc "Controls transfer of ID from SENDER to RECEIVER."
    @managed ;; one-shot
    )

  (defcap ROTATE:bool
    ( account:string )
    @doc "Controls rotation of ACCOUNT."
    @managed ;; one-shot
    )

  (defcap ACCOUNT:bool
    ( account:string
      guard:guard )
    @doc "Notifies creation or rotation of ACCOUNT to GUARD."
    @event
    )

  (defcap SEND-CROSSCHAIN:bool
    ( sender:string
      receiver:string
      receiver-guard:guard
      target-chain:string
      id:string )
    @doc "Notifies initial step of 'transfer-crosschain' on source chain."
    @event
    )

  (defcap RECEIVE-CROSSCHAIN:bool
    ( sender:string
      receiver:string
      receiver-guard:guard
      source-chain:string
      id:string )
    @doc "Notifies final step of 'transfer-crosschain' on target chain."
    @event
    )

  (defcap ITEM:bool
    ( id:string )
    @doc " Notifies of the creation/existence of ID as an NFT. \
         \ This can be used to assure presence of an NFT in a cross-chain \
         \ transaction. If so, implementors should accept a field 'proof' \
         \ in the cross-chain transaction that verifies existence of the \
         \ item on the target chain."
    @event
    )

  ;;
  ;; Query/read-only operations
  ;;

  (defun balance-of:integer
      ( account:string )
    @doc "Count all NFTs owned by ACCOUNT."
    )

  (defun owner-of:string
      ( id:string )
    @doc "Returns account of owner of ID."
    )

  (defschema account-details
    @doc "Schema for results of 'details' operation."
    account:string
    guard:guard
    )

  (defun details:object{account-details}
    ( account: string )
    @doc " Get an object with details of ACCOUNT. \
         \ Fails if account does not exist."
    )

  ;;
  ;; Transactional operations
  ;;

  (defun transfer:string
      ( sender:string
        receiver:string
        id:string )
    @doc " Transfers ownership of ID from SENDER to RECEIVER. \
         \ Managed by 'TRANSFER' capability."
    @model [ (property (!= sender ""))
             (property (!= receiver ""))
             (property (!= id ""))
             (property (!= sender receiver))
           ]
    )

  (defun transfer-create:string
      ( sender:string
        receiver:string
        receiver-guard:guard
        id:string )
    @doc " Transfers ownership of ID from SENDER to RECEIVER, \
         \ creating RECEIVER account if necessary with RECEIVER-GUARD. \
         \ Fails if account exists and GUARD does not match. \
         \ Managed by 'TRANSFER' capability. \
         \ Emits ACCOUNT for newly-created accounts."
    @model [ (property (!= sender ""))
             (property (!= receiver ""))
             (property (!= id ""))
             (property (!= sender receiver))
           ]
    )

  (defpact transfer-crosschain:string
    ( sender:string
      receiver:string
      receiver-guard:guard
      target-chain:string
      id:string )
    @doc " 2-step pact to transfer ownership of ID \
         \ from SENDER on current chain to RECEIVER on TARGET-CHAIN, \
         \ creating RECEIVER account if necessary with RECEIVER-GUARD. \
         \ Step 1 emits SEND-CROSSCHAIN event on source chain. \
         \ Step 2 emits RECEIVE-CROSSCHAIN event on target chain. \
         \ Step 2 emits ACCOUNT for newly-created accounts. \
         \ See note in ITEM event docs for including a 'proof' field \
         \ in the message data for ensuring ID exists on target chain."
    @model [ (property (!= sender ""))
             (property (!= receiver ""))
             (property (!= id ""))
             (property (!= target-chain ""))
           ]
    )

  (defun create-account:string
      ( account:string
        guard:guard
        )
    @doc " Create ACCOUNT with 0.0 balance, with GUARD controlling access. \
         \ Emits ACCOUNT event."
    @model [ (property (!= account "")) ]
    )

  (defun rotate:string
      ( account:string
        new-guard:guard
        )
    @doc " Rotate guard for ACCOUNT. Transaction is validated against \
         \ existing guard before installing new guard. \
         \ Controlled by ROTATE capability. Emits ACCOUNT event."
    @model [ (property (!= account "")) ]
    )

)
