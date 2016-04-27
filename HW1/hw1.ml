(*function to check if a set contains a given item*)

let rec contain x set = match set with
  | [] -> false
  | head::tail -> if x = head
                  then true
                  else contain x tail;;
(*warmup functions*)

let rec subset a b = match a with
  | [] -> true
  | head::tail -> if contain head b
                  then subset tail b
                  else false;;

let rec equal_sets a b =
  if ((subset a b) && (subset b a))
  then true
  else false;;

let set_union a b = a@b;;

let rec set_intersection a b = match a with
  | [] -> []
  | head::tail -> if contain head b
                  then head::(set_intersection tail b)
                  else set_intersection tail b;;

let rec set_diff a b = match a with
  | [] -> []
  | head::tail -> if contain head b
                  then set_diff tail b
                  else head::(set_diff tail b);;

let rec computed_fixed_point eq f x =
  if(eq(f x) x)
  then x
  else computed_fixed_point eq f (f x);;

let rec compute_p_calls f p x =
  if p <= 0
  then x
  else compute_p_calls f (pred p) (f x);;

let rec computed_periodic_point eq f p x =
  if(eq(compute_p_calls f p x) x)
  then x
  else computed_periodic_point eq f p (f x);;

(*filter_blind_alleys and helper functions*)

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal;;

let rec check_term_list sym term_list = match term_list with
  | [] -> false
  | head::tail -> match head with
                    | (sym2, _) -> if sym2 = sym
                                   then true
                                   else check_term_list sym tail;;

let rec check_rhs_terminates rhs term_list = match rhs with
  | [] -> true
  | head::tail -> match head with
                    | N sym -> if check_term_list sym term_list
                                  then check_rhs_terminates tail term_list
                                  else false
                    | T _ -> check_rhs_terminates tail term_list;;

let rec build_terminal_list rules term_list = match rules with
  | [] -> term_list
  | head::tail -> match head with
                      | (sym, rhs) -> if (check_rhs_terminates rhs term_list) && not (contain head term_list)
                                      then head::(build_terminal_list tail term_list)
                                      else build_terminal_list tail term_list;;

let rec filter_and_order rules term_list final_rules = match rules with
  | [] -> final_rules
  | head::tail -> if contain head term_list
                  then head::(filter_and_order tail term_list final_rules)
                  else filter_and_order tail term_list final_rules;;

let filter_blind_alleys g = match g with
  | (start, rules) -> start, filter_and_order (rules) (computed_fixed_point (equal_sets) (build_terminal_list rules) []) [];;
