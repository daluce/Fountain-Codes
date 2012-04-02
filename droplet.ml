(* the Droplet, containing a seed and the XOR'd data *)
class type droplet data total seed =
object
    (* a few chunks of the file encoded together *)
    val mutable data
    
    (* total number of chunks in file *)
    val mutable total_pieces
    
    (* pseduorandomly generated seed for telling which chunks were used *)
    val mutable seed
    
    (* this prints the data, total_pieces, and seed *)
    method to_string: unit

    (* returns a tuple with data, total_pieces, and seed for use in
       goblet *)
    method get_contents
end
