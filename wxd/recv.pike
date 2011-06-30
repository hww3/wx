Stdio.UDP udp;
Sql.Sql db;
PMQ.PMQClient client;
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
 // write("struct: %O\n", wxr);
  wxr->insert(db, "observations");
  object reader = client->get_topic_writer("observations");

    object m = Message.PMQMessage();
    m->set_body(wxr->as_json());
    reader->write(m);

}
