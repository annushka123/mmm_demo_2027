
float sep, coh;
float heatStrength = 0;
float stormStrength = 0;
float audienceHorizontalInfluence = 1.0f;




void drawMode1() {
  // Smoothly approach the selected weather.
  //float targetHeat =
  //  audienceWeatherClass == 1 ? 1.0 : 0.0;

  //float targetStorm =
  //  audienceWeatherClass == 3 ? 1.0 : 0.0;
  
  activeHorizontalClass = audienceHorizontalClass;
  audienceHorizontalInfluence = 1.0f;
  
  float targetHeat = 0.0f;
float targetStorm = 0.0f;

if (audienceWeatherClass == 1) {
  targetHeat = 1.0f;
}

if (audienceWeatherClass == 3) {
  targetStorm = 1.0f;
}

  heatStrength =
    lerp(heatStrength, targetHeat, 0.04);

  stormStrength =
    lerp(stormStrength, targetStorm, 0.04);

  // Weather colour palette.
  color sunnyBG = color(75, 105, 145);
  color hotBG = color(170, 40, 5);
  color stormBG = color(4, 8, 28);

  color sunnyTint = color(255, 235, 175);
  color hotTint = color(255, 90, 20);
  color stormTint = color(65, 85, 155);

  // Blend between the three weather states.
  targetBG =
    lerpColor(sunnyBG, hotBG, heatStrength);

  targetBG =
    lerpColor(targetBG, stormBG, stormStrength);

  targetTint =
    lerpColor(sunnyTint, hotTint, heatStrength);

  targetTint =
    lerpColor(targetTint, stormTint, stormStrength);

  targetTintAlpha =
    210 +
    heatStrength * 35 -
    stormStrength * 85;

  float weatherPulseAmount =
    8 +
    heatStrength * 27 +
    stormStrength * 57;

  float weatherPulseSpeed =
    0.02 +
    heatStrength * 0.03 +
    stormStrength * 0.09;

  alphaPulse =
    sin(frameCount * weatherPulseSpeed) *
    weatherPulseAmount;

  // Flower movement builds as the storm develops.
  for (int i = 0; i < flower.length; i++) {
    flower[i].updateDrift(stormStrength > 0.15);
  }

  swarm.setErratic(stormStrength > 0.65);

  flowerSparkle =
    heatStrength > 0.35 ||
    stormStrength > 0.35;

  float mappedPressure =
    map(pressure, 1, 3, 0, 1);

  int targetFlowers =
    int(pow(mappedPressure, 2) * 200);

  flowers.updateFlowerCount(targetFlowers);

  flowers.display();

  for (int i = 0; i < flower.length; i++) {
    flower[i].display();
  }

  swarm.updateSwarmSize(targetBees);
  swarm.updateHeights(violinPitchClass, flower);

  float audienceBeeSpeed;

  switch (audienceSpeedClass) {
    case 3:
      audienceBeeSpeed = 5.5;
      break;

    case 2:
      audienceBeeSpeed = 2.8;
      break;

    case 1:
    default:
      audienceBeeSpeed = 0.8;
      break;
  }

  swarm.updateSpeed(audienceBeeSpeed);
  swarm.applyBehaviors();
  swarm.display();
  
}

void drawMode2() {

  activeHorizontalClass = audienceHorizontalClass;
  audienceHorizontalInfluence = 0.55f;

  targetBG = color(255, 190, 150);
  targetTint = color(255, 230, 200);
  targetTintAlpha = 220;
  alphaPulse = sin(frameCount * 0.03) * 60;


  //for (int i = 0; i < flower.length; i++) {
  //  //flower[i].updateDrift(false);  // return to original position
  //flower[i].updateDrift(audienceWeatherClass == 3);
  //  flower[i].updateDrift(stormStrength > 0.15);
  //}
  for (int i = 0; i < flower.length; i++) {
  flower[i].updateDrift(false);
}

  flowerSparkle = true;

  //image(grass, 0, 0, width, height);
  swarm.setErratic(true);  // activate erratic mode
  float mappedPressure = map(pressure, 1, 3, 0, 1);
  int targetFlowers = int(pow(mappedPressure, 2) * 200);
  flowers.updateFlowerCount(targetFlowers);

  flowers.display();
  for (int i = 0; i < flower.length; i++) {
    flower[i].display();
  }
  swarm.updateSwarmSize(targetBees);
  swarm.updateHeights(pitch, flower);
  swarm.updateSpeed(bSpeed);
  swarm.applyBehaviors();
  swarm.display();
}


//void drawMode3() {

//  float avgDensity = average(densityMemory);
//  float avgVolume = average(volumeMemory);
//  float avgBowPos = average(bowPosMemory);


//  float normDensity = map(avgDensity, 1, 3, 0, 1);  // assuming density is 1-3
//  float normVolume = map(avgVolume, 0.1, 5.0, 0, 1); // volume is 0.1-5
//  float normBowPos = map(avgBowPos, 1, 4, 0, 1);     // bow position 1-4

//  float beeMoodScore =
//    (normDensity * 0.4) +
//    (normVolume * 0.4) +
//    ((1.0 - normBowPos) * 0.2);  // lower bow positions = higher agitation
    
//    // ✨ NEW: Add tiny randomness
//beeMoodScore += random(-0.05, 0.05);
//beeMoodScore = constrain(beeMoodScore, 0, 1);

//// ✨ NEW: Debugging
//println("🐝 Bee Mood Score: " + beeMoodScore);
    
//    int swarmMood;

//if (beeMoodScore < 0.3) {
//  swarmMood = 1;  // calm
//} else if (beeMoodScore < 0.6) {
//  swarmMood = 2;  // focused
//} else {
//  swarmMood = 3;  // chaotic
//}

//if (useAutonomousSlider) {
//  autonomousSlider = swarmMood;
//}



//  flowerSparkle = true;
//  swarm.setErratic(false);
//  alphaPulse = sin(frameCount * 0.01) * 30;
//  targetTintAlpha = 180;
//  gestureState = (int)gestures;



//  switch (gestureState) {
//  case 1:
//    targetBG = color(30, 40, 70);
//    targetTint = color(30, 220, 255);
//    targetTintAlpha = 200;
//    break;
//  case 2:
//    targetBG = color(80, 10, 30);
//    targetTint = color(255, 150, 180);
//    targetTintAlpha = 200;
//    break;
//  case 3:
//    targetBG = color(10, 0, 0);
//    targetTint = color(180, 100, 255);
//    targetTintAlpha = 180;
//    break;
//  default:
//    targetBG = color(20);
//    targetTint = color(255);
//    targetTintAlpha = 160;
//  }


//  currentBG = lerpColor(currentBG, targetBG, 0.05);
//  currentTint = lerpColor(currentTint, targetTint, 0.05);
//  currentTintAlpha = lerp(currentTintAlpha, targetTintAlpha, 0.05);

//  background(currentBG);
//  tint(red(currentTint), green(currentTint), blue(currentTint), currentTintAlpha);
//  image(grass, 0, 0, width, height);
//  noTint();




//  // 👁️ Memory-based behavior
//  float avgVol = constrain(average(volumeMemory), 0.05, 1.5);
//  //float flowerPulse = map(avgVol, 0.2, 1.0, 1.0, 1.5);
//  float beeSpeed = map(avgVol, 0.05, 1.0, 0.5, 6.0);

//  for (int i = 0; i < flower.length; i++) {
//    flower[i].updateDrift(true);  // 🌬 floating
//    flower[i].display();          // 🖼 draw it!
//  }

//  flowers.display(); // 🌸 dynamic flower field

//  swarm.updateSpeed(beeSpeed);
//  swarm.setMood(swarmMood, flower);

//  swarm.applyBehaviors();
//  swarm.display();
//}


float average(ArrayList<Float> data) {
  float sum = 0;
  for (float v : data) {
    sum += v;
  }
  return (data.size() > 0) ? sum / data.size() : 0;
}

void drawMode3() {
  
  activeHorizontalClass = 2;
  audienceHorizontalInfluence = 0.0f;
  
  flowerSparkle = true;
  swarm.setErratic(false);
  alphaPulse = sin(frameCount * 0.01) * 30;
  targetTintAlpha = 180;

  gestureState = (int)gestures;

  switch (gestureState) {
    case 1:
      targetBG = color(30, 40, 70);
      targetTint = color(30, 220, 255);
      targetTintAlpha = 200;
      sep = 0.5;   // tighter grouping
      coh = 2.0;   // strong cohesion
      break;
    case 2:
      targetBG = color(80, 10, 30);
      targetTint = color(255, 150, 180);
      targetTintAlpha = 200;
          sep = 1.0;   // balanced
    coh = 1.2;
      break;
    case 3:
      targetBG = color(10, 0, 0);
      targetTint = color(180, 100, 255);
      targetTintAlpha = 180;
          sep = 2.0;   // strong repulsion
    coh = 0.3;   // weak attraction
      break;
    default:
      targetBG = color(20);
      targetTint = color(255);
      targetTintAlpha = 160;
          sep = 1.0;
    coh = 1.0;
  }

  currentBG = lerpColor(currentBG, targetBG, 0.05);
  currentTint = lerpColor(currentTint, targetTint, 0.05);
  currentTintAlpha = lerp(currentTintAlpha, targetTintAlpha, 0.05);

  background(currentBG);
  tint(red(currentTint), green(currentTint), blue(currentTint), currentTintAlpha);
  image(grass, 0, 0, width, height);
  noTint();

  // Bee speed logic still OK:
  float avgVolume = constrain(average(volumeMemory), 0.05, 1.5);
  float beeSpeed = map(avgVolume, 0.05, 1.0, 0.5, 6.0);

  for (int i = 0; i < flower.length; i++) {
    flower[i].updateDrift(true);
    flower[i].display();
  }
  swarm.setSwarmSocial(sep, coh);
    swarm.updateSwarmSize(targetBees);
  swarm.updateHeights(pitch, flower);
  flowers.display(); 
  swarm.updateSpeed(beeSpeed);
  swarm.applyBehaviors();
  swarm.display();
}


void updateAutonomousSlider() {
  float avgDensity = average(densityMemory);
  float avgVolume = average(volumeMemory);
  float avgBowPos = average(bowPosMemory);

  float normDensity = map(avgDensity, 1, 3, 0, 1);
  float normVolume = map(avgVolume, 0.1, 5.0, 0, 1);
  float normBowPos = map(avgBowPos, 1, 4, 0, 1);

  float beeMoodScore =
    (normDensity * 0.4) +
    (normVolume * 0.4) +
    ((1.0 - normBowPos) * 0.2);

  beeMoodScore += random(-0.05, 0.05);  // add slight randomness
  beeMoodScore = constrain(beeMoodScore, 0, 1);

  println("🐝 Bee Mood Score: " + beeMoodScore);

  int swarmMood;

  if (beeMoodScore < 0.3) {
    swarmMood = 1;  // calm
  } else if (beeMoodScore < 0.6) {
    swarmMood = 2;  // focused
  } else {
    swarmMood = 3;  // chaotic
  }

  autonomousSlider = swarmMood;
}
