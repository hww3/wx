rrdtool graph /c/media/temp.png --width 700 --height 268 \
-v "degrees celcuis" \
DEF:tempb=station_3.rrd:tempb:AVERAGE:start=now-24h \
DEF:temp=station_3.rrd:tempa:AVERAGE \
CDEF:fara=9,5,/,temp,*,32,+ \
CDEF:farb=9,5,/,tempb,*,32,+ \
LINE1:fara#0000FF \
LINE1:farb#00FF00

rrdtool graph /c/media/relhx.png --width 700 --height 268 \
-v "% relative humidity" \
DEF:relhx=station_3.rrd:relhx:AVERAGE:start=now-24h \
LINE1:relhx#0000FF \

rrdtool graph /c/media/wind.png --width 700 --height 268 \
-v "windspeed mph" \
DEF:wind=station_3.rrd:windspeed:AVERAGE:start=now-24h \
DEF:maxwind=station_3.rrd:windspeedmax:MAX:start=now-24h \
LINE1:wind#0000FF \
LINE1:maxwind#00FFFF:gusts \

rrdtool graph /c/media/winddir.png --width 700 --height 268 \
-v "wind direction degrees" \
DEF:winddir=station_3.rrd:winddir:AVERAGE:start=now-24h \
LINE1:winddir#0000FF \

rrdtool graph /c/media/pres.png --width 700 --height 268 \
-v "barometric pressure (inHg)" \
DEF:pres=station_3.rrd:pressure:AVERAGE:start=now-24h \
CDEF:mbpres=pres,100,/,0.02953,* \
LINE1:mbpres#FF00FF \

rrdtool graph /c/media/rainfall.png --width 700 --height 268 \
-v "daily rainfall, inches" \
DEF:rf=station_3.rrd:rainfall:AVERAGE:step=86400:start=midnight-30d:end=-1d \
CDEF:rfa=rf,86400,* \
LINE1:rfa#00FF00 \
