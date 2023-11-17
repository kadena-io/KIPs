(interface kdafs-v1

  (defun kdafs-immutable:bool ()
    @doc "Return true if all objects stored by this module are immutable"
  )

  (defun kdafs-get:object (cid:string)
    @doc "Return a stored object indexed by its CID"
  )
)
