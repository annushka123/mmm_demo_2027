
float sep, coh;
float heatStrength = 0;
float stormStrength = 0;
float audienceHorizontalInfluence = 1.0f;

// Mode 3 is driven by a slowly changing interpretation of recent behaviour.
// These values retain state between frames, which gives the system inertia.
float mode3Energy = 0.35f;
float mode3Mood = 0.35f;
float mode3HeatStrength = 0.0f;
float mode3StormStrength = 0.0f;
float mode3SystemX = 0.0f;
float autonomousMoodScore = 0.35f;
int lastAutonomousDecisionTime = -10000;
int lastMode3ReportTime = -10000;




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


float average(ArrayList<Float> data) {
  float sum = 0;
  for (float v : data) {
    sum += v;
  }
  return (data.size() > 0) ? sum / data.size() : 0;
}

float normalisedAverage(
  ArrayList<Float> data,
  float minimum,
  float maximum,
  float fallback
) {
  if (data.size() == 0) {
    return fallback;
  }

  float value = average(data);
  float normalised = (value - minimum) / (maximum - minimum);
  return constrain(normalised, 0.0f, 1.0f);
}

float classFraction(ArrayList<Float> data, int wantedClass) {
  if (data.size() == 0) {
    return 0.0f;
  }

  int matches = 0;

  for (float value : data) {
    if (round(value) == wantedClass) {
      matches++;
    }
  }

  return matches / (float)data.size();
}

void drawMode3() {
  // The current audience direction is deliberately ignored here. Instead,
  // the system recalls the recent directional tendency and then departs from
  // it using slow Perlin-noise movement.
  activeHorizontalClass = 2;
  audienceHorizontalInfluence = 0.0f;

  // Performer memory: volume contributes most to energy, density contributes
  // to agitation, and recent audience movement contributes a smaller amount.
  float volumeLevel =
    normalisedAverage(volumeMemory, 0.1f, 5.0f, 0.35f);

  float densityLevel =
    normalisedAverage(densityMemory, 1.0f, 3.0f, 0.35f);

  float audienceMovementLevel =
    normalisedAverage(audienceSpeedMemory, 1.0f, 3.0f, 0.25f);

  float targetEnergy =
    volumeLevel * 0.45f +
    densityLevel * 0.35f +
    audienceMovementLevel * 0.20f;

  // A slow internal fluctuation prevents exact replay of the remembered data.
  float systemVariation = noise(frameCount * 0.003f + 19.0f);
  float targetMood =
    constrain(targetEnergy * 0.75f + systemVariation * 0.25f, 0.0f, 1.0f);

  mode3Energy = lerp(mode3Energy, targetEnergy, 0.018f);
  mode3Mood = lerp(mode3Mood, targetMood, 0.012f);

  // Weather recalls how often the audience selected heat or storm. The
  // system adds its own slow climate drift, so the result resembles the
  // interaction without reproducing it literally.
  float heatMemory = classFraction(gestureMemory, 1);
  float stormMemory = classFraction(gestureMemory, 3);
  float rememberedClimate = stormMemory - heatMemory;

  float autonomousClimate =
    map(noise(frameCount * 0.0015f + 73.0f), 0.0f, 1.0f, -1.0f, 1.0f);

  float climate =
    rememberedClimate * 0.65f + autonomousClimate * 0.35f;

  float targetHeat =
    constrain((-climate - 0.12f) / 0.88f, 0.0f, 1.0f);

  float targetStorm =
    constrain((climate - 0.12f) / 0.88f, 0.0f, 1.0f);

  mode3HeatStrength =
    lerp(mode3HeatStrength, targetHeat, 0.012f);

  mode3StormStrength =
    lerp(mode3StormStrength, targetStorm, 0.012f);

  color memoryCalmBG = color(24, 58, 68);
  color memoryHeatBG = color(118, 27, 54);
  color memoryStormBG = color(7, 10, 42);

  color memoryCalmTint = color(155, 225, 210);
  color memoryHeatTint = color(255, 115, 82);
  color memoryStormTint = color(105, 120, 220);

  targetBG =
    lerpColor(memoryCalmBG, memoryHeatBG, mode3HeatStrength);
  targetBG =
    lerpColor(targetBG, memoryStormBG, mode3StormStrength);

  targetTint =
    lerpColor(memoryCalmTint, memoryHeatTint, mode3HeatStrength);
  targetTint =
    lerpColor(targetTint, memoryStormTint, mode3StormStrength);

  targetTintAlpha =
    165.0f + mode3Energy * 55.0f - mode3StormStrength * 35.0f;

  alphaPulse =
    sin(frameCount * (0.012f + mode3Mood * 0.045f)) *
    (12.0f + mode3Mood * 42.0f);

  // Horizontal motion is 30% remembered audience tendency and 70% the
  // system's own slow movement.
  float rememberedHorizontal = 2.0f;
  if (horizontalMemory.size() > 0) {
    rememberedHorizontal = average(horizontalMemory);
  }

  float rememberedX =
    map(rememberedHorizontal, 1.0f, 3.0f, width * 0.25f, width * 0.75f);

  float autonomousX =
    map(
      noise(frameCount * 0.0022f + 131.0f),
      0.0f,
      1.0f,
      width * 0.12f,
      width * 0.88f
    );

  mode3SystemX = lerp(autonomousX, rememberedX, 0.30f);

  // Performer pitch is remembered, then gently displaced by the system.
  float rememberedPitch = violinPitchClass;
  if (bowPosMemory.size() > 0) {
    rememberedPitch = average(bowPosMemory);
  }

  float pitchDeparture =
    map(noise(frameCount * 0.0027f + 211.0f), 0.0f, 1.0f, -0.8f, 0.8f);

  float autonomousPitch =
    constrain(rememberedPitch + pitchDeparture, 1.0f, 4.0f);

  sep = lerp(0.65f, 2.25f, mode3Mood);
  coh = lerp(1.85f, 0.35f, mode3Mood);

  float beeSpeed =
    lerp(0.8f, 5.2f, mode3Energy) *
    lerp(0.88f, 1.12f, systemVariation);

  int rememberedBees = round(lerp(18.0f, 130.0f, volumeLevel));
  int rememberedFlowers = round(lerp(25.0f, 180.0f, densityLevel));

  flowerSparkle =
    mode3Energy > 0.48f || mode3StormStrength > 0.30f;

  boolean driftingFlowers =
    mode3StormStrength > 0.18f || mode3Mood > 0.78f;

  for (int i = 0; i < flower.length; i++) {
    flower[i].updateDrift(driftingFlowers);
    flower[i].display();
  }

  flowers.updateFlowerCount(rememberedFlowers);
  flowers.display();

  swarm.setErratic(
    mode3StormStrength > 0.55f || mode3Mood > 0.76f
  );
  swarm.setSwarmSocial(sep, coh);
  swarm.updateSwarmSize(rememberedBees);
  swarm.updateHeights(autonomousPitch, flower);
  swarm.updateSpeed(beeSpeed);
  swarm.applyBehaviors();
  swarm.display();

  // A compact status report makes the relationship visible while testing,
  // without flooding the console every frame.
  if (millis() - lastMode3ReportTime >= 5000) {
    lastMode3ReportTime = millis();
    println(
      "Mode 3 memory: energy=" + nf(mode3Energy, 1, 2) +
      " mood=" + nf(mode3Mood, 1, 2) +
      " heat=" + nf(mode3HeatStrength, 1, 2) +
      " storm=" + nf(mode3StormStrength, 1, 2)
    );
  }
}


void updateAutonomousSlider() {
  // Make a decision only every four seconds. The old version added fresh
  // randomness every frame, which could make the system flicker between modes.
  if (millis() - lastAutonomousDecisionTime < 4000) {
    return;
  }

  lastAutonomousDecisionTime = millis();

  float densityLevel =
    normalisedAverage(densityMemory, 1.0f, 3.0f, 0.35f);

  float volumeLevel =
    normalisedAverage(volumeMemory, 0.1f, 5.0f, 0.35f);

  float pitchLevel =
    normalisedAverage(bowPosMemory, 1.0f, 4.0f, 0.50f);

  float slowVariation = noise(millis() * 0.00008f + 307.0f);

  float targetScore =
    densityLevel * 0.35f +
    volumeLevel * 0.35f +
    (1.0f - pitchLevel) * 0.15f +
    slowVariation * 0.15f;

  autonomousMoodScore =
    lerp(autonomousMoodScore, targetScore, 0.45f);

  int newAutonomousSlider = 1;

  if (autonomousMoodScore >= 0.38f) {
    newAutonomousSlider = 2;
  }

  if (autonomousMoodScore >= 0.68f) {
    newAutonomousSlider = 3;
  }

  if (newAutonomousSlider != autonomousSlider) {
    println(
      "Autonomous mode decision: " + newAutonomousSlider +
      " score=" + nf(autonomousMoodScore, 1, 2)
    );
  }

  autonomousSlider = newAutonomousSlider;
}
