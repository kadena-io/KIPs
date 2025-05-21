(module kdafs-store-one GOVERNANCE
  (implements kip.kdafs-v1)
  (use free.util-time)

  (defcap GOVERNANCE ()
    false)

  (defschema storage-sch
    data:object ; Data itself
    storage-time:time ; The storage date
  )

  (deftable storage-table:{storage-sch})

  ;; ---------------------------------------------------------------------------
  ;; Interface implementation
  ;; ---------------------------------------------------------------------------
  (defun kdafs-immutable:bool ()
    @doc "Always true because objects stored by this module are immutable"
    true)

  (defun kdafs-get:object (cid:string)
    @doc "Return a stored object indexed by its CID"
    (with-read storage-table cid {'data:=data}
      data))

  ;; ---------------------------------------------------------------------------
  ;; Storage function
  ;; ---------------------------------------------------------------------------
  (defun store:string (obj-to-store:object)
    @doc "Store the given object and return the CID"
    (let ((cid (hash obj-to-store)))
      (insert storage-table cid {'data:obj-to-store,
                                 'storage-time: (now)})
      cid)
  )

  ;; ---------------------------------------------------------------------------
  ;; Metadata (out of the interface)
  ;; ---------------------------------------------------------------------------
  (defun get-storage-time:time (cid:string)
    @doc "Return the storage time of the object"
    (with-read storage-table cid {'storage-time:=t}
      t))

)
