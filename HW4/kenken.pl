/* kenken.pl */
/* Helper predicate to grab value of a square in the matrix */

elementMatrix(T, A-B, V) :-                                                                                                                                                                                 
	nth(A,T,Row),
	nth(B,Row,V).                                                                                                                                                                                 
    
/* Helper predicates to handle the four basic arithmatic operations a kenken constraint can have */

add([], Sum, Sum, _).                                                                                                                                                                                       
add([Head|Tail], Sum, Accum, Mat) :-                                                                                                                                                                        
	elementMatrix(Mat, Head, Element),                                                                                                                                                                          
	New_Accum #= Accum + Element,                                                                                                                                                                               
	add(Tail, Sum, New_Accum, Mat).                                                                                                                                                                             
                                                                                                                                                                                                            
sub(Diff, JSqr, KSqr, Mat) :-                                                                                                                                                                               
	elementMatrix(Mat, JSqr, J),                                                                                                                                                                                
	elementMatrix(Mat, KSqr, K),                                                                                                                                                                                
	(Diff #= J - K ; Diff #= K - J).                                                                                                                                                                            
                                                                                                                                                                                                            
mult([], Prod, Prod, _).                                                                                                                                                                                    
mult([Head|Tail], Prod, Accum, Mat) :-                                                                                                                                                                      
	elementMatrix(Mat, Head, Element),                                                                                                                                                                         
	New_Accum #= Accum * Element,                                                                                                                                                                              
 	mult(Tail, Prod, New_Accum, Mat).                                                                                                                                                                          
                                                                                                                                                                                                            
div(Quot, JSqr, KSqr, Mat) :-                                                                                                                                                                               
 	elementMatrix(Mat, JSqr, J),                                                                                                                                                                               
 	elementMatrix(Mat, KSqr, K),                                                                                                                                                                               
 	(Quot #= K / J ; Quot #= J / K).                                                                                                                                                                           

/* predicate to evaulate kenken matrix based on inputted constraints */

evalConstraints(Mat, +(Sum, List)) :-
	add(List, Sum, 0, Mat).
evalConstraints(Mat, -(Diff, JSqr, KSqr)) :-
  	sub(Diff, JSqr, KSqr, Mat).
evalConstraints(Mat, *(Prod, List)) :-
  	mult(List, Prod, 1, Mat).
evalConstraints(Mat, /(Quot, JSqr, KSqr)) :-                                                                                                                                                              
	div(Quot, JSqr, KSqr, Mat).                                                                                                                                                                                 
   
/* transpose predicate. transpose is used to take the transpose of the kenken matrix
in order to allow the program to ensure that rows and columns are all distinct values 

code from: http://stackoverflow.com/questions/4280986/how-to-transpose-a-matrix-in-prolog

*/

transpose([], []).                                                                                                                                                                                          
transpose([F|Fs], T) :-                                                                                                                                                                                     
        transpose(F, [F|Fs], T).                                   

transpose([], _, []).                                                                                                                                                                                       
transpose([_|R], M, [T|Ts]) :-                                                                                                                                                                              
    transpose_aux(M, T, Ms),                                                                                                                                                                                
    transpose(R, Ms, Ts).                                                                                                                                                                                   
                                                                                                                                                                                                            
transpose_aux([], [], []).                                                                                                                                                                                  
transpose_aux([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-                                                                                                                                                           
    transpose_aux(Rest, Fs, Oss).                                                                                                                                                                           
   
/* helper predicate that sets length of rows */

rowLength(N, L) :-                                                                                                                                                                                          
length(L, N).                                                                                                                                                                                               
   
/* helper predicate that sets the range of 1..N for each element in the inputted list */

setDomain(N, L) :-                                                                                                                                                                                          
fd_domain(L,1,N).                                                                                                                                                                                           
  
/* To run timing tests on kenken, I ran the following command in gprolog:
fd_set_vector_max(255), kenken_testcase(N,C), statistics, kenken(N,C,T), statistics.

I ran this test on the 6x6 testcase given in the homework spec.
The elapsed real time was consistently 0.001 seconds.
 */  

kenken(N, C, T) :-                                                                                                                                                                                          
	length(T, N),                                                                                                                                                                                               
	maplist(rowLength(N), T),                                                                                                                                                                                   
	maplist(setDomain(N), T),                                                                                                                                                                                   
	maplist(fd_all_different, T),                                                                                                                                                                               
	transpose(T, TransT),                                                                                                                                                                                       
	maplist(fd_all_different, TransT),                                                                                                                                                                          
	maplist(evalConstraints(T), C),                                                                                                                                                                             
	maplist(fd_labeling, T).                          

/* copies of add, sub, mult, div, and evalConstraints from regular kenken. Modified
to not use the finite domain solver */

plain_add([], Sum, Sum, _).                                                                                                                                                                                 
plain_add([Head|Tail], Sum, Accum, Mat) :-                                                                                                                                                                  
	elementMatrix(Mat, Head, Element),                                                                                                                                                                          
	New_Accum is Accum + Element,                                                                                                                                                                               
	add(Tail, Sum, New_Accum, Mat).                                                                                                                                                                             
                                                                                                                                                                                                            
plain_sub(Diff, JSqr, KSqr, Mat) :-                                                                                                                                                                         
	elementMatrix(Mat, JSqr, J),                                                                                                                                                                                
	elementMatrix(Mat, KSqr, K),                                                                                                                                                                                
	(Diff is J - K ; Diff is K - J).                                                                                                                                                                            
                                                                                                                                                                                                            
plain_mult([], Prod, Prod, _).                                                                                                                                                                              
plain_mult([Head|Tail], Prod, Accum, Mat) :-                                                                                                                                                                
    elementMatrix(Mat, Head, Element),                                                                                                                                                                      
    New_Accum is Accum * Element,                                                                                                                                                                           
    mult(Tail, Prod, New_Accum, Mat).                                                                                                                                                                       
                                                                                                                                                                                                            
plain_div(Quot, JSqr, KSqr, Mat) :-                                                                                                                                                                         
    elementMatrix(Mat, JSqr, J),                                                                                                                                                                            
    elementMatrix(Mat, KSqr, K),                                                                                                                                                                            
    (Quot is K / J ; Quot is J / K).

plain_evalConstraints(Mat, +(Sum, List)) :-
	plain_add(List, Sum, 0, Mat).
plain_evalConstraints(Mat, -(Diff, JSqr, KSqr)) :-
	plain_sub(Diff, JSqr, KSqr, Mat).
plain_evalConstraints(Mat, *(Prod, List)) :-
	plain_mult(List, Prod, 1, Mat).
plain_evalConstraints(Mat, /(Quot, JSqr, KSqr)) :-                                                                                                                                                          
    plain_div(Quot, JSqr, KSqr, Mat).       



plain_kenken(N,C,T) :-                                                                                                                                                                                      
    length(T,N),                                                                                                                                                                                            
    maplist(rowLength(N), T),                                                                                                                                                                               
    setof(X, between(1,N,X), DomainList),                                                                                                                                                                   
    maplist(permutation(DomainList), T),                                                                                                                                                                    
    transpose(T, TransT),                                                                                                                                                                                   
    maplist(permutation(DomainList), TransT),                                                                                                                                                               
    maplist(plain_evalConstraints(T), C).                           

/* To run timing tests on plain_kenken, I ran the following command in gprolog:
kenken_testcase(N,C), statistics, plain_kenken(N,C,T), statistics.

I ran this test on the 6x6 testcase given in the homework spec; however, my implementation hangs when given a 6x6 matrix.
So, I instead tested my plain_kenken on the 4x4 testcase given in the homework spec.
The elapsed real time was consistently 0.053 seconds.
Considering a 4x4 kenken puzzle is significantly simpler to solve than a 6x6 puzzle, plain_kenken is significantly slower than 
kenken as kenken can solve a more complicated puzzle in less time.
 */






