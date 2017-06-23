using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Graphics;
using Toybox.System as System;
using Toybox.Position as Pos;


//! @author Konrad Paumann
class PiloteField extends App.AppBase {

    function getInitialView() {
        var view = new PiloteView();
        return [ view ];
    }
}

//! A DataField that shows some infos.
//!
//! @author Konrad Paumann
class PiloteView extends Ui.DataField {

   hidden const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const HEADER_FONT = Graphics.FONT_XTINY;
    hidden const VALUE_FONT = Graphics.FONT_NUMBER_MEDIUM;
    hidden const ZERO_TIME = "0:00";
    hidden const ZERO_DISTANCE = "0.00";
    
    hidden var kmOrMileInMeters = 1000;
    hidden var is24Hour = true;
    hidden var distanceUnits = System.UNIT_METRIC;
    hidden var textColor = Graphics.COLOR_BLACK;
    hidden var inverseTextColor = Graphics.COLOR_WHITE;
    hidden var backgroundColor = Graphics.COLOR_WHITE;
    hidden var inverseBackgroundColor = Graphics.COLOR_BLACK;
    hidden var inactiveGpsBackground = Graphics.COLOR_LT_GRAY;
    hidden var batteryBackground = Graphics.COLOR_WHITE;
    hidden var batteryColor1 = Graphics.COLOR_GREEN;
    hidden var hrColor = Graphics.COLOR_RED;
    hidden var lapColor = Graphics.COLOR_DK_BLUE;
    hidden var headerColor = Graphics.COLOR_DK_GRAY;
        
    hidden var paceStr, avgPaceStr, hrStr, distanceStr, durationStr,lapPaceStr;
    
    hidden var paceData = new DataQueue(10);
    hidden var paceData30 = new DataQueue(30);
    hidden var paceData3 = new DataQueue(3);

    hidden var doUpdates = 0;
	
	hidden var speed = 0;
    hidden var avgSpeed= 0;
    hidden var maxSpeed= 0;
    hidden var hr = 0;
    hidden var avghr = 0;
    hidden var maxhr = 0;
    hidden var distance = 0;
    hidden var elapsedTime = 0;
    hidden var gpsSignal = 0;
    
    hidden var currentCadence = 0;
    hidden var averageCadence = 0;
    hidden var maxCadence = 0;
    
    
     //lap
    hidden var compteurLap = 0;
    hidden var distLap=0;
    hidden var distLapStr;
    hidden var durationLap;
    hidden var timeLap=0;
    hidden var timeLapTmp=0;
    hidden var distLapCourant=0;
    hidden var timeLapCourant=0;
    hidden var speedLap = 0;
    hidden var speedLapCourant = 0;
    hidden var timeLapStr=ZERO_TIME;
    hidden var distLapOnLap = 0;
    
    //
    hidden var ascension=0;
    
    
    hidden var hasBackgroundColorOption = false;
    
    function initialize() {
        DataField.initialize();
    }
    
    function onTimerLap(){
    	compteurLap ++;
    	speedLapCourant = speedLap;
    	distLapOnLap = distLap;
        distLapCourant = distance != null ? distance : 0;
        timeLapTmp = elapsedTime - timeLapCourant; 
        timeLapCourant = elapsedTime != null ? elapsedTime : 0;
                
        if (timeLapTmp != null && timeLapTmp > 0) {
 			timeLapStr = msToTime(timeLapTmp,0);
        } else {
            timeLapStr = ZERO_TIME;
        } 

    }

    //! The given info object contains all the current workout
    function compute(info) {
        if (info.currentSpeed != null) {
            paceData.add(info.currentSpeed);
            paceData30.add(info.currentSpeed);
            paceData3.add(info.currentSpeed);
        } else {
            paceData.reset();
            paceData30.reset();
            paceData3.reset;
        }
        
        speed = info.currentSpeed != null ? info.currentSpeed : 0;
        avgSpeed = info.averageSpeed != null ? info.averageSpeed : 0;
        maxSpeed = info.maxSpeed != null ? info.maxSpeed : 0;
        elapsedTime = info.timerTime != null ? info.timerTime : 0;        
        hr = info.currentHeartRate != null ? info.currentHeartRate : 0;
        avghr = info.averageHeartRate != null ? info.averageHeartRate : 0;
        maxhr = info.maxHeartRate != null ? info.maxHeartRate : 0;
        distance = info.elapsedDistance != null ? info.elapsedDistance : 0;
        gpsSignal = info.currentLocationAccuracy != null ? info.currentLocationAccuracy : 0;
        
		
		speed = speed * 3.6;

        maxCadence = info.maxCadence != null ? info.maxCadence : 0;
        averageCadence = info.averageCadence != null ? info.averageCadence : 0;
        currentCadence = info.currentCadence != null ? info.currentCadence : 0;
        
        
        ascension = info.totalAscent != null ? info.totalAscent : 0;
    
        if (compteurLap == 0){
            speedLap = avgSpeed;
            distLap=distance;
            timeLap=elapsedTime;
        }else{
            if (elapsedTime != null &&  distance != null){
                distLap = distance - distLapCourant;
                timeLap =  elapsedTime - timeLapCourant;
                if (distLap>0 && timeLap>0){
                    var timeLapSecond = timeLap / 1000;
                    if (timeLapSecond != null && timeLapSecond > 0.2){
                        speedLap = distLap / timeLapSecond;
                    }else{
                        speedLap = 0;
                    }
                   
                }else{
                    speedLap = 0;
                }
            }
        }
        
        //if (hr>170){
        //	hrColor = Graphics.COLOR_RED;
    	//}else if (hr<140){
    	//	hrColor = Graphics.COLOR_GREEN;
    	//}else{
    	//	hrColor = textColor;
    	//}
    }
    
    function onLayout(dc) {
        setDeviceSettingsDependentVariables();
        //onUpdate(dc);
    }
    
    function onShow() {
        doUpdates = true;
        return true;
    }
    
    function onHide() {
        doUpdates = false;
    }
    
    function onUpdate(dc) {
        if(doUpdates == false) {
            return;
        }
        
        setColors();
        // reset background
        dc.setColor(backgroundColor, backgroundColor);
        dc.fillRectangle(0, 0, 218, 218);
        
        drawValues(dc);
    }

    function setDeviceSettingsDependentVariables() {
        hasBackgroundColorOption = (self has :getBackgroundColor);
    }
    
    function setColors() {
        if (hasBackgroundColorOption) {
            backgroundColor = getBackgroundColor();
            //TODO:pour les tests
            //backgroundColor = Graphics.COLOR_BLACK;
            textColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            inverseTextColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_WHITE;
            inverseBackgroundColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_DK_GRAY: Graphics.COLOR_BLACK;
            hrColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
            headerColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_LT_GRAY: Graphics.COLOR_DK_GRAY;
            batteryColor1 = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_BLUE : Graphics.COLOR_DK_GREEN;
            lapColor = (backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_BLUE;
        }
    }
    

        
    function drawValues(dc) {
    
        //time
        var clockTime = System.getClockTime();
        var time = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%.2d")]);
          
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillRectangle(0,0,218,20);
        dc.setColor(inverseTextColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(106, 10, Graphics.FONT_TINY, time, CENTER);
        var battery = System.getSystemStats().battery;
        dc.drawText(142, 11, HEADER_FONT,battery.format("%d"), CENTER);
 
        var computeAvgSpeed = computeAverageSpeed(paceData);
        var computeAvgSpeed3s = computeAverageSpeed(paceData3);
       
        
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        
        //timeLap
        var durationLap;
        if (timeLap != null && timeLap > 0) {
     		durationLap=msToTime(timeLap,0);
        } else {
            durationLap = ZERO_TIME;
        } 

       //AVG NEW
        dc.drawText(35, 85, HEADER_FONT, "avg", CENTER);
        dc.drawText(35 , 111, VALUE_FONT, getMinutesPerKmOrMile(avgSpeed), CENTER);//
        //dc.drawText(87, 85, HEADER_FONT, "lap", CENTER);
        dc.drawText(87 , 120, Graphics.FONT_NUMBER_MILD, getMinutesPerKmOrMile(speedLapCourant), CENTER);//
        dc.drawText(87 , 93, Graphics.FONT_NUMBER_MILD, timeLapStr, CENTER);
        dc.drawText(127 , 111, Graphics.FONT_NUMBER_MILD, convertDistance(distLapOnLap) , CENTER);
        dc.drawText(127, 85, HEADER_FONT, "dlap", CENTER);
        
        
	
        dc.drawText(182 , 111, VALUE_FONT, getMinutesPerKmOrMile(computeAvgSpeed) , CENTER);//
       
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        
        if (computeAvgSpeed>computeAvgSpeed3s){
        	dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(148,80,80,12);
        }else if (computeAvgSpeed3s>computeAvgSpeed){
         	dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
         	dc.fillRectangle(148,80,80,12);
        }
        
        //hr=111;
        if (hr>170){
        	dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(110,165,47,5);
    	}else if (hr<140 && hr>0){
    		dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        	dc.fillRectangle(110,165,47,5);
    	}
    	

        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT); 
        //dc.drawText(127 , 111, Graphics.FONT_NUMBER_MILD, getMinutesPerKmOrMile(computeAverageSpeed(paceData30)) , CENTER);//
        dc.drawText(182, 85, HEADER_FONT, "10s", CENTER);
        
        
        //lap
        dc.drawText(145, 145, HEADER_FONT, "lap", CENTER);
        dc.drawText(145, 155, HEADER_FONT, "time", CENTER);
        
        dc.drawText(110 , 151, Graphics.FONT_NUMBER_MILD, durationLap, CENTER); 
        dc.drawText(60 , 151, Graphics.FONT_NUMBER_MILD, getMinutesPerKmOrMile(speedLap), CENTER);//
        dc.drawText(180 , 151, Graphics.FONT_NUMBER_MILD, convertDistance(distLap), CENTER);//
        
        
 
        //dc.drawText(30 , 151, Graphics.FONT_NUMBER_MILD, distLapStr, CENTER);//
        //dc.drawText(150 , 28, Graphics.FONT_TINY, distLapStr, CENTER);//distLapStr
        
        

        
        
        
        //hr
        if (hr>0){
	        dc.setColor(hrColor, Graphics.COLOR_TRANSPARENT);
	        dc.drawText(130, 185, Graphics.FONT_NUMBER_MEDIUM,hr.format("%d"), CENTER);//hr.format("%d")
	      
	        
	        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
	        dc.drawText(60, 172, HEADER_FONT,"avg", CENTER);
	        dc.drawText(90, 175, Graphics.FONT_NUMBER_MILD,avghr.format("%d"), CENTER);
	        dc.drawText(64, 193, HEADER_FONT,"max", CENTER);
	        dc.drawText(90, 200, Graphics.FONT_NUMBER_MILD,maxhr.format("%d"), CENTER);//maxhr.format("%d")
        }else{
        	//affichage d+
        	dc.drawText(147, 172, HEADER_FONT,"D+", CENTER);
        	dc.drawText(50, 175, Graphics.FONT_NUMBER_MILD,speed.format("%.1f"), CENTER);//speed.format("%d")
        	dc.drawText(100, 185, Graphics.FONT_NUMBER_MEDIUM,ascension.format("%d"), CENTER);//ascension.format("%d")
        	dc.drawText(145, 202, HEADER_FONT,"m", CENTER);
        }
        
        //cadence
        //dc.drawText(55 , 28, Graphics.FONT_TINY, averageCadence.format("%d"), CENTER);// averageCadence.format("%d")
        dc.drawText(55 , 28, Graphics.FONT_TINY, compteurLap.format("%d"), CENTER);//distLapStr
	    dc.drawText(90 , 28, Graphics.FONT_TINY, currentCadence.format("%d"), CENTER);// currentCadence.format("%d")
        
        //VMAX
        var vMax = maxSpeed * 3.6;
        dc.drawText(172, 175, Graphics.FONT_NUMBER_MILD,vMax.format("%.1f")  , CENTER);   //vMax.format("%.1f")     
        

        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()-70, 56, VALUE_FONT,convertDistance(distance) , CENTER);//distStr
        dc.drawText(dc.getWidth()-20, 70, HEADER_FONT, "km", CENTER);
        
                
        //duration
        var duration;
        var timeEtude = elapsedTime;
        if (timeEtude != null && timeEtude > 0) {
            duration = msToTime(timeEtude,0);
        } else {
            duration = ZERO_TIME;
        } 
		dc.drawText(65, 56, VALUE_FONT, duration, CENTER);//duration      	
        dc.drawText(17, 72,Graphics.FONT_TINY,msToTime(timeEtude,1), CENTER);//msToTime(timeEtude,1)    	
            
        
               
        //grid
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, 164, dc.getWidth(), 164);
        dc.drawLine(0, 80, dc.getWidth(), 80);
        dc.drawLine(0, 136, dc.getWidth(), 136);
        dc.drawLine(0, 37, dc.getWidth(), 37);
        
        
        dc.drawLine(dc.getWidth()/4+15, 80, dc.getWidth()/4+15, 136);
        dc.drawLine(dc.getWidth()/2, 80, dc.getWidth()/2, 136);
        dc.drawLine(3*dc.getWidth()/4-15, 80, 3*dc.getWidth()/4-15, 136);
        
        
        dc.drawLine(dc.getWidth()/4+30, 137, dc.getWidth()/4+30, 165);
        dc.drawLine(dc.getWidth()/2, 20, dc.getWidth()/2, 80);
        
       
        
        if (hr>0){
        	dc.drawLine(dc.getWidth()/2, 165, dc.getWidth()/2, dc.getHeight());
 		}
        dc.drawLine(dc.getWidth()/2+47, 165, dc.getWidth()/2+47, dc.getHeight());
        
                
        // gps 
        if (gpsSignal <= 2) {
           dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
           dc.drawText(22, 152, HEADER_FONT, "GPS", CENTER);
        } 
        
    }
    
   
    
    function computeAverageSpeed(tableau) {
        var size = 0;
        var data = tableau.getData();
        var sumOfData = 0.0;
        for (var i = 0; i < data.size(); i++) {
            if (data[i] != null) {
                sumOfData = sumOfData + data[i];
                size++;
            }
        }
        if (sumOfData > 0) {
            return sumOfData / size;
        }
        return 0.0;
    }
    
   
    
	function msToTime(ms,isHour) {
    	var seconds = (ms / 1000) % 60;
    	var minutes = (ms / 60000) % 60;
    	var hours = ms / 3600000;
    	
    	if (isHour){
    		if (hours>0){
    			return hours.format("%d");
    		}else{
    			return "";
    		}
    	}else{
    		if (minutes < 10){
    			return Lang.format("$1$:$2$", [minutes.format("%d"), seconds.format("%02d")]);
    		}
    		else{
    			return Lang.format("$1$:$2$", [minutes.format("%02d"), seconds.format("%02d")]);
    		}	
    	} 
    }
    
     function convertDistance(metres) {
    	var result;
    	
    	if( metres == null ) {
    		result = 0;
    	} else {
	    	result = metres / 1000.0;
	    }
    	
    	return Lang.format("$1$", [result.format("%.2f")]);
    }
    
    function getMinutesPerKmOrMile(speedMetersPerSecond) {
        if (speedMetersPerSecond != null && speedMetersPerSecond > 0.2) {
            var metersPerMinute = speedMetersPerSecond * 60.0;
            var minutesPerKmOrMilesDecimal = kmOrMileInMeters / metersPerMinute;
            var minutesPerKmOrMilesFloor = minutesPerKmOrMilesDecimal.toNumber();
            var seconds = (minutesPerKmOrMilesDecimal - minutesPerKmOrMilesFloor) * 60;
            return minutesPerKmOrMilesDecimal.format("%2d") + ":" + seconds.format("%02d");
        }
        return ZERO_TIME;
    }

}

//! A circular queue implementation.
//! @author Konrad Paumann
class DataQueue {

    //! the data array.
    hidden var data;
    hidden var maxSize = 0;
    hidden var pos = 0;

    //! precondition: size has to be >= 2
    function initialize(arraySize) {
        data = new[arraySize];
        maxSize = arraySize;
    }
    
    //! Add an element to the queue.
    function add(element) {
        data[pos] = element;
        pos = (pos + 1) % maxSize;
    }
    
    //! Reset the queue to its initial state.
    function reset() {
        for (var i = 0; i < data.size(); i++) {
            data[i] = null;
        }
        pos = 0;
    }
    
    //! Get the underlying data array.
    function getData() {
        return data;
    }
}