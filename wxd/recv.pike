Stdio.UDP udp;
Sql.Sql db;

int main()
{
  db = Sql.Sql("sqlite://wx.sqlite3");
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
  wxr->insert(db, "observations");
}
