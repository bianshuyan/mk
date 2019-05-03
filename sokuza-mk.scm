(define (var x) (vector x))
(define var? vector?)
(define (walk v s)
  (let ((a (and (var? v) (assv v s))))
    (if a (walk (cdr a) s) v)))
(define (succeed s) (list s))
(define (fail s) '())
(define (disj g1 g2)
  (lambda (s)
    (append (g1 s) (g2 s))))
(define (conj g1 g2)
  (lambda (s)
    (apply append (map g2 (g1 s)))))
(define (unify u v s)
  (let ((u (walk u s)) (v (walk v s)))
    (cond ((eqv? u v) s)
          ((var? u) (cons (cons u v) s))
          ((var? v) (cons (cons v u) s))
          ((and (pair? u) (pair? v))
           (let ((s (unify (car u) (car v) s)))
             (and s (unify (cdr u) (cdr v) s))))
          (else #f))))
(define (== u v)
  (lambda (s)
    (let ((s (unify u v s)))
      (if s (list s) '()))))
(define-syntax disj*
  (syntax-rules ()
    ((_) fail)
    ((_ g) g)
    ((_ g0 g1 ...) (disj g0 (disj* g1 ...)))))
(define-syntax conj*
  (syntax-rules ()
    ((_) succeed)
    ((_ g) g)
    ((_ g0 g1 ...) (conj g0 (lambda (s) ((conj* g1 ...) s))))))
(define (walk* v s)
  (let ((v (walk v s)))
    (if (pair? v)
        (cons (walk* (car v) s)
              (walk* (cdr v) s))
        v)))
(define-syntax run
  (syntax-rules ()
    ((_ (x ...) g ...)
     (let ((x (var 'x)) ...)
       (map (lambda (s) (walk* `(,x ...) s))
            ((conj* g ...) '()))))))
(define-syntax fresh
  (syntax-rules ()
    ((_ (x ...) g ...)
     (let ((x (var 'x)) ...) (conj g ...)))))
(define-syntax conde
  (syntax-rules ()
    ((_ (g ...) ...)
     (disj* (conj* g ...) ...))))