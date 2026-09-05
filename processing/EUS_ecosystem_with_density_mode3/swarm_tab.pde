

class Swarm {
  ArrayList<Bee> bees;
  ArrayList<Float> speedHistory;  //a list that stores all recent bSpeed values
  int maxHistorySize = 50; //number of frames used for smoothing
  boolean erraticMode = false;

  Swarm() {
    bees = new ArrayList<Bee>();
    speedHistory = new ArrayList<Float>();
    for (int i = 0; i < 25; i++) {
      bees.add(new Bee(random(width), random(height), 1.0));
    }
  }

  void updateHeights(float pitch, Flower[] flower) {
    for (Bee b : bees) {
      b.updateTargetHeight(pitch, flower);
    }
  }

  void updateSpeed(float bSpeed) {
    speedHistory.add(bSpeed); // Add new speed

    // Keep only the last `maxHistorySize` values
    if (speedHistory.size() > maxHistorySize) {
      speedHistory.remove(0);
    }

    float smoothedSpeed = getSmoothedSpeed(); // Compute the average speed

    // Update each bee with the smoothed speed
    for (Bee b : bees) {
      b.updateTargetSpeed(smoothedSpeed);
    }
  }

  float getSmoothedSpeed() {
    float sum = 0;

    for (float speed : speedHistory) {
      sum += speed; // Add each speed to the sum
    }

    return sum / speedHistory.size(); // Get the average
  }

  void updateSwarmSize(int numBees) {

    int currentSize = bees.size();

    if (numBees > currentSize) {
      for (int i = currentSize; i < numBees; i += detailLevel) {
        bees.add(new Bee(random(width), random(height), 1.0));
      }
    } else if (numBees < currentSize) {
      for (int i = currentSize -1; i >= numBees; i--) {
        //bees.remove(i);
        bees.get(i).fadingOut = true;
      }
    }
  }

  void setErratic(boolean e) {
    erraticMode = e;
  }

  //void applyBehaviors() {

  //  for (int i = bees.size() - 1; i >= 0; i--) {
  //    Bee b = bees.get(i);
      
  //    b.erratic = erraticMode;
      
  //    if (b.fadingOut && b.opacity <= 0) {
  //      bees.remove(i); // Remove only after fading is complete
  //    } else {
  //      b.applyBehaviors();
  //    }
  //  }
  //}

void applyBehaviors() {
  for (int i = bees.size() - 1; i >= 0; i--) {
    Bee b = bees.get(i);
    b.erratic = erraticMode;
    
    if (b.fadingOut && b.opacity <= 0) {
      bees.remove(i);
    } else {
      b.applyBehaviors(bees);  // ✅ Pass the bees list to each Bee
    }
  }
}

void setSwarmSocial(float separation, float cohesion) {
  for (Bee b : bees) {
    b.setSeparation(separation);
    b.setCohesion(cohesion);
  }
}

  void display() {
    ArrayList<Bee> currentBees = new ArrayList<Bee>(bees);
    for (Bee b : currentBees) {
      b.display();
    }
  }
  
  void setMood(int mood, Flower[] flowerTargets) {
  for (Bee b : bees) {
    switch (mood) {
      case 1:  // calm
        b.setTarget(flowerTargets[1].home.x, flowerTargets[1].home.y);
        b.setSeparation(0.5);
        b.setCohesion(1.2);
        b.setSpeed(1.0);
        break;

      case 2:  // focused
        int randFlower = int(random(flowerTargets.length));
        b.setTarget(flowerTargets[randFlower].home.x, flowerTargets[randFlower].home.y);
        b.setSeparation(1.0);
        b.setCohesion(0.8);
        b.setSpeed(2.5);
        break;

      case 3:  // chaotic
        b.setTarget(random(width), random(height));
        b.setSeparation(2.0);
        b.setCohesion(0.3);
        b.setSpeed(5.0);
        break;
    }
  }
}

}
