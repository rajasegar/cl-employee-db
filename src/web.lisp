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

;; create employees
(defroute ("/employees" :method :POST) (&key _parsed)
  (print _parsed)
    (let ((employees (with-connection (db)
    (retrieve-all
      (select :*
        (from :employees))))))
    (format t "~a~%" employees)
  (render #P"employees.html" (list :employees employees))))

(defroute "/employees/new" ()
    (let ((departments (with-connection (db)
    (retrieve-all
      (select :*
        (from :departments))))))
  (render #P"new-employee.html" (list :departments departments))))


(defroute "/departments" ()
    (let ((departments (with-connection (db)
    (retrieve-all
      (select :*
        (from :departments))))))
    (format t "~a~%" departments)
  (render #P"departments.html" (list :departments departments))))
;;
;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
