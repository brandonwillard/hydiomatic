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

(import [adderall.dsl [*]])
(require adderall.dsl)
(require hydiomatic.macros)

(defrules [rules/equalityᵒ rules/equalityo]
  ;; (= (% n 2) 0) => (even? n)
  [[n] `(= (% ~n 2) 0) `(even? ~n)]
  ;; (= (% n 2) 1) => (odd? n)
  [[n] `(= (% ~n 2) 1) `(odd? ~n)]
  ;; zero?
  [[x] `(= 0 ~x) `(zero? ~x)]
  [[x] `(= ~x 0) `(zero? ~x)]
  ;; pos?
  [[x] `(< 0 ~x) `(pos? ~x)]
  [[x] `(> ~x 0) `(pos? ~x)]
  ;; neg?
  [[x] `(< ~x 0) `(neg? ~x)]
  ;; nil?
  [[x] `(= ~x nil) `(nil? ~x)]
  [[x] `(= nil ~x) `(nil? ~x)]
  ;; none? => nil?
  [[x] `(none? ~x) `(nil? ~x)])
