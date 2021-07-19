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

(defun get-param (name parsed)
  "Get param value from _parsed"
  (cdr (assoc name parsed :test #'string=)))
;;
;; Routing rules

(defroute "/" ()
  (render #P"index.html"))

(defroute "/employees" ()
    (let ((employees (with-connection (db)
    (retrieve-all
     (select (:ssn
	      :lastname
       (:as :employees.name :name)
       (:as :departments.name :department))
       (from :employees)
       (inner-join :departments :on (:= :employees.department :departments.code)))))))
    (format t "~a~%" employees)
  (render #P"employees/index.html" (list :employees employees))))

;; employees#new
(defroute "/employees/new" ()
    (let ((departments (with-connection (db)
    (retrieve-all
      (select :*
        (from :departments))))))
  (render #P"employees/new.html" (list :departments departments))))


;; employees#create
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
      (render #P"employees/index.html" (list :employees employees)))))

;; employees#show
(defroute "/employees/:ssn" (&key ssn)
  (with-connection (db)
    (let ((employee (retrieve-one
		     (select (:ssn
			      :lastname
			      (:as :employees.name :name)
			      (:as :departments.name :department))
		       (from :employees)
		       (inner-join :departments :on (:= :employees.department :departments.code))
		       (where (:= :ssn ssn))))))
      (render #P"employees/show.html" (list :employee employee)))))

;; edit employee
(defroute "/employees/:ssn/edit" (&key ssn)
  (with-connection (db)
  (let ((departments (retrieve-all
      (select :*
        (from :departments))))
        (employee (retrieve-one
                   (select :*
                     (from :employees)
                     (where (:= :ssn ssn))))))
  (render #P"employees/edit.html" (list :departments departments :employee employee)))))

;; update employee
(defroute ("/employees/:ssn/update" :method :POST) (&key ssn _parsed)
  (with-connection (db)
    (let ((name (get-param "name" _parsed))
	  (lastname (get-param "lastname" _parsed))
	  (department (get-param "department" _parsed)))
    (execute
     (update :employees
       (set=
	:name name
	:lastname lastname
	:department department)
       (where (:= :ssn ssn))))
      (redirect (concatenate 'string "/employees/" ssn)))))

;; delete employee
(defroute "/employees/:ssn/delete" (&key ssn)
  (with-connection (db)
    (execute
     (delete-from :employees
       (where (:= :ssn ssn)))))
  (redirect "/employees"))



(defroute "/departments" ()
    (let ((departments (with-connection (db)
    (retrieve-all
      (select :*
        (from :departments))))))
    (format t "~a~%" departments)
  (render #P"departments/index.html" (list :departments departments))))

(defroute "/departments/new" ()
  (render #P"departments/new.html"))

(defroute ("/departments" :method :POST) (&key _parsed)
  (with-connection (db)
    (let ((code (get-param "code" _parsed))
          (name (get-param "name" _parsed))
          (budget (get-param "budget" _parsed)))
      (execute
       (insert-into :departments
         (set= :code code
                :name name
               :budget budget)))
  (redirect "/departments"))))

(defroute "/departments/:code/edit" (&key code)
  (with-connection (db)
    (let ((dept (retrieve-one
                 (select :*
                   (from :departments)
                   (where (:= :code code))))))
      (print dept)
      (render #P"departments/edit.html" (list :dept dept)))))

(defroute ("/departments/:code/update" :method :POST) (&key code _parsed)
  (with-connection (db)
    (execute
     (update :departments
       (set= :name (get-param "name" _parsed)
             :budget (get-param "budget" _parsed))
       (where (:= :code code))))
    (redirect "/departments")))

(defroute "/departments/:code/delete" (&key code)
  (with-connection (db)
    (execute
     (delete-from :departments
       (where (:= :code code)))))
  (redirect "/departments"))


;;
;; Error pages

(defmethod on-exception ((app <web>) (code (eql 404)))
  (declare (ignore app))
  (merge-pathnames #P"_errors/404.html"
                   *template-directory*))
