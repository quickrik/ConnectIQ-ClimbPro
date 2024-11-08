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
    hidden var data = [0, 40, 50, 110, 120,130,140,170,180];
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
    hidden var dist=0;

        // Set the target GPS coordinates (latitude and longitude)
    const targetLat = -43.563172579; // Replace with target latitude
    const targetLon = 172.598233192; // Replace with target longitude
    const length = 800;
    const name = "Worsley Rd";

    const proximityThreshold = 25; // Proximity threshold in meters



    function initialize() {
        DataField.initialize();
        mValue = 0.0f;
        var climbpoints = data.size();

        for (var i=0; i < data.size()-1; i++)
        {
            climbgrad[i] = ((data[i+1] -data[i]) / 1000f ) * 100f;
             //System.println(climbgrad[i]);
        }

       // die;
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {

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
            System.println("Location: " + Lat +", " + Lon);
            distToClimb = calculateDistance(Lat, Lon, targetLat, targetLon);
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
                    climbToGo = length - (covered - proximityThreshold);
                    climbTime =Time.now().value()-timer;
                    if (climbToGo <= 0) {
                        inClimb = 0;
                        timer=0;
                    }

                }
            }
            System.println(dist+", "+inClimb+", "+covered+", "+climbToGo+", "+climbTime);
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
        var barWidth = 180 /((length-1)/100);
        var startX = 20;
        var maxBarHeight = 120.0f;
        
        // Colors for each bar
        var colours = [Graphics.COLOR_RED, Graphics.COLOR_GREEN, Graphics.COLOR_BLUE, Graphics.COLOR_ORANGE];

        // Background colour
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_TRANSPARENT);
        
        // Draw each bar
        for (var i = 0; i < data.size()-1; i++) {
            var h1 = 180-((data[i] / maxBarHeight) * maxBarHeight);
            var h2 = 180-((data[i+1] / maxBarHeight) * maxBarHeight);
            var x1 = (i * (barWidth));
            var x2 = ((i+1) * (barWidth));
            var y = 180; // Adjust to place bars within the data field
            
            // Set the colour for each bar
            var grad = ((data[i+1] -data[i]) / 1000f ) * 100f;
            
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            if ((grad >=3) && (grad <6)) {dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);}
            if ((grad >=6) && (grad <9)) {dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);}
            if ((grad >=9) && (grad <12)) {dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);}
            if (grad >=12) {dc.setColor(Graphics.COLOR_DK_RED, Graphics.COLOR_TRANSPARENT);}

            var pts = [[x1,h1], [x1,y], [x2,y], [x2,h2]];
           // var pts = [[20,10], [10,100], [100,100], [100,10]];
            dc.fillPolygon(pts);
            if (timer !=0) {
                dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
                var progress = 180* ((length-climbToGo) / length); 
                 dc.fillRectangle(0,182, progress, 2);

                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(5, 5, Graphics.FONT_SMALL, name, Graphics.TEXT_JUSTIFY_LEFT);
                    dc.drawText(5, 25, Graphics.FONT_SMALL, climbToGo.toNumber()+"m", Graphics.TEXT_JUSTIFY_LEFT);
                    var dispTime = secondsToTimeString(climbTime);
                    dc.drawText(5, 45, Graphics.FONT_SMALL, dispTime, Graphics.TEXT_JUSTIFY_LEFT);
            }
            else
            {
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                    dc.drawText(5, 25, Graphics.FONT_SMALL, distToClimb.toNumber()+"m", Graphics.TEXT_JUSTIFY_LEFT);

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
}