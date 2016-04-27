(define (compare-expr x y)
  (if (and (list? x)(list? y))
      (if (eqv? (length x)(length y))
          (if (eqv? (car x)(car y))
              (if (or (equal? 'quote (car x))(equal? 'let (car x))(equal? 'lambda (car x))(equal? 'if (car x)))
                  (compare-let-lambda-quote-if x y)
                  (compare-simple x y #t))
              (case (car x)
                ((quote let) (compare-simple x y #f))
                ((quote if) (compare-simple x y #f))
                ((quote lambda) (compare-simple x y #f))
                ((quote quote) (compare-simple x y #f))
                (else (case (car y)
                        ((quote let) (compare-simple x y #f))
                        ((quote if) (compare-simple x y #f))
                        ((quote lambda) (compare-simple x y #f))
                        ((quote quote) (compare-simple x y #f))
                        (else (compare-simple x y #t))))))
          (compare-simple x y #f))
      (compare-simple x y #f)))


(define (construct-output w x y z)
  (list w x y z))

(define (compare-simple x y toggle)
  (if (eqv? toggle #t)
      (if (equal? x '())
          '()
          (if (equal? y '())
              '()
              (cons (compare-expr (car x)(car y))(compare-simple (cdr x)(cdr y) #t))))
      (if (equal? x y)
          x
          (if (and (equal? x #t)(equal? y #f))
              'TCP
              (if (and (equal? x #f)(equal? y #t))
                  '(not TCP)
                  (construct-output 'if 'TCP x y))))))

(define (compare-let-lambda-quote-if x y)
  (if (and (equal? (car x) 'lambda)(equal? (car y) 'lambda))
      (if (equal? (cadr x)(cadr y))
          (compare-simple x y #t)
          (compare-simple x y #f))
      (if (and (equal? (car x) 'let)(equal? (car y) 'let))
          (if (equal? (extract-let-variables (cadr x))(extract-let-variables (cadr y)))
              (compare-simple x y #t)
              (compare-simple x y #f))
          (if (and (equal? (car x) 'if)(equal? (car y) 'if))
              (compare-simple x y #t)
              (compare-simple x y #f)))))

(define (extract-let-variables x)
  (if (equal? x '())
      '()
      (cons (caar x)(extract-let-variables (cdr x)))))

(define (test-compare-expr x y)
  (let ((compare-expr-output (compare-expr x y)))
    (if (equal? (eval x)(eval (list 'let '((TCP #t)) compare-expr-output)))
        (if (equal? (eval y)(eval (list 'let '((TCP #f)) compare-expr-output)))
            #t
            #f)
        #f)))

(define test-x
  '(cons
    ((lambda (x y)(* x y)) 5 4); lambda test case with equal formals                                                               
    (cons
     ((lambda (z)(+ z z)) 6) ; lambda test case with differing formals and differing bodies                                        
     (cons
      (let ((x 1)(y 2))(+ x y)) ; let test case with equal variable bindings and differing bodies                                  
      (cons
       (let ((x 1)(y 2))(* x y)) ; let test case with differing variable bindings                                                  
       (cons
        (let ((x 5))(+ x x)) ; let test case with equal variable bindings and equal bodies                                         
        (cons
         (if (equal? 1 1) #t #f) ; tests when x contains a built-in function (let, if, quote, lambda) and y does not               
         (cons
          (if (list? '(1 2 3)) (+ 1 2)(+ 1 3)) ; if test case with differences in <test><consequence><alternate>                   
          (quote (1 2 3)))))))))) ; tests differing quoted lists of constant literals     

(define test-y
  '(cons
    ((lambda (x y)(+ x y)) 5 6); lambda test case with equal formals                                                               
    (cons
     ((lambda (w)(+ w w)) 6) ; lambda test case with differing formals and differing bodies                                        
     (cons
      (let ((x 1)(y 2))(* x y)) ; let test case with equal variable bindings and differing bodies                                  
      (cons
       (let ((a 1)(b 2))(* a b)) ; let test case with differing variable bindings                                                  
       (cons
        (let ((x 5))(+ x x)) ; let test case with equal variable bindings and equal bodies                                         
        (cons
         (+ 1 2 3) ; tests when x contains a built-in function (let, if, quote, lambda) and y does not                             
         (cons
          (if (list? '(1 5 3)) (* 1 2)(- 3 1)) ; if test case with differences in <test><consequence><alternate>                   
          (quote (1 4 3)))))))))) ; tests differing quoted lists of constant literals                                              

(test-compare-expr test-x test-y)       

