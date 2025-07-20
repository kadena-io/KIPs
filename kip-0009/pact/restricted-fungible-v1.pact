(namespace (read-msg 'ns))

(interface restricted-fungible-v1

  "KIP-0009 Restricted Fungible standard, to be used with `fungible-v2` tokens."

  (defun detect-transfer-restriction:string
      ( sender:string
        receiver:string
        amount:decimal )
    @doc " Implements restriction logic of their token transfers from SENDER to RECEIVER for AMOUNT. \
         \ Returns a `string` value explaining or codifying reason for restriction, \
         \ or `\"\"` (empty string) for success. \
         \ A `fungible-v2` MUST call this function in `transfer`, `transfer-create`, and \
         \ `transfer-crosschain`. The function also allows a 3rd party to test the expected \
         \ outcome of a transfer."
    @model [ (!= sender "")
             (!= receiver "")
             (> amount 0.0) ]
  )

)
