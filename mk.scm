(define (var x) (vector x))
(define (var? x) (vector? x))
(define (walk v s)
  (let ((a (and (var? v) (assq v s))))
    (if a (walk (cdr a) s) v)))
(define (occurs? x v s)
  (let ((v (walk v s)))
    (cond ((var? v) (eq? x v))
          ((pair? v) (or (occurs? x (car v) s) (occurs? x (cdr v) s)))
          (else #f))))
(define (ext-s x v s)
  (if (occurs? x v s) #f (cons (cons x v) s)))
(define (unify u v s)
  (let ((u (walk u s)) (v (walk v s)))
    (cond ((eq? u v) s)
          ((var? u) (if (var? v) (cons (cons u v) s) (ext-s u v s)))
          ((var? v) (ext-s v u s))
          ((and (pair? u) (pair? v))
           (let ((s (unify (car u) (car v) s)))
             (and s (unify (cdr u) (cdr v) s))))
          (else #f))))
(define (== u v)
  (lambda (s)
    (let ((s (unify u v s)))
      (if s (list s) '()))))
(define (succeed s) (list s))
(define (fail s) '())
(define (disj2 g1 g2)
  (lambda (s)
    (mix (g1 s) (g2 s))))
(define (mix $1 $2)
  (cond ((null? $1) $2)
        ((pair? $1) (cons (car $1) (mix (cdr $1) $2)))
        (else (lambda () (mix $2 ($1))))))
(define (conj2 g1 g2)
  (lambda (s)
    (mix-map g2 (g1 s))))
(define (mix-map g $)
  (cond ((null? $) '())
        ((pair? $) (mix (g (car $)) (mix-map g (cdr $))))
        (else (mix-map g ($)))))
(define-syntax disj
  (syntax-rules ()
    ((_) fail)
    ((_ g) g)
    ((_ g0 g1 ...)
     (disj2 g0 (lambda (s) (lambda () ((disj g1 ...) s)))))))
(define-syntax conj
  (syntax-rules ()
    ((_) succeed)
    ((_ g) g)
    ((_ g0 g1 ...) (conj2 g0 (conj g1 ...)))))
(define (walk* v s)
  (let ((v (walk v s)))
    (if (pair? v)
        (cons (walk* (car v) s) (walk* (cdr v) s))
        v)))
(define (reify-name n)
  (string->symbol (string-append "_." (number->string n))))
(define (reify-s v r)
  (let ((v (walk v r)))
    (cond ((var? v) (cons (cons v (reify-name (length r))) r))
          ((pair? v) (reify-s (cdr v) (reify-s (car v) r)))
          (else r))))
(define (reify v)
  (lambda (s)
    (let ((v (walk* v s)))
      (walk* v (reify-s v '())))))
(define (take n $)
  (cond ((null? $) '())
        ((= n 0) '())
        ((pair? $) (cons (car $) (take (- n 1) (cdr $))))
        (else (take n ($)))))
(define-syntax run
  (syntax-rules ()
    ((_ n (x ...) g ...)
     (let ((x (var 'x)) ...)
       (map (reify `(,x ...)) (take n ((conj g ...) '())))))))
(define (take-all $)
  (cond ((null? $) '())
        ((pair? $) (cons (car $) (take-all (cdr $))))
        (else (take-all ($)))))
(define-syntax run*
  (syntax-rules ()
    ((_ (x ...) g ...)
     (let ((x (var 'x)) ...)
       (map (reify `(,x ...)) (take-all ((conj g ...) '())))))))
(define-syntax fresh
  (syntax-rules ()
    ((_ (x ...) g ...)
     (let ((x (var 'x)) ...) (conj g ...)))))
(define-syntax conde
  (syntax-rules ()
    ((_ (g ...) ...) (disj (conj g ...) ...))))
(define (appendo x y z)
  (conde ((== x '()) (== y z))
         ((fresh (a d r)
            (== (cons a d) x)
            (== (cons a r) z)
            (appendo d y r)))))
