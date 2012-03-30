Stdio.UDP udp;
Sql.Sql db;
PMQ.PMQClient client;
mapping stations_registered = ([]);

import PMQ;
int main()
{
  db = Sql.Sql("sqlite://wx.sqlite3");
  PMQ.PMQConstants.DEBUG_LEVEL(0);
  client = PMQClient("pmq://127.0.0.1:9998");
//client->set_backend(backend);
  client->connect();
  udp = Stdio.UDP();
  udp->bind(7656);
  udp->set_nonblocking();
  udp->set_read_callback(got_packet); 
  return -1;
}

void got_packet(mapping packet)
{
  write("got packet: %O\n", packet->data);
  object wxr = .WXR1(packet->data);
 write("struct: %O\n", wxr);
  if(!stations_registered[wxr->station_id])
    register(wxr);

  wxr->insert(db, "observations");
  object reader = client->get_topic_writer("observations");

    object m = Message.PMQMessage();
    m->set_body(wxr->as_json());
    reader->write(m);

}

void register(object wxr)
{
  int station_id = wxr->station_id;

  if(!file_stat("station_" + station_id + ".rrd"))
  {
    create_rrd(station_id);
  }
  
  stations_registered[station_id] = 1;
}

void create_rrd(int station_id)
{
  Public.Tools.RRDtool.rrdtool_create("station_" + station_id + ".rrd", 
  ({
    (["name": "tempa", "DST": "GAUGE", "heartbeat": 600, "min": "U", "max": "U"]),
    (["name": "pressure", "DST": "GAUGE", "heartbeat": 600, "min": "U", "max": "U"]),
    (["name": "relhx", "DST": "GAUGE", "heartbeat": 600, "min": "U", "max": "U"]),
    (["name": "tempb", "DST": "GAUGE", "heartbeat": 600, "min": "U", "max": "U"]),
    (["name": "rainfall", "DST": "ABSOLUTE", "heartbeat": 600, "min": "U", "max": "U"]),
    (["name": "windspeed", "DST": "GAUGE", "heartbeat": 600, "min": "U", "max": "U"]),
    (["name": "winddir", "DST": "GAUGE", "heartbeat": 600, "min": "U", "max": "U"]),
    (["name": "windspeedmax", "DST": "GAUGE", "heartbeat": 600, "min": "U", "max": "U"])
  }),
  ({
    (["CF": "AVERAGE", "xff": 0.5, "step": 1, "rows": 12*60]), /* 10 seconds for 2 hour */
    (["CF": "AVERAGE", "xff": 0.5, "step": 6, "rows": 60*24]), /* 1 minute for an day */
    (["CF": "AVERAGE", "xff": 0.5, "step": 6*5, "rows": 12*24*30]), /* 5 minutes for 30 days */
    (["CF": "AVERAGE", "xff": 0.5, "step": 6*30, "rows": 2*24*365*5]), /* 30 minutes for 5 years */
    (["CF": "MAX", "xff": 0.5, "step": 6*60*24, "rows": 365*5]), /* daily for 5 years */
    (["CF": "MIN", "xff": 0.5, "step": 6*60*24, "rows": 365*5]), /* daily for 5 years */
    (["CF": "LAST", "xff": 0.5, "step": 6, "rows": 60*24]), /* 1 minute for an day */
    (["CF": "MIN", "xff": 0.5, "step": 6*5, "rows": 12*24*30]), /* 5 minutes for 30 days */
    (["CF": "MAX", "xff": 0.5, "step": 6*5, "rows": 12*24*30]), /* 5 minutes for 30 days */
    (["CF": "MIN", "xff": 0.5, "step": 6*30, "rows": 2*24*365*5]), /* 30 minutes for 5 years */
    (["CF": "MAX", "xff": 0.5, "step": 6*30, "rows": 2*24*365*5]) /* 30 minutes for 5 years */

  })
, ({"--start", time(), "--step", 10}) );
}
