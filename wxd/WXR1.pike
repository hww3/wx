import ADT.Struct;

  inherit ADT.Struct;

  Item cookie = Chars(4);
  Item station_id = Byte();
  Item uptime = lWord();
  Item temp = lSWord();
  Item pres = lLWord();
  Item relhx = Float();
  Item tempb = Float();
  Item rainfall = Float();
  Item windspeed = Float();
  Item maxwindspeed = Float();
  Item winddegrees = lWord();
//  Item winddir = Chars(2);
  Item luxa = lWord();
  Item luxb = lWord();
  Item luxc = lWord();

static mixed cast(string type)
{
  if(type=="mapping") return as_mapping();
  else return ::cast(type);
}

string as_json()
{
 return Tools.JSON.serialize((mapping)this); 
}

mapping as_mapping()
{
  mapping v = ([]);
  foreach(indices(this);;string i)
  {
    v[i] = this[i];
    if(stringp(v[i])) v[i] = replace(v[i], "\0", "");
  }

  return v; 
}

void insert(Sql.Sql db, string table)
{
 mapping v = ([]);
 foreach(indices(this);;string i)
  {  
     mixed val;
     if(i=="cookie") continue;
     if(i=="winddir") continue;
     else if(i=="temp") val = (this[i])/10.0;
     else if(this[i] == "\0\0") val = "--";
     else val = this[i];
     v[":" + i] = val;
}
//werror("%O\n", mkmapping(indices(this), values(this)));
  db->query("INSERT INTO " + table + " (updated, location, uptime, "
    "temperature, pressure, humidity, temperature_b, rainfall, windspeed, "
    "direction, wind_gusts, luminosity_a, luminosity_b, luminosity_c) "
    "VALUES(DATETIME('now'), :station_id, :uptime, :temp, :pres, :relhx, "
    ":tempb, :rainfall, :windspeed, :winddegrees, :maxwindspeed, :luxa, "
    ":luxb, :luxc)", v);
}
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
  void decode(object f) { int v; sscanf((f->read(size)), "%-"+size+"c", v); 
	if(v>>15)
	  value = -((v-1)^0xffff);
        else value = v;
}
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
  void decode(object f) { sscanf(f->read(size), "%-"+size+"c", value);}
  string encode() { return sprintf("%-"+size+"c", value); }

  protected string _sprintf(int t) {
    return t=='O' && sprintf("%O(%d)", this_program, value);
  }
}

class lLWord{
 inherit lWord; 
 int size = 4;
}

