
float bSpeed, bSpeed2, gestures, bowPos, pitch, volume, density, pressure, spare, slider;
int targetBees = 25;  // default

// Clear names for the newly trained audience controls.
int audienceSpeedClass = 1;       // 1 still, 2 moderate, 3 energetic
int audienceWeatherClass = 2;     // 2 neutral, 1 hot, 3 storm
int audienceHorizontalClass = 2;  // 1 left, 2 centre, 3 right
// The controller currently permitted to affect the visuals.
int activeHorizontalClass = 2;

// Existing violin pitch model remains unchanged.
int violinPitchClass = 1;

// Used to print only when a classification changes.
int previousAudienceSpeedClass = -1;
int previousAudienceWeatherClass = -1;
int previousAudienceHorizontalClass = -1;
int previousViolinPitchClass = -1;



void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/wek/outputs") == true) {
    if (theOscMessage.checkTypetag("ffffffffff")) {
      //bow speed
      bSpeed = theOscMessage.get(0).floatValue();
      //bow position
      bSpeed2 = theOscMessage.get(1).floatValue();
      //starting gesture
      gestures = theOscMessage.get(2).floatValue();
      //bow acceleration
      bowPos = theOscMessage.get(3).floatValue();
      //note density
      pitch = theOscMessage.get(4).floatValue();
      //amplitude
      volume = theOscMessage.get(5).floatValue();
      //println("volume; ", volume);
      //pitches
      density = theOscMessage.get(6).floatValue();
      //range
      pressure = theOscMessage.get(7).floatValue();
      spare = theOscMessage.get(8).floatValue();
      slider = theOscMessage.get(9).floatValue();

      // Convert Wekinator's float outputs into safe class numbers.
audienceSpeedClass =
  constrain(round(bSpeed), 1, 3);

audienceWeatherClass =
  constrain(round(gestures), 1, 3);

audienceHorizontalClass =
  constrain(round(bowPos), 1, 3);

violinPitchClass =
  constrain(round(pitch), 1, 4);

// Print only when one of the classifications changes.
if (
  audienceSpeedClass != previousAudienceSpeedClass ||
  audienceWeatherClass != previousAudienceWeatherClass ||
  audienceHorizontalClass != previousAudienceHorizontalClass ||
  violinPitchClass != previousViolinPitchClass
) {
  println(
    "audience speed=" + audienceSpeedClass +
    " weather=" + audienceWeatherClass +
    " horizontal=" + audienceHorizontalClass +
    " | violin pitch=" + violinPitchClass +
    " | slider=" + round(slider) +
    " | mode=" + finalSlider
  );

  previousAudienceSpeedClass = audienceSpeedClass;
  previousAudienceWeatherClass = audienceWeatherClass;
  previousAudienceHorizontalClass = audienceHorizontalClass;
  previousViolinPitchClass = violinPitchClass;
}

      //swarm.updateHeights(pitch, flower);
      //println("bPos ;" + pitch);
      //swarm.updateHeights(violinPitchClass, flower);
       
      volume = theOscMessage.get(5).floatValue();
      float mappedValue = map(volume, 1, 5, 1, 15);
      targetBees = int(pow(mappedValue, 2));


      remember(volumeMemory, volume);
      remember(gestureMemory, gestures);
      remember(densityMemory, density);
      remember(bowPosMemory, pitch);  // Performer pitch is intentional here.



      // Optional: handle button 4 kill here
    }
  }

  if (theOscMessage.checkAddrPattern("/max/outputs/buttons") == true) {

    int buttonID = theOscMessage.get(0).intValue();

    println("button: " + buttonID);
      switch (buttonID) {
    case 5: // short press: manual mode
      useAutonomousSlider = false;
      println("✅ Manual Slider Mode (performer control)");
      break;

    case 6: // long press: autonomous mode
      useAutonomousSlider = true;
      println("✅ Autonomous Slider Mode (system decides)");
      sendAutonomousSliderToMax();
      break;


  }
}
}

void sendAutonomousSliderToMax() {
  if (toMax != null && oscP5 != null) {  // ✅ optional safe check
    OscMessage msg = new OscMessage("/processing/autonomousSlider");
    msg.add(autonomousSlider);  // 1, 2, or 3
    oscP5.send(msg, toMax);
  } else {
    println("❌ Cannot send autonomousSlider - OSC or toMax not ready");
  }
}
