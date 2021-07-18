(defsystem "cl-employee-db-test"
  :defsystem-depends-on ("prove-asdf")
  :author "Rajasegar Chandran"
  :license ""
  :depends-on ("cl-employee-db"
               "prove")
  :components ((:module "tests"
                :components
                ((:test-file "cl-employee-db"))))
  :description "Test system for cl-employee-db"
  :perform (test-op (op c) (symbol-call :prove-asdf :run-test-system c)))
