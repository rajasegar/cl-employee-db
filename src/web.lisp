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

(defun get-param (name parsed)
  (cdr (assoc name parsed :test #'string=)))

;; create employees
(defroute ("/employees" :method :POST) (&key _parsed)
  (print _parsed)
  (with-connection (db)
    (execute
     (insert-into :employees
       (set= :ssn (get-param "ssn" _parsed)
             :name (get-param "name" _parsed)
             :lastname (get-param "lastname" _parsed)
             :department (get-param "department" _parsed))))

    (let ((employees (retrieve-all
                      (select :*
                        (from :employees)))))
      (format t "~a~%" employees)
      (render #P"employees.html" (list :employees employees)))))

;; edit employee
(defroute "/employees/edit/:ssn" (&key ssn)
  (with-connection (db)
  (let ((departments (retrieve-all
      (select :*
        (from :departments))))
        (employee (retrieve-one
                   (select :*
                     (from :employees)
                     (where (:= :ssn ssn))))))
  (render #P"edit-employee.html" (list :departments departments :employee employee)))))

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
