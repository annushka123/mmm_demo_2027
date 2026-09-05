class Flower {
    float x, y; // Position of the flower
    int baseColor; // Color of the flower
    int petalCount; // Number of petals
    float len; // Length of the petals
    float wid; // Width scaling of the petals
    int rowCount; // Number of petal rows
    float petalOpenness = 1.0;
    
PVector position;
PVector velocity;
PVector home;
boolean floating = false;


    Flower(float x, float y, float len, float wid, int rowCount) {
        this.x = x;
        this.y = y;
        this.baseColor = color(random(100, 255), random(100, 250), random(100, 255));
        this.petalCount = 8; // Fixed petal count for simplicity
        this.len = len; // Petal length
        this.wid = wid; // Petal width scaling
        this.rowCount = rowCount; // Number of rows of petals
        home = new PVector(x, y);
       position = new PVector(x, y);
velocity = PVector.random2D();
velocity.mult(0.5);  // adjust speed as needed
home = new PVector(x, y);


    }
    
void updateDrift(boolean isFloating) {
  floating = isFloating;

  if (floating) {
    position.add(velocity);

    // Bounce off walls
    if (position.x < 0 || position.x > width) {
      velocity.x *= -1;
    }
    if (position.y < 0 || position.y > height) {
      velocity.y *= -1;
    }

  } else {
    // Return to home smoothly
    position.x = lerp(position.x, home.x, 0.05);
    position.y = lerp(position.y, home.y, 0.05);
  }
}

void display() {
  // Direct weather only applies in Mode 1.
  float activeHeat =
    finalSlider == 1 ? heatStrength : 0;

  float activeStorm =
    finalSlider == 1 ? stormStrength : 0;

  // Petals close gradually as the heat increases.
  float targetOpenness =
    lerp(1.0, 0.28, activeHeat);

  petalOpenness =
    lerp(petalOpenness, targetOpenness, 0.05);

  stroke(0);
  strokeWeight(1);

  float deltaA = TWO_PI / petalCount;
  float petalLen = len;

  // Storm movement grows gradually.
  float stormX =
    sin(frameCount * 0.10 + home.y * 0.01) *
    10 *
    activeStorm;

  float stormY =
    cos(frameCount * 0.08 + home.x * 0.01) *
    4 *
    activeStorm;

  pushMatrix();
  translate(position.x + stormX, position.y + stormY);

  float pulseAmount =
    0.02 + 0.04 * activeStorm;

  float pulseSpeed =
    0.005 + 0.075 * activeStorm;

  float driftPulse =
    1.0 +
    sin(frameCount * pulseSpeed + home.x * 0.01) *
    pulseAmount;

  scale(driftPulse);

  for (int r = 0; r < rowCount; r++) {
    for (int i = 0; i < petalCount; i++) {
      float angle = i * deltaA;

      float oscillationAmount =
        5 -
        4 * activeHeat +
        15 * activeStorm;

      float oscillationSpeed =
        0.03 + 0.13 * activeStorm;

      float oscillation =
        sin(
          frameCount * oscillationSpeed +
          i * 1.7 +
          r * 0.6
        ) * oscillationAmount;

      fill(
        lerpColor(
          baseColor,
          color(255, 130, 150),
          r / (float) rowCount
        )
      );

      pushMatrix();
      rotate(angle + radians(oscillation));

      float petalDistance =
        petalLen * 0.7 * petalOpenness;

      float displayedLength =
        petalLen * (0.55 + 0.45 * petalOpenness);

      ellipse(
        petalDistance,
        0,
        displayedLength,
        petalLen * wid
      );

      popMatrix();
    }

    petalLen *= 0.8;
  }

  popMatrix();
}
//    void display() {
//        stroke(0);
//        strokeWeight(1);
//        float deltaA = (2 * PI) / petalCount;
//        float petalLen = len;

//        pushMatrix();
//        translate(position.x, position.y);


//        float driftPulse = 1.0 + sin(frameCount * 0.005 + home.x) * 0.02;

//scale(driftPulse);


//        for (int r = 0; r < rowCount; r++) {
//            for (int i = 0; i < petalCount; i++) {
//              float angle = i * deltaA;
//              float oscillation = sin(frameCount * 0.03 + i) * 5;
              
//            fill(lerpColor(baseColor, color(255, 130, 150), r / (float) rowCount)); // Gradient effect
//            pushMatrix();
//            rotate(angle + radians(oscillation));
            
//                            ellipse(petalLen * 0.7, 0, petalLen, petalLen * wid);
//            popMatrix();
//            }
//            petalLen *= 0.8; // Shrink petals in each row
//        }
//        popMatrix();
//    }
    



    }
    
