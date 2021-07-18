(in-package :cl-user)
(defpackage cl-employee-db.web
  (:use :cl
        :caveman2
        :cl-employee-db.config
        :cl-employee-db.view
        :cl-employee-db.db
        :datafly
        :sxql)
  (:export :*web*))
(in-package :cl-employee-db.web)

;; for @route annotation
(syntax:use-syntax :annot)

;;
;; Application

(defclass <web> (<app>) ())
(defvar *web* (make-instance '<web>))
(clear-routing-rules *web*)

;;
;; Routing rules

(defroute "/" ()
  (render #P"index.html"))

(defroute "/employees" ()
    (let ((employees (with-connection (db)
    (retrieve-all
      (select :*
        (from :employees))))))
    (format t "~a~%" employees)
  (render #P"employees.html" (list :employees employees))))

;;
;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
