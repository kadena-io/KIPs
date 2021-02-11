
(namespace (read-msg 'ns))

(module non-fungible-v1-reference GOV

  "KIP-0008 Non-fungible token standard reference implementation."

  (implements non-fungible-v1)

  (defcap GOV () true)

  (defschema account
    guard:guard)

  (deftable accounts:{account})

  (defschema item
    owner:string)

  (deftable items:{item})

  ;;
  ;; Events/Capabilities
  ;;

  (defcap TRANSFER:bool
    ( sender:string
      receiver:string
      id:string )
    @doc "Controls transfer of ID from SENDER to RECEIVER."
    @managed ;; one-shot
    (map (validate-identifier) [sender receiver id])
    (enforce-guard (at 'guard (read accounts sender)))
    (let ((owner (owner-of id)))
      (enforce (= sender owner) "Sender is not owner"))
  )

  (defcap ROTATE:bool
    ( account:string )
    @doc "Controls rotation of ACCOUNT."
    @managed ;; one-shot
    (validate-identifier account)
    (enforce-guard (at 'guard (read accounts account)))
  )

  (defcap ACCOUNT:bool
    ( account:string
      guard:guard )
    @doc "Notifies creation or rotation of ACCOUNT to GUARD."
    @event
    (validate-identifier account)
  )

  (defcap SEND-CROSSCHAIN:bool
    ( sender:string
      receiver:string
      receiver-guard:guard
      target-chain:string
      id:string )
    @doc "Notifies initial step of 'transfer-crosschain' on source chain."
    @event
    true
  )

  (defcap RECEIVE-CROSSCHAIN:bool
    ( sender:string
      receiver:string
      receiver-guard:guard
      source-chain:string
      id:string )
    @doc "Notifies final step of 'transfer-crosschain' on target chain."
    @event
    true
  )

  (defcap ITEM:bool
    ( id:string )
    @doc " Notifies of the creation/existence of ID as an NFT. \
         \ This can be used to assure presence of an NFT in a cross-chain \
         \ transaction. If so, implementors should accept a field 'proof' \
         \ in the cross-chain transaction that verifies existence of the \
         \ item on the target chain."
    @event
    true
  )

  ;;
  ;; Query/read-only operations
  ;;

  (defun balance-of:integer
      ( account:string )
    @doc "Count all NFTs owned by ACCOUNT."
    ;; EXTREMELY unperformant method. Better to index with a separate table.
    (length (select items (where 'owner (= account))))
  )

  (defun owner-of:string
      ( id:string )
    @doc "Returns account of owner of ID."
    (at 'owner (read items id))
  )

  (defun details:object{non-fungible-v1.account-details}
    ( account: string )
    @doc " Get an object with details of ACCOUNT. \
         \ Fails if account does not exist."
    { 'account: account, 'guard: (at 'guard (read accounts account)) }
  )

  ;;
  ;; Utilities
  ;;


  (defun validate-identifier (account:string)
    (enforce (!= "" account) "Empty identifier"))

  (defun create-maybe (account:string guard:guard)
    (let ((dummy (create-user-guard (validate-identifier account))))
      (with-default-read accounts account
        { 'guard: dummy }
        { 'guard := g }
        (if (= g dummy)
            (create-account account guard)
          (if (enforce (= g guard) "Account guard mismatch")
            "Account already exists" "")))))

  (defconst NULL_OWNER "NULL_OWNER")

  (defun null-owner-guard ()
    (create-module-guard NULL_OWNER))


  ;;
  ;; Transactional operations
  ;;

  (defun transfer:string
    ( sender:string
      receiver:string
      id:string )
    @doc " Transfers ownership of ID from SENDER to RECEIVER. \
         \ Managed by 'TRANSFER' capability."
    (with-capability (TRANSFER sender receiver id)
        (validate-identifier sender)
        (enforce (!= sender receiver) "Same transfer")
        (read accounts receiver) ;; enforces active receiver
        (update items id { 'owner: receiver }))
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
    (with-capability (TRANSFER sender receiver id)
        (enforce (!= sender receiver) "Same transfer")
        (create-maybe receiver receiver-guard)
        (update items id { 'owner: receiver }))
  )

  (defschema xchain source-chain:string)

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
         \ Step 1 is controlled by TRANSFER capability. \
         \ Step 2 emits RECEIVE-CROSSCHAIN event on target chain. \
         \ Step 2 emits ACCOUNT for newly-created accounts."
    (step
      (with-capability (TRANSFER sender receiver id)
        (with-capability (SEND-CROSSCHAIN sender receiver receiver-guard target-chain id)
          (update items id { 'owner: NULL_OWNER })
          (validate-identifier target-chain)
          (let ((r:object{xchain} { 'source-chain: (at 'chain-id (chain-data)) }))
            (yield r target-chain)))))
    (step
      (resume { 'source-chain:= source-chain }
        (with-capability (RECEIVE-CROSSCHAIN sender receiver receiver-guard source-chain id)
          (create-maybe receiver receiver-guard)
          (update items id { 'owner: receiver }))))
  )

  (defun create-account:string
    ( account:string
      guard:guard
      )
    @doc " Create ACCOUNT with 0.0 balance, with GUARD controlling access. \
         \ Emits ACCOUNT event."
    (with-capability (ACCOUNT account guard)
        (insert accounts account { 'guard: guard }))
  )

  (defun rotate:string
    ( account:string
      new-guard:guard
      )
    @doc " Rotate guard for ACCOUNT. Transaction is validated against \
         \ existing guard before installing new guard. \
         \ Controlled by ROTATE capability. Emits ACCOUNT event."
    (with-capability (ROTATE account)
        (with-capability (ACCOUNT account new-guard)
            (update accounts account { 'guard: new-guard })))
  )

  ;; item management
  (defun create-item (id:string owner:string)
    (with-capability (ITEM id)
      (insert items id { 'owner: owner }))
  )

)


(create-table accounts)
(create-table items)
(create-account NULL_OWNER (null-owner-guard))
