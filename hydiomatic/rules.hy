;; hydiomatic -- The Hy Transformer
;; Copyright (C) 2014  Gergely Nagy <algernon@madhouse-project.org>
;;
;; This library is free software: you can redistribute it and/or
;; modify it under the terms of the GNU Lesser General Public License
;; as published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.
;;
;; This library is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; Lesser General Public License for more details.
;;
;; You should have received a copy of the GNU Lesser General Public
;; License along with this program. If not, see <http://www.gnu.org/licenses/>.

(import [adderall.dsl [*]]
        [adderall.extra.misc [*]]
        [hy [HyExpression HyList]])
(require adderall.dsl)

(defn-alias [rules/arithmeticᵒ rules/arithmetico] [expr out]
  (condᵉ
   ;; (+ 0 x), (+ x 0) => x
   ;; (* 1 x), (* x 1) => x
   [(fresh [op zero]
           (condᵉ
            [(≡ op '+) (≡ zero 0)]
            [(≡ op '*) (≡ zero 1)])
           (condᵉ
            [(≡ expr `(~op ~zero ~out))]
            [(≡ expr `(~op ~out ~zero))]))]
   ;; (+ x (+ ...)) => (+ x ...)
   ;; (* x (* ...)) => (* x ...)
   [(fresh [op x xs]
           (memberᵒ op `[+ *])
           (≡ expr `(~op ~x (~op . ~xs)))
           (≡ out `(~op ~x . ~xs)))]
   ;; (+ x 1), (+ 1 x) => (inc x)
   [(fresh [x]
           (condᵉ
            [(≡ expr `(+ ~x 1))]
            [(≡ expr `(+ 1 ~x))])
           (≡ out `(inc ~x)))]
   ;; (- x 1) => (dec x)
   [(fresh [x]
           (≡ expr `(- ~x 1))
           (≡ out `(dec ~x)))]))

(defn-alias [rules/quoteᵒ rules/quoteo] [expr out]
  (condᵉ
   ;; `~x => x
   [(fresh [x]
           (≡ expr `(quasiquote (unquote ~x)))
           (≡ out x))]))

(defn-alias [rules/control-structᵒ rules/control-structo] [expr out]
  (condᵉ
   ;; (if test y nil) => (when test y)
   [(fresh [test yes-branch]
           (≡ expr `(if ~test ~yes-branch nil))
           (≡ out `(when ~test ~yes-branch)))]
   ;; (if test nil n) => (unless test n)
   [(fresh [test no-branch]
           (≡ expr `(if ~test nil ~no-branch))
           (≡ out `(unless ~test ~no-branch)))]
   ;; (if (not test) a b) => (if-not test a b)
   [(fresh [test branches]
           (≡ expr `(if (not ~test) . ~branches))
           (≡ out `(if-not ~test . ~branches)))]
   ;; (if test (do y)) => (when test y)
   [(fresh [test y]
           (≡ expr `(if ~test (do . ~y)))
           (≡ out `(when ~test . ~y)))]
   ;; (when (not test) stuff) => (unless test stuff)
   [(fresh [test body]
           (≡ expr `(when (not ~test) . ~body))
           (≡ out `(unless ~test . ~body)))]
   ;; (do x) => x
   [(≡ expr `(do ~out))]
   ;; (when test (do x)) => (when test x)
   ;; (unless test (do x)) => (unless test x)
   [(fresh [op test body]
           (memberᵒ op `[when unless])
           (≡ expr `(~op ~test (do . ~body)))
           (≡ out `(~op ~test . ~body)))]
   ;; (if test a) => (when test a)
   ;; (if-not test a) => (unless test a)
   [(fresh [op new-op test branch]
           (condᵉ
            [(≡ op 'if) (≡ new-op 'when)]
            [(≡ op 'if-not) (≡ new-op 'unless)])
           (≡ expr `(~op ~test ~branch))
           (≡ out `(~new-op ~test ~branch)))]))

(defn-alias [rules/equalityᵒ rules/equalityo] [expr out]
  (condᵉ
   ;; (= (% n 2) 0) => (even? n)
   ;; (= (% n 2) 1) => (odd? n)
   [(fresh [n r op]
           (≡ expr `(= (% ~n 2) ~r))
           (condᵉ
            [(≡ r 0) (≡ op 'even?)]
            [(≡ r 1) (≡ op 'odd?)])
           (≡ out `(~op ~n)))]
   ;; zero?
   [(fresh [x]
           (condᵉ
            [(≡ expr `(= 0 ~x))]
            [(≡ expr `(= ~x 0))])
           (≡ out `(zero? ~x)))]
   ;; pos?
   [(fresh [x]
           (condᵉ
            [(≡ expr `(< 0 ~x))]
            [(≡ expr `(> ~x 0))])
           (≡ out `(pos? ~x)))]
   ;; neg?
   [(fresh [x]
           (≡ expr `(< ~x 0))
           (≡ out `(neg? ~x)))]
   ;; nil?
   [(fresh [x]
           (condᵉ
            [(≡ expr `(= ~x nil))]
            [(≡ expr `(= nil ~x))])
           (≡ out `(nil? ~x)))]
   ;; none? => nil?
   [(fresh [x]
           (≡ expr `(none? ~x))
           (≡ out `(nil? ~x)))]))

(defn-alias [rules/collectionᵒ rules/collectiono] [expr out]
  (condᵉ
   ;; (get x 0) => (first x)
   [(fresh [x]
           (≡ expr `(get ~x 0))
           (≡ out `(first ~x)))]
   ;; (slice x 1) => (rest x)
   [(fresh [x]
           (≡ expr `(slice ~x 1))
           (≡ out `(rest ~x)))]
   ;; (= (len x) 0), (= 0 (len x)), (zero? (len x))
   ;;  => (empty? x)
   [(fresh [x]
           (condᵉ
            [(≡ expr `(= (len ~x) 0))]
            [(≡ expr `(= 0 (len ~x)))]
            [(≡ expr `(zero? (len ~x)))])
           (≡ out `(empty? ~x)))]))

(defn-alias [rules/syntaxᵒ rules/syntaxo] [expr out]
  (condᵉ
   ;; (defn foo (x) ...) => (defn foo [x] ...)
   [(fresh [op fname params body]
           (memberᵒ op `[defn defun defn-alias defun-alias])
           (≡ expr `(~op ~fname ~params . ~body))
           (typeᵒ params HyExpression)
           (project [params]
                    (≡ out `(~op ~fname ~(HyList params) . ~body))))]
   ;; (isinstance x klass) => (instance? klass x)
   [(fresh [x klass]
           (≡ expr `(isinstance ~x ~klass))
           (≡ out `(instance? ~klass ~x)))]
   ;; (instance? float x) => (float? x)
   ;; (instance? int x) => (integer? x)
   ;; (instance? str x) => (string? x)
   ;; (instance? unicode x) => (string? x)
   [(fresh [klass x alt]
           (≡ expr `(instance? ~klass ~x))
           (condᵉ
            [(≡ klass 'float) (≡ alt 'float?)]
            [(≡ klass 'int) (≡ alt 'integer?)]
            [(≡ klass 'str) (≡ alt 'string?)]
            [(≡ klass 'unicode) (≡ alt 'string?)])
           (≡ out `(~alt ~x)))]
   ;; (for* [x iteratable] (yield x))
   ;;  => (yield-form iteratable)
   [(fresh [x iteratable]
           (≡ expr `(for* [~x ~iteratable] (yield ~x)))
           (≡ out `(yield-form ~iteratable)))]))

(eval-and-compile
 (defn --transform-bindings [bindings body]
   (let [[new-bindings (list-comp `(setv ~@x) [x bindings])]]
         (+ new-bindings body))))

(defn-alias [rules/optimᵒ rules/optimo] [expr out]
  (condᵉ
   ;; (defn foo [x] (let [[y (inc x)]] ...))
   ;;  => (defn foo [x] (setv y (inc x)) ...)
   [(fresh [op fname params bindings body new-body c]
           (memberᵒ op `[defn defun defn-alias defun-alias])
           (≡ expr `(~op ~fname ~params
                      (let ~bindings . ~body)))
           (project [bindings body]
                    (≡ new-body (--transform-bindings bindings body)))
           (≡ c `(~op ~fname ~params . ~new-body))
           (project [c]
                    (≡ out (HyExpression c))))]))

(defn rules/default [expr q]
  (condᵉ
   [(rules/arithmeticᵒ expr q)]
   [(rules/quoteᵒ expr q)]
   [(rules/control-structᵒ expr q)]
   [(rules/equalityᵒ expr q)]
   [(rules/collectionᵒ expr q)]
   [(rules/syntaxᵒ expr q)]
   [(rules/optimᵒ expr q)]))
