import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Math as Math;

using Toybox.Time;
using Toybox.Time.Gregorian;

// Compile with:
// for /f usebackq %i in (%APPDATA%\Garmin\ConnectIQ\current-sdk.cfg) do set CIQ_HOME=%~pi
// set PATH=%PATH%;%CIQ_HOME%\bin
// monkeyc -d edge520plus -f C:\Projects\ConnectIQ\ClimbPro\monkey.jungle -o c:\Projects\ConnectIQ\ClimbPro\bin\ClimbPro.prg -y C:\Projects\ConnectIQ\developer_key
//

// climb code
//-43.56317257,172.598233192, 1100, 0, 40, 50, 110, 120, 130, 140, 170, 180

class ClimbProView extends WatchUi.DataField {

    hidden var mValue as Numeric;
    hidden var climbgrad = new Array<Number>[100];
    hidden var data = [0, 40, 50, 110, 120,130,140,170,186];
    hidden var maxBarHeight =0;
    hidden var currentLoc;
    hidden var inClimb = 0;
    hidden var distToClimb = 100000;
    hidden var climbToGo;
    hidden var covered;
    hidden var Lat;
    hidden var Lon;
    hidden var lastLat;
    hidden var lastLon;
    hidden var timer=0;
    hidden var climbTime=0;
    hidden var lastTime=0;
    hidden var dist=0;
    hidden var resStart;
    hidden var resFinish;
    hidden var height;
    hidden var width;
    hidden var targetLon;
    hidden var targetLat;
    hidden var length;
    hidden var climbCode = "-43.56317257,172.598233192, 800,Worsleys, 0, 40, 50, 110, 120, 130, 140, 170, 180";
    hidden var climbCode2 = "-43.56724,172.59921,550,Sparks,0,30,60,90,150,180,200";
    hidden var allClimbs = new [10];
    hidden var closestClimb= 0;
    hidden var lowDistToClimb= 999999;

        // Set the target GPS coordinates (latitude and longitude)

    hidden var name = "Worsleys";

    const proximityThreshold = 25; // Proximity threshold in meters



    function initialize() {
        DataField.initialize();

        resStart = WatchUi.loadResource(Rez.Drawables.Start);
        resFinish = WatchUi.loadResource(Rez.Drawables.Finish);

        mValue = 0.0f;
        maxBarHeight = maxAlt(data);

        // for(var i=0; i <2;i++) {
        //     allclimbs[i] = blah;
        // }
        allClimbs[0] = toArray(climbCode, ",");
        allClimbs[1] = toArray(climbCode2, ",");

        var bobo = allClimbs[0];
        var boba = allClimbs[1];

        data = toArray(climbCode, ",");
        targetLat = data[1].toFloat();
        targetLon = data[2].toFloat();
        length = data[3].toFloat();
        name = data[4];
        // for (var i=5; i < data[0]; i++)
        // {
        //     climbgrad[i] = ((data[i+1].toFloat() -data[i].toFloat()) / 1000f ) * 100f;
        //      //System.println(climbgrad[i]);
        // }

       // die;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        height = dc.getHeight();
        width = dc.getWidth();
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // See Activity.Info in the documentation for available information.
        if (info.currentLocation != null) {
            Lat = info.currentLocation.toDegrees()[0];
            Lon = info.currentLocation.toDegrees()[1];
            
            lowDistToClimb = 99999;
            for(var i=0; i <2;i++) {
                var tempDistToClimb = calculateDistance(Lat, Lon, allClimbs[i][1].toFloat(), allClimbs[i][2].toFloat());
                if (tempDistToClimb < lowDistToClimb) {
                    lowDistToClimb = tempDistToClimb;
                    distToClimb = tempDistToClimb;
                    length = allClimbs[i][3];
                    name = allClimbs[i][4];
                    closestClimb = i;
                }
            }
            System.println(closestClimb);
            
            if ((distToClimb <=proximityThreshold ) && (inClimb==0)) {
                inClimb=1;
                covered = 0;
                lastLat = Lat;
                lastLon = Lon;
            }

            if(inClimb == 1) {
                covered += calculateDistance(lastLat, lastLon, Lat, Lon);
                lastLat = Lat;
                lastLon = Lon;
                if ((covered  >= proximityThreshold) && (timer==0)) {timer = Time.now().value();}

                if (timer !=0) {
                    climbToGo = length.toFloat() - (covered - proximityThreshold);
                    climbTime =Time.now().value()-timer;
                    if (climbToGo <= 0) {
                        inClimb = 0;
                        lastTime = climbTime;
                        timer=0;
                    }

                }
            }
            System.println(distToClimb+", "+inClimb+", "+covered+", "+climbToGo+", "+climbTime);
        }

    }
        function calculateDistance(lat1, lon1, lat2, lon2) {
        var R = 6371000; // Earth's radius in metres

        // Convert latitudes and longitudes from degrees to radians
        var dLat = Math.toRadians(lat2 - lat1);
        var dLon = Math.toRadians(lon2 - lon1);
        lat1 = Math.toRadians(lat1);
        lat2 = Math.toRadians(lat2);

        // Haversine formula
        var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                Math.cos(lat1) * Math.cos(lat2) *
                Math.sin(dLon / 2) * Math.sin(dLon / 2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }


    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        // Data values to plot
        
        // Graph parameters
        var bob = length;
        var barWidth = width.toFloat() /((length.toFloat())/100f);
        var startX = 20;

        
        // Colors for each bar
        var colours = [Graphics.COLOR_RED, Graphics.COLOR_GREEN, Graphics.COLOR_BLUE, Graphics.COLOR_ORANGE];

        // Background colour
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_WHITE);
        dc.clear();
        
        // Draw each bar
        for (var i = 5; i < data[0]; i++) {
            var h1 = (height-5)-((data[i].toFloat() / maxBarHeight) * (height-5));
            var h2 = (height-5)-((data[i+1].toFloat() / maxBarHeight) * (height-5));
  
            var x1 = ((i-5) * (barWidth));
            var x2 = ((i-4) * (barWidth));
            var y = height-5; // Adjust to place bars within the data field
            
            // Set the colour for each bar
            var grad = ((data[i+1].toFloat() - data[i].toFloat()) / 1000f ) * 100f;
 
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            if ((grad >=3) && (grad <6)) {dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);}
            if ((grad >=6) && (grad <9)) {dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);}
            if ((grad >=9) && (grad <12)) {dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);}
            if (grad >=12) {dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);}

            var pts = [[x1,h1], [x1,y], [x2,y], [x2,h2]];
            dc.fillPolygon(pts);
        }

        var lenName = dc.getTextWidthInPixels(name, Graphics.FONT_SMALL);
        if (lenName > 60) 
        {
            lenName = 60;
            name = name.substring(0, 10);
        }

        if (timer !=0) {
            // Progress bar
            dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
            var progress = width * ((length.toFloat()-climbToGo) / length.toFloat()); 
            dc.fillRectangle(0,height-3, progress, 2);

            // Name - Dist.
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(2, 2, Graphics.FONT_SMALL, name, Graphics.TEXT_JUSTIFY_LEFT);
            var lenNme = dc.getTextWidthInPixels(name, Graphics.FONT_SMALL);
            dc.drawBitmap(lenName+5, 7, resFinish);
            dc.drawText(lenName+17, 2, Graphics.FONT_SMALL, climbToGo.toNumber()+"m", Graphics.TEXT_JUSTIFY_LEFT);

            // Time
            var dispTime = secondsToTimeString(climbTime);
            dc.drawText(2, 22, Graphics.FONT_SMALL, dispTime, Graphics.TEXT_JUSTIFY_LEFT);
        }
        else
        {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(2, 2, Graphics.FONT_SMALL, name, Graphics.TEXT_JUSTIFY_LEFT);
            var lenNme = dc.getTextWidthInPixels(name, Graphics.FONT_SMALL);
            dc.drawBitmap(lenName+5, 7, resStart);
            dc.drawText(lenName+17, 2, Graphics.FONT_SMALL, distToClimb.toNumber()+"m", Graphics.TEXT_JUSTIFY_LEFT);

            // Time
            if (lastTime !=0) {
                var dispTime = secondsToTimeString(lastTime);
                dc.drawText(2, 22, Graphics.FONT_SMALL, dispTime, Graphics.TEXT_JUSTIFY_LEFT);
            }
        }


    }

    function secondsToTimeString(totalSeconds) {
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds /60) % 60;
        var seconds = totalSeconds % 60;
        var timeString = format("$1$:$2$:$3$", [hours.format("%01d"), minutes.format("%02d"), seconds.format("%02d")]);
        return timeString;
    }

    function maxAlt(alts) {
        var counter=0;
        var biggest=0;
        do {
        if(alts[counter]>biggest){
            biggest=alts[counter];
        }
        counter++;
        }
        while (counter < alts.size());
        return biggest;
    }

function toArray(string, splitter) {
var array = new [50]; //Use maximum expected length
var index = 1;
var location;
do
{
location = string.find(splitter);
if (location != null) {
array[index] = string.substring(0, location);
string = string.substring(location + 1, string.length());
index++;
}
}
while (location != null);
array[index] = string;
array[0] = index;

var result = new [index];
for (var i = 0; i < index; i++) {
result= array;
}
return result;
}
}
