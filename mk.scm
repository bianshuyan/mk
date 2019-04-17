(define (var) (vector #f))
(define var? vector?)
(define (walk v d)
  (let ((a (and (var? v) (assv v d))))
    (if a (walk (cdr a) d) v)))
(define (ext-d x v d)
  (if (occurs? x v d)
      #f
      (cons (cons x v) d)))
(define (occurs? x v d)
  (let ((v (walk v d)))
    (cond ((var? v) (eqv? x v))
          ((pair? v)
           (or (occurs? x (car v) d)
               (occurs? x (cdr v) d)))
          (else #f))))
(define (unify u v d)
  (let ((u (walk u d)) (v (walk v d)))
    (cond ((eqv? u v) d)
          ((var? u) (ext-d u v d))
          ((var? v) (ext-d v u d))
          ((and (pair? u) (pair? v))
           (let ((d (unify (car u) (car v) d)))
             (and d (unify (cdr u) (cdr v) d))))
          (else #f))))
(define (== u v)
  (lambda (d)
    (let ((d (unify u v d)))
      (if d (list d) '()))))
(define (succeed d) (list d))
(define (fail d) '())
(define (disj2 g1 g2)
  (lambda (d)
    (merge (g1 d) (g2 d))))
(define-syntax disj
  (syntax-rules ()
    ((_) fail)
    ((_ g) g)
    ((_ g0 g1 ...) (disj2 g0 (disj g1 ...)))))
(define (conj2 g1 g2)
  (lambda (d)
    (merge-map g2 (g1 d))))
(define-syntax conj
  (syntax-rules ()
    ((_) succeed)
    ((_ g) g)
    ((_ g0 g1 ...) (conj2 g0 (conj g1 ...)))))
(define (merge s1 s2)
  (cond ((null? s1) s2)
        ((pair? s1) (cons (car s1) (merge (cdr s1) s2)))
        (else (lambda () (merge s2 (s1))))))
(define (merge-map g s)
  (cond ((null? s) '())
        ((pair? s)
         (merge (g (car s)) (merge-map g (cdr s))))
        (else (merge-map g (s)))))
(define (reify-name n)
  (string->symbol
   (string-append "_" (number->string n))))
(define (reify-d v r)
  (let ((v (walk v r)))
    (cond ((var? v)
           (let ((rn (reify-name (length r))))
             (cons (cons v rn) r)))
          ((pair? v)
           (let ((r (reify-d (car v) r)))
             (reify-d (cdr v) r)))
          (else r))))
(define (reify v)
  (lambda (d)
    (let ((v (walk* v d)))
      (let ((r (reify-d v '())))
        (walk* v r)))))
(define (walk* v d)
  (let ((v (walk v d)))
    (if (pair? v)
        (cons (walk* (car v) d)
              (walk* (cdr v) d))
        v)))
(define-syntax fresh
  (syntax-rules ()
    ((_ (x ...) g ...)
     (let ((x (var)) ...) (conj g ...)))))
(define (take n s)
  (cond ((or (= n 0) (null? s)) '())
        ((pair? s)
         (cons (car s) (take (- n 1) (cdr s))))
        (else (take n (s)))))
(define-syntax conde
  (syntax-rules ()
    ((_ (g ...) ...)
     (disj (conj g ...) ...))))
(define-syntax run
  (syntax-rules ()
    ((_ n (x0 x1 ...) g ...)
     (run n q (fresh (x0 x1 ...)
                (== (list x0 x1 ...) q) g ...)))
    ((_ n q g ...)
     (let ((q (var)))
       (map (reify q) (take n ((conj g ...) '())))))))
(define-syntax defrel
  (syntax-rules ()
    ((_ (name x ...) g ...)
     (define (name x ...)
       (lambda (s)
         (lambda ()
           ((conj g ...) s)))))))
