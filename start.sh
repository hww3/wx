PIKE_MODULE_PATH=$PIKE_MODULE_PATH:/root/wx/web/PMQ:/root/wx/Fins/lib:/root/wx/wxd
export PIKE_MODULE_PATH

cd /root/wx/web/PMQ
 pike pmqd.pike &
sleep 5
cd /root/wx/wxd
  pike recv.pike &

