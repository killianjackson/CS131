type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal;;

let rec productionFunction nt ruleList = match ruleList with
  |[]->[]
  |head::tail -> match head with
            |(lhs, rhs) -> if lhs = nt
                         then rhs::productionFunction nt tail
                         else productionFunction nt tail;;

let convert_grammar gram1 = match gram1 with
  | (start, ruleList) -> (start, fun nt -> (productionFunction nt ruleList));;


let rec matcher = fun prodFunction nt acceptor deriv frag ->
  let rec check_symbols = fun prodFunction rhs acceptor deriv frag ->
    match frag with
      | [] -> if rhs = []
              then acceptor deriv frag
              else None
      | h::t -> match rhs with
                | [] -> if rhs = [] 
                        then acceptor deriv frag 
                        else None
                | (N x)::tail -> matcher prodFunction x (check_symbols (prodFunction) tail acceptor) deriv frag
                | (T x)::tail -> if x = h
                                 then check_symbols (prodFunction) tail acceptor deriv t
                                 else None

  in

  let rec check_rhs = fun prodFunction nt rhsRules acceptor deriv frag ->
    match rhsRules with
      | [] -> None
      | h::t -> match check_symbols prodFunction h acceptor (deriv@[(nt,h)]) frag with
                | None -> check_rhs prodFunction nt t acceptor deriv frag
                | Some (x,y) -> Some (x,y)
                
  in

  check_rhs prodFunction nt (prodFunction nt) acceptor deriv frag;;

  let parse_prefix gram accept frag = match gram with
    | (start, prodFunction) -> matcher prodFunction start accept [] frag;;