
import oscP5.*;
import netP5.*;

import java.util.ArrayList;
import java.util.List;

boolean useAutonomousSlider = false;
int performerSlider = 1;
int autonomousSlider = 1;
int finalSlider = 1;  // this is what you'll switch on in draw()


int lastSentSlider = -1; // 🧠 tracks the last sent slider value


PImage grass;


OscP5 oscP5;
//NetAddress dest;
NetAddress toMax;


ArrayList<Float> volumeMemory = new ArrayList<Float>();
int gestureState = 0;
ArrayList<Float> gestureMemory = new ArrayList<Float>();
int maxMemorySize = 120;  // 2 seconds at 60fps
color currentBG;
color targetBG;
ArrayList<Float> densityMemory = new ArrayList<Float>();
ArrayList<Float> bowPosMemory = new ArrayList<Float>();

Flower[] flower;
Flowers flowers;
Swarm swarm;

ArrayList<Flowers> flowerList = new ArrayList<Flowers>();

color currentTint;
color targetTint;
float currentTintAlpha = 180;
float targetTintAlpha = 180;
float alphaPulse = 0;  // dynamic part


int targetFPS = 60;
int detailLevel = 1;


boolean flowerSparkle = false;





void setup() {
  fullScreen(P2D, 2);
  //size(600, 600);
  frameRate(30); // You can try 30 if it's still too slow

  grass = loadImage("grass.png");
  //colorMode(HSB, 360, 100, 100);
  oscP5 = new OscP5(this, 12000);
  toMax = new NetAddress("127.0.0.1", 6451);

  flower = new Flower[4];
  flower[0] = new Flower(width*0.63, height*0.18, 100, 0.4, 7);
  flower[1] = new Flower(width*0.4, height*0.4, 110, 0.9, 8);
  flower[2] = new Flower(width*0.6, height*0.60, 80, 0.5, 6);
  flower[3] = new Flower(width/2, height*0.83, 101, 0.63, 7);
  swarm = new Swarm(); // Initialize swarm
  flowers = new Flowers();


  currentBG = targetBG = color(30, 40, 70);  // default calm
  currentTint = targetTint = color(200, 220, 255);

  //bee.updateDimensions(width, height);
}

void draw() {
  // 👇 Smooth transition always
currentBG = lerpColor(currentBG, targetBG, 0.01);
currentTint = lerpColor(currentTint, targetTint, 0.01);
currentTintAlpha = lerp(currentTintAlpha, targetTintAlpha, 0.01);
//background(0);

//tint(red(currentTint), green(currentTint), blue(currentTint), currentTintAlpha);
float finalAlpha = constrain(currentTintAlpha + alphaPulse, 0, 255);

background(currentBG);
tint(red(currentTint), green(currentTint), blue(currentTint), finalAlpha);

image(grass, 0, 0, width, height);
noTint();

 performerSlider = (int)slider;
 
//if (useAutonomousSlider) {
//  finalSlider = autonomousSlider;
//} else {
//  finalSlider = performerSlider;
//}

adjustDetailLevel();

  if (useAutonomousSlider) {
    updateAutonomousSlider();   // 🧠 updates autonomousSlider
    finalSlider = autonomousSlider;
    
    if (autonomousSlider != lastSentSlider) {
      sendAutonomousSliderToMax();
      lastSentSlider = autonomousSlider; // 🧠 update memory
    }
  } else {
    finalSlider = performerSlider;
  }
  //background(0);  // Reset every frame

  //int sliderMode = (int)slider;  // Ensure consistent int type

  switch (finalSlider) {
  case 1:
    drawMode1();  // 🌼 Only flowers
    break;

  case 2:
    drawMode2();    // 🐝 Only swarm
    break;

  case 3:
    drawMode3(); // 🐝 + 🌼 Both
    break;

  default:
    // Optional: draw idle or debug screen
    fill(255);
    textAlign(CENTER, CENTER);
    text("Waiting for input...", width/2, height/2);
    break;
  }
  

}

void adjustDetailLevel() {
    float currentFPS = frameRate;
    if (currentFPS >= targetFPS - 5) {
        detailLevel = 1; // High Detail
    } else if (currentFPS >= targetFPS / 2) {
        detailLevel = 2; // Medium Detail
    } else {
        detailLevel = 3; // Low Detail
    }
}
