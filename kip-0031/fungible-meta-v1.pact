(interface fungible-meta-v1
  @doc "Provides several meta-data informations for the token"

  (defschema social-schema
    type:string
    url:string
  )

  (defschema info-schema
    symbol:string
    name:string
    description:string
    img:string
    logo:string
    color:string
    socials:[object{social-schema}]
  )

  (defun general-info:object{info-schema} ()
    @doc "Return general information about a token")

  (defun main-chain:string ()
    @doc "Return the main chain (if any) of the token")

  (defun supported-chains:[string] ()
    @doc "Return the list of chains supported by the token")

  (defun total-supply:decimal ()
    @doc "Return the total supply of the token")

  (defun circulating-supply:decimal ()
    @doc "Returns the circulating supply of the token")

)
