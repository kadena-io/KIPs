(load "fungible-meta-v1.pact")

(module bro-token G
  (defcap G ()
    (enforce false "No"))

  (implements kip.fungible-v2)
  (implements kip.fungible-meta-v1)


  (defconst _SUPPORTED_CHAINS ["0", "1", "2" ])
  (defconst _MAIN_CHAIN "2")

  (defun general-info:object{info-schema} ()
    {'symbol: "BRO",
     'name: "$BRO",
     'description: "Token of Kadena Brothers DAO",
     'img: "https://raw.githubusercontent.com/brothers-DAO/bro-token/refs/heads/main/graphic-assets/basic/BRO_3000_3000.png",
     'logo: "https://raw.githubusercontent.com/brothers-DAO/bro-token/refs/heads/main/graphic-assets/basic/BRO_192_192.png",
     'color: "#eec2a1",
     'socials:[{'type:"website", 'url:"https://bro.pink"},
               {'type:"github",  'url:"https://github.com/brothers-DAO"}]}
  )

  (defun main-chain:string ()
    _MAIN_CHAIN)

  (defun supported-chains:[string] ()
    _SUPPORTED_CHAINS)

  (defun total-supply:decimal ()
    100.0)

  (defun circulating-supply:decimal ()
    (if (= _MAIN_CHAIN (at 'chain-id (chain-data)))
        (- (total-supply) (get-balance "issuance-account"))
        0.0)
  )

  ; Usual fungible-v2 functions ===>

  ; ...

  ; ...

  ; ....
)
