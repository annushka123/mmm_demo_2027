class Flowers {

  class SimpleFlower {
    float x, y;
    int baseColor;
    float size;
    float alpha;
    float targetAlpha;
    float fadeSpeed;
    float sizeOffset = 0;


    SimpleFlower(float x, float y) {
      this.x = x;
      this.y = y;
      this.size = random(10, 30);
      this.baseColor = color(random(100, 255), random(100, 250), random(100, 255), random(100, 255) );
      this.alpha = 0;
      this.targetAlpha = 255;
      this.fadeSpeed = 3;
    }

    void update() {
      if (alpha < targetAlpha) {
        alpha = min(alpha + fadeSpeed, targetAlpha);
      } else if (alpha > targetAlpha) {
        alpha = max(alpha - fadeSpeed, targetAlpha);
      }

      // ✨ Add jittery size offset in sparkle mode
      if (flowerSparkle) {
        sizeOffset = random(-7.5, 7.5);  // subtle sparkle pulse
      } else {
        sizeOffset = 0;
      }
    }


    void display() {
      update();
      if (alpha <= 0) return;

      pushMatrix();
      translate(x, y);
      noStroke();
      //stroke(0, alpha);
      //strokeWeight(1);
      //fill(baseColor, alpha);
      if (flowerSparkle) {
        // Sparkly mode!
        float r = red(baseColor) + random(-10, 10);
        float g = green(baseColor) + random(-10, 10);
        float b = blue(baseColor) + random(-10, 10);
        float a = alpha + random(-30, 30);

        r = constrain(r, 0, 255);
        g = constrain(g, 0, 255);
        b = constrain(b, 0, 255);
        a = constrain(a, 0, 255);

        fill(r, g, b, a);
        noStroke();
        //stroke(255, random(20, 80));
      } else {
        // Normal mode
        //flowerSparkle = true;

        fill(baseColor, alpha);
        noStroke();
      }

      int petals = 6;
      float angleStep = TWO_PI / petals;

      for (int i = 0; i < petals; i++) {
        float angle = i * angleStep;
        float px = cos(angle) * size;
        float py = sin(angle) * size;
        ellipse(px, py, size * 0.6, size * 1.0);
      }

      popMatrix();
    }

    boolean isFadingOut() {
      return targetAlpha == 0;
    }

    boolean isFullyInvisible() {
      return targetAlpha == 0 && alpha <= 0;
    }

    void fadeOut() {
      targetAlpha = 0;
    }
  }

  ArrayList<SimpleFlower> flowers;

  Flowers() {
    flowers = new ArrayList<SimpleFlower>();
  }

  int currentTarget = 0;

  void updateFlowerCount(int targetCount) {
    // only do anything if the number has changed
    if (targetCount == currentTarget) return;
    currentTarget = targetCount;

    int visibleCount = countVisible();

    // Add only the difference
    if (targetCount > visibleCount) {
      for (int i = 0; i < targetCount - visibleCount; i++) {
        flowers.add(new SimpleFlower(random(width), random(height)));
      }
    } else {
      int toFade = visibleCount - targetCount;
      for (SimpleFlower f : flowers) {
        if (toFade <= 0) break;
        if (!f.isFadingOut()) {
          f.fadeOut();
          toFade--;
        }
      }
    }

    // Remove only fully faded flowers
    flowers.removeIf(f -> f.isFullyInvisible());
  }


  int countVisible() {
    int count = 0;
    for (SimpleFlower f : flowers) {
      if (!f.isFadingOut()) count++;
    }
    return count;
  }

  void display() {
    // Make a shallow copy of the list to safely iterate
    ArrayList<SimpleFlower> copy = new ArrayList<SimpleFlower>(flowers);
    for (SimpleFlower f : copy) {
      f.display();
    }
  }
}
