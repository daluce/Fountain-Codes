open Random;;
open Droplet;;

(* the fountain produces droplets according to the fountain code 
 * implementation chosen *)

class type fountain =
object
  
    (* the total data (file) being transferred *)
    val mutable data : string

    (* the size of each piece of data from the file, eg 16 bytes *)
    val mutable piece_size : int

    (* total number of pieces in the original file *)
    val mutable total_pieces : int

    (* seed generated using a PRNG, to determine which pieces
       of the file we're using and how many pieces are in
       each XOR'd droplet *)
    val mutable seed : int
    
    (* number of pieces of the original file to be XOR'd in the new droplet *)
    val mutable droplet_pieces : int
    
    (* this creates a new random seed to generate new droplets *)
    method random_seed : unit

    (* this uses the seed to come up with a new random number of
       pieces being encoded in the next droplet *)
    method rand_droplet_pieces : int

    (* this actually updates the droplet_pieces using an int argument,
       generated by rand_droplet_pieces *)
    method update_droplet_pieces : int -> unit

    (* this uses the seed and data variables to fetch a random
       piece of the original file *)
    method get_piece : int list

    method private xor : int list

    (* this generates a new random droplet object, using the above 
       methods and instance variables *)
    method output_droplet : droplet option
    method output_droplet_list : int -> (droplet option) list

    method private get_diced_data : int list array

    method private get_total_pieces : int

    method get_mean : float
    method get_var : float
    method get_bound : int
end


class lt_fountain (d: string) (ps: int) (bound : int) : fountain =
object (self)
  (*   type droplet = lt_droplet
   *  we may need some sort of a line like this ! *) 
    val mutable data           = d
    val mutable piece_size     = ps
    val mutable diced_data     = Array.make 1 []

    val mutable total_pieces   = 
       let length = String.length d in
       if ((length mod ps) = 0) 
         then (length/ps)
         else ((length/ps) + 1)
    
    val mutable seed           = self_init (); int 10000
    val mutable droplet_pieces = 0
    val mutable extra = 0

    initializer
        self#string_to_intlist piece_size data
    
    method random_seed         = self_init (); seed <- int 10000; init seed
    
    method rand_droplet_pieces = (int bound) + 1

    method update_droplet_pieces i = droplet_pieces <- i
    
    method private chopper len str = 
      let rec chopper_helper (len: int) (str:string)
                             (place:int) (len_string:int) : string list = 
     if place < len_string then 
       (String.sub str place len)::
             (chopper_helper len str (place+len) len_string)
     else []
       in 
      let str_len = String.length str in 
        if str_len mod len = 0 then chopper_helper len str 0 (str_len)
        else 
            (extra <- (extra + 1); self#chopper len (str^" "))


    method private int_string (str:string) : int list =   
     let rec int_string_helper (str:string) (counter:int) : int list =
        if (counter = String.length str) 
          then []
          else ((int_of_char str.[counter]) :: 
                                          (int_string_helper str (counter + 1)))
     in 
     int_string_helper str 0
   
    method private string_to_intlist len str : unit =
      let lst = self#chopper piece_size data in
      let lst2 = (List.map (self#int_string) lst) in
      (diced_data <- (Array.of_list lst2))

    method get_piece =
      let a = (int total_pieces) in 
     (*(Printf.printf "encoding#: %d \n" a);*) diced_data.(a) 


    method private xor         =
        let rec help_xor (n:int) : int list =
	        if (n > 1) 
                then ( List.map2 (lxor) (self#get_piece) (help_xor (n-1)))
	            else self#get_piece
        in
        help_xor droplet_pieces
    
    (* Probability of packet loss gets larger as piece size gets bigger 
     * (i.e., droprob gets smaller as piece size increases).
     *
     * NOTE: These numbers have been assigned arbitrarily for the purposes of
     * simulation. *)
    method private droprob = 
       if piece_size <= 20 
         then 100 
         else 
           if piece_size <= 100
             then 60
             else 40

    (* call f with probability (1/p) and g if f is not called *)
    method private inv_probability_or (p:int) (f:unit->'a) (g:unit->'a) : 'a =
        Random.self_init ();    
        if Random.int p = 0 then f () else g ()

    method output_droplet    =
        self#inv_probability_or self#droprob
           (fun () -> None)
           (fun () -> (self#random_seed; 
                       self#update_droplet_pieces self#rand_droplet_pieces;
                       Some (new lt_droplet (self#xor) 
                                      (total_pieces)
                                      (seed) (extra))))

    method output_droplet_list (n:int) : (droplet option) list = 
        if n > 0 
            then self#output_droplet::(self#output_droplet_list (n-1)) 
            else []

    method private get_diced_data = diced_data

    method private get_total_pieces = total_pieces

    method get_mean = 0.
    method get_var = 0.
    method get_bound = bound
end
