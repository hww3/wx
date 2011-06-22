import ADT.Struct;

  inherit ADT.Struct;

  Item cookie = Chars(4);
  Item uptime = lWord();
  Item temp = lWord();
  Item pres = lLWord();
  Item relhx = Float();
  Item tempb = Float();
  Item rainfall = Float();
  Item windspeed = Float();
  Item maxwindspeed = Float();
  Item winddir = Chars(2);
  Item luxa = lWord();
  Item luxb = lWord();
  Item luxc = lWord();

// little endian word
class Float
{
  inherit Item;
  protected float value;
  int size = 4;
    void decode(object f) { sscanf(reverse(f->read(size)), "%F", value);  }      
  string encode() { return sprintf("%F", value); }                                                                                 
                                                                                                                                            
  protected string _sprintf(int t) {                                                                                                        
    return t=='O' && sprintf("%O(%f)", this_program, value);                                                                                
  }    
}

class lSWord {
  inherit Item;
  int size = 2;
  protected int value;

  //! The word can be initialized with an optional value.
  protected void create(void|int(-32768..32767) initial_value) {
//    set(initial_value);
  }

  void set(int(0..) in) {
    if(in<-~(1<<size*8-1) || in>~((-1)<<size*8-1))
      error("Value %d out of bound (%d..%d).\n",
            in, -~(1<<size*8-1), ~((-1)<<size*8-1));
    value = in;
  }
  void decode(object f) { int v; sscanf(f->read(size), "%-"+size+"c", v); sscanf(sprintf(size + "c", v), "%+" +size+"c", value); }
  string encode() { return sprintf("%-"+size+"c", value); }

  protected string _sprintf(int t) {
    return t=='O' && sprintf("%O(%d)", this_program, value);
  }
}

class lWord {

  inherit Item;
  int size = 2;
  protected int(0..) value;

  //! The word can be initialized with an optional value.
  protected void create(void|int(0..65535) initial_value) {
    set(initial_value);
  }

  void set(int(0..) in) {
    if(in<0 || in>~((-1)<<size*8))
      error("Value %d out of bound (0..%d).\n",
            in, ~((-1)<<size*8));
    value = in;
  }
  void decode(object f) { sscanf(f->read(size), "%-"+size+"c", value); }
  string encode() { return sprintf("%-"+size+"c", value); }

  protected string _sprintf(int t) {
    return t=='O' && sprintf("%O(%d)", this_program, value);
  }
}

class lLWord{
 inherit lWord; 
 int size = 4;
}

