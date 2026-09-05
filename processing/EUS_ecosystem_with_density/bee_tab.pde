//import static processing.core.PApplet.*;


class Bee {
  float wingDirR = 1;
float wingDirL = 1;

  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector target; // Target position (flower)

  float maxSpeed = 3;   // Maximum speed
  float maxForce = 0.1; // Maximum steering force
  float size;           // Current size of the bee
  float headWidth;      // Dynamic head width

  // Adjusted wandering parameters for Swarm
  float wanderRadius = 5;
  float wanderDistance = 90;
  float wanderStrength = 0.1;
  float attractionStrength = 0.9;

  // Wing properties
  float wingMovementR = 4;
  float wingMovementL = 4;
  float wingSpeedR = 0.1;
  float wingSpeedL = 0.1;

  float opacity;
  boolean fadingOut;
  
  //bow_position behaviours
  float targetHeight;
  float heightLerp = 0.0;
  float lerpSpeed = 0.02;

  //bow_speed behaviours
  PVector targetSpeed;
  PVector newTargetSpeed;
  boolean erratic = false;

float separationFactor = 1.0;
float cohesionFactor = 1.0;



  Bee(float x, float y, float initialSize) {
    position = new PVector(x, y);
    velocity = new PVector(random(-1, 1), random(-1, 1));
    acceleration = new PVector(0, 0);
    target = new PVector(x, y);
    size = initialSize;
    headWidth = 10 * size;
    opacity = 0;
    fadingOut = false;
    targetHeight = y;
    targetSpeed = velocity.copy();
  }

  void fadeIn() {
    if (opacity < 255) {
      opacity += 2; // Gradually increase opacity
      opacity = constrain(opacity, 0, 255);
    }
  }

  void fadeOut() {
    if (opacity > 0) {
      opacity -= 2; // Gradually decrease opacity
      opacity = constrain(opacity, 0, 255);
    }
  }




  void setTarget(float x, float y) {
    target.set(x, y);
  }
  
  void setSpeed(float newSpeed) {
  maxSpeed = lerp(maxSpeed, newSpeed, 0.05);
}

void setSeparation(float sep) {
  separationFactor = sep;
}

void setCohesion(float coh) {
  cohesionFactor = coh;
}

  //void updateTargetHeight(float bowPos, Flower[] flowers) {
  //  int flowerIndex = -1; // Default to no valid flower

  //  // Map pitch to the correct flower index
  //  if (pitch == 1.0) { flowerIndex = 0; }
  //  else if (pitch == 2.0 ) { flowerIndex = 1; }
  //  else if (pitch == 3.0 ) { flowerIndex = 2; }
  //  else if (pitch == 4.0 ) { flowerIndex = 3; }

  //  // If a valid flower index was found, update the target position
  //  // If a valid flower index was found, move toward that flower
  //  if (flowerIndex >= 0 && flowerIndex < flowers.length) {
  //      target.set(flowers[flowerIndex].x, flowers[flowerIndex].y);
  //  }
  //}
  
  void updateTargetHeight(float pitchClass, Flower[] flowers) {
  int flowerIndex = round(pitchClass) - 1;

  if (flowerIndex < 0 || flowerIndex >= flowers.length) {
    return;
  }

  float audienceX = width * 0.5f;

  if (activeHorizontalClass == 1) {
    audienceX = width * 0.2f;
  } 
  else if (activeHorizontalClass == 3) {
    audienceX = width * 0.8f;
  }

  // The system slowly moves around the centre.
  float systemX =
    width * 0.5f +
    sin(frameCount * 0.006f) * width * 0.12f;

  // 1.0 = audience control; 0.0 = system control.
  float desiredX = lerp(
    systemX,
    audienceX,
    audienceHorizontalInfluence
  );

  float desiredY = flowers[flowerIndex].y;

  target.x = lerp(target.x, desiredX, 0.08f);
  target.y = lerp(target.y, desiredY, 0.08f);
}
void updateTargetSpeed(float smoothedSpeed) {
  float desiredSpeed =
    constrain(smoothedSpeed * 2.2f, 0.1f, 6.0f);

  maxSpeed =
    lerp(maxSpeed, desiredSpeed, 0.25f);

  maxForce =
    map(maxSpeed, 0.1f, 6.0f, 0.01f, 0.35f);
}



  void wander() {
    PVector wanderCenter = velocity.copy();
    wanderCenter.setMag(wanderDistance);

    PVector wanderOffset = PVector.random2D();
    //wanderOffset.mult(wanderRadius);
    float scaledRadius = map(maxSpeed, 0.5, 6.0, wanderRadius, 2);
    wanderOffset.mult(scaledRadius);


    PVector wanderTarget = PVector.add(wanderCenter, wanderOffset);
    seek(PVector.add(position, wanderTarget));
  }
  
    void seek(PVector target) {
    PVector desired = PVector.sub(target, position);
    float distance = desired.mag();
    desired.normalize();

    if (distance < 150) {
      float m = map(distance, 0, 150, maxSpeed * attractionStrength, maxSpeed);
      desired.mult(m);
    } else {
      desired.mult(maxSpeed*1);
    }

    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxForce);
    acceleration.add(steer);
  }
  
  void jitter() {
  PVector noiseOffset = PVector.random2D();
  noiseOffset.mult(random(0.5, 1.5));
  acceleration.add(noiseOffset);
}



  //void applyBehaviors() {
  //  //wander();
    
  //    if (erratic) {
  //  jitter(); // ✨ add subtle unpredictability
  //} else {
  //  wander(); // regular behavior
  //}

  //  seek(target);
  //  update();
  //  //may not need??
  //  position.x = constrain(position.x, 0, width);
  //  position.y = constrain(position.y, 0, height);
  //}

void applyBehaviors(ArrayList<Bee> bees) {
  if (erratic) {
    jitter(); // subtle random force
  } else {
    wander(); // normal behavior
  }

  separation(bees);  // ✨ NEW
  cohesion(bees);    // ✨ NEW
  seek(target);      // keep aiming at main target
  update();
  
  // Stay within screen
  position.x = constrain(position.x, 0, width);
  position.y = constrain(position.y, 0, height);
}

void separation(ArrayList<Bee> others) {
  float desiredSeparation = 50 * separationFactor;  // 25 pixels base

  PVector steer = new PVector(0, 0);
  int count = 0;

  for (Bee other : others) {
    float d = PVector.dist(position, other.position);
    if ((d > 0) && (d < desiredSeparation)) {
      PVector diff = PVector.sub(position, other.position);
      diff.normalize();
      diff.div(d);  // weight by distance
      steer.add(diff);
      count++;
    }
  }

  if (count > 0) {
    steer.div((float)count);
  }

  if (steer.mag() > 0) {
    steer.setMag(maxSpeed);
    steer.sub(velocity);
    steer.limit(maxForce * separationFactor);
    acceleration.add(steer);
  }
}

void cohesion(ArrayList<Bee> others) {
  float neighborDist = 50 * cohesionFactor;  // base 50 pixels

  PVector sum = new PVector(0, 0);
  int count = 0;
  
  for (Bee other : others) {
    float d = PVector.dist(position, other.position);
    if ((d > 0) && (d < neighborDist)) {
      sum.add(other.position);
      count++;
    }
  }

  if (count > 0) {
    sum.div((float)count);
    seek(sum);
  }
}


  void update() {
  acceleration.limit(maxForce); // ✨ added
  velocity.add(acceleration);
  velocity.limit(maxSpeed);
  position.add(velocity);
  acceleration.mult(0);

    // Wing flapping motion
    wingMovementR += wingSpeedR;
    if (wingMovementR < 3 || wingMovementR > 6) {
      wingSpeedR *= -1;
    }
    wingMovementL += wingSpeedL;
    if (wingMovementL < 3 || wingMovementL > 6) {
      wingSpeedL *= -1;
    }

    if (fadingOut) {
      fadeOut();
    } else {
      fadeIn();
    }

    
  }

  // Make sure your display method uses alpha correctly:
  void display() {
    //update();

    float theta = velocity.heading() + PI / 2;

    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    stroke(0, opacity);
    drawTentacles(0, 0);



    fill(250, 250, 10, opacity); // Yellow body
    drawBody(0, 0);

    fill(0, opacity); // Black head
    drawHead(0, 0);

    fill(0, opacity); // Transparent wings
    drawWings(0, 0);

    popMatrix();
  }

  void drawHead(float localX, float localY) {
    strokeWeight(2);
    circle(localX, localY, headWidth);
  }

  void drawTentacles(float localX, float localY) {
    noFill();
    strokeWeight(2);
    arc(localX + headWidth * 0.75, localY - headWidth / 2, headWidth, headWidth * 0.75, PI, PI + HALF_PI);
    arc(localX - headWidth * 0.75, localY - headWidth / 2, headWidth, headWidth * 0.75, PI + HALF_PI, TWO_PI);
  }

  void drawBody(float localX, float localY) {
    ellipse(localX, localY + headWidth * 1.8, headWidth * 1.7, headWidth * 2.7);
    strokeWeight(2);
  }

  void drawWings(float localX, float localY) {
    //// Left wing
    //pushMatrix();
    //translate(localX - headWidth * 0.8, localY + headWidth * 1.1); // Adjusted to move wings slightly down
    ////wingSpeedR = map(maxSpeed, 0.1, 6.0, 0.02, 0.3);

    //wingMovementR += wingSpeedR;
    //rotate(PI / wingMovementR);
    //if (wingMovementR < 3 || wingMovementR > 6) {
    //  wingSpeedR *= -1;
    //}


    //ellipse(0, 0, headWidth * 1.35, headWidth * 2.35);
    //popMatrix();

    //// Right wing
    //pushMatrix();
    //translate(localX + headWidth * 0.8, localY + headWidth * 1.1); // Adjusted to move wings slightly down
    ////wingSpeedL = map(maxSpeed, 0.1, 6.0, 0.02, 0.3);
    //wingMovementL += wingSpeedL;
    //rotate(-PI / wingMovementL);
    //if (wingMovementL < 3 || wingMovementL > 6) {
    //  wingSpeedL *= -1;
    //}


    //ellipse(0, 0, headWidth * 1.35, headWidth * 2.35);
    //popMatrix();
    
    // Left wing
pushMatrix();
translate(localX - headWidth * 0.8, localY + headWidth * 1.1);

float mappedWingSpeed = map(maxSpeed, 0.1, 6.0, 0.02, 0.3);
wingMovementR += mappedWingSpeed * wingDirR;

rotate(PI / wingMovementR);
if (wingMovementR < 3 || wingMovementR > 6) {
  wingDirR *= -1;  // flip direction, not magnitude
}

ellipse(0, 0, headWidth * 1.35, headWidth * 2.35);
popMatrix();

// Right wing
pushMatrix();
translate(localX + headWidth * 0.8, localY + headWidth * 1.1);

wingMovementL += mappedWingSpeed * wingDirL;
rotate(-PI / wingMovementL);
if (wingMovementL < 3 || wingMovementL > 6) {
  wingDirL *= -1;
}

ellipse(0, 0, headWidth * 1.35, headWidth * 2.35);
popMatrix();

  }
}
