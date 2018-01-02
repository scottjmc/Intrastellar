  import java.util.concurrent.ConcurrentLinkedQueue;
  import java.util.Iterator;
  import processing.sound.*;

  static Iterator<Meteor> mtI; // Iterator for Meteors.
  static Iterator<Planet> plI; // Iterator for Planets.
  static Iterator<Missile> msI; // Iterator for Missiles.

  Planet home; // Large planet on far left.
  Planet planet1; //Arbitrary moon
  Planet planet2; //Abritrary moon

  double level_timeout; // Time to display new level
  double power_timeout; // Time allocated for a power-up.
  int powerUp; // Last power-up to be awarded.

  boolean start = false; // Ready to play game. Enabled on key-press.
  
  void setup() {
    
     size(800, 600); // These must be raw values.
     init();;
  }

  void draw() {
    background(background_img);

    fill(255);
    textSize(25);

    if (!start) {
      text("PRESS ANY KEY TO START", (WIDTH / 2) - 160, HEIGHT / 2);
      return;
    }

    if (home.health <= 0) {
      if(explosion!=null) explosion.play();
      if(slow_wave!=null) slow_wave.play();
      gameOver();
      explosion = null;
      slow_wave = null;
      start=false;
    }

    else {

      renderMissilesLeft();
      renderLevel();
      renderScore();
      renderCrosshairs();
      renderPlanets();
      renderMeteors();
      renderMissiles();
      renderPowerUp();
      
      if (level_timeout <= 0) spawnMeteors(); //Spawn meteors after a short break at the end of a level.
      
      image(base_img, -100, 0, 150, 600); // Image of the main planet/base (far left).
      fill(255, 255, 255, 100); //Fill white, 100/255 opacity.

      if(SCORE < 0) SCORE=0; 
      if (mousePressed) fire(mouseX, mouseY);
    }
  }

  void keyPressed() {
    start = true;
    if(slow_wave == null) slow_wave = new SoundFile(this, "Slow_Wave.wav");
    slow_wave.play();
  }
  
  void init() {
    
    SCORE = 0;
    LEVEL = 1;
    MISSILES_LEFT = 50;
    METEORS_TO_LEVEL = 5;
    METEORS_SPAWNED = 0;
    
    meteors = new ConcurrentLinkedQueue<Meteor>();
    planets = new ConcurrentLinkedQueue<Planet>();
    missiles = new ConcurrentLinkedQueue<Missile>();

    background_img = loadImage("Intrastellar_bg.jpg"); // Define background image.
    planet_img = loadImage("Intrastellar_planet.png"); // Define planet overlay image.
    base_img = loadImage("Intrastellar_base.png"); // Define the overlay image for the base (far left).
    missile_img = loadImage("Intrastellar_missile.png"); //Define the overlay image for the missiles.

    home = new Planet(0-HOME_OFFSET, HEIGHT/2, HOME_RADIUS, HOME_DIAMETER, 200); //Intialise the home planet.
    home.setHealth(200); //Set default max health to double normal.
    
    explosion = new SoundFile(this, "Explosion.wav");
    small_explosion = new SoundFile(this, "Small_Explosion.wav");
    slow_wave = new SoundFile(this, "Slow_Wave.wav");
    discharge = new SoundFile(this, "Discharge.wav");
    deep_boom = new SoundFile(this, "Deep_Boom.wav");

    planet1 = new Planet(WIDTH / 3, 200, 80);
    planet2 = new Planet(WIDTH / 4, 400, 100);

    planets.add(planet1);
    planets.add(planet2);

    mtI = meteors.iterator();
    plI = planets.iterator();
    msI = missiles.iterator();
  }

  // Kill the planet and the meteor if they collide.
  private void handlePlanetCollisions(Meteor m) {
    if (m.position.x < 30 && !m.dead) {
      home.health -= m.size + (m.size * (1 - (1 / LEVEL)));
      m.kill();
      SCORE-= 2*POINTS_PER_METEOR;
      return;
    }
    while (plI.hasNext()) {
      Planet planet = plI.next();
      m.addForce(home.getGravity(m));
      m.addForce(planet.getGravity(m));
      if (collision(m, planet)) {
        m.kill();
        SCORE-=2*POINTS_PER_METEOR;
        planet.health -= 2 * m.size;
        if (planet.health <= 0)
          planet.kill();
          SCORE-= 10*POINTS_PER_METEOR;
          deep_boom.play();
          deep_boom.play();
      }
    }
    // Reset iterator after use.
    plI = planets.iterator();
  }

  // Kill the missile and meteor if they collide.
  private void handleMissileCollisions(Meteor m) {
    while (msI.hasNext()) {
      Missile missile = msI.next();
      if (collision(m, missile)) {
        if(m.lucky) powerUp();
        m.kill();
        missile.kill();
        MISSILES_LEFT+=2;
        SCORE+=POINTS_PER_METEOR;
      }

      if(missile.dead) {

        PVector force = missile.getGravity(m);
        if(superBullets()) force.mult(-1);
        else force.mult(-0.1);

        m.addForce(force);
      }
    }
    //Reset iterator after use.
    msI = missiles.iterator();
  }

  // Random number generator with 10% probability of returning true.
  boolean roll() {
    // Random roll with odds 1/10
    return (random(0, 1) < 0.1) ? true : false;
  }

  // Random number generator with probability of returning true equal to 1/odds.
  boolean roll(float odds) {
    if(odds<=0) odds=1;
    // Random roll with defined odds
    return (random(0, 1) < (1 / odds)) ? true : false;
  }

  // Create a bullet and calculate its direction.
  void fire(float x, float y) {

      if (LAST_FIRE+FIRE_RATE > millis()) return;
      if(MISSILES_LEFT <=0) return;
      LAST_FIRE = millis();
      MISSILES_LEFT--;

      if(home.dead) return;

      discharge.play();
      PVector path = new PVector(x-home.shooter.x, y-home.shooter.y);
      path.normalize().mult(MISSILE_SPEED);
      missiles.add(new Missile(int(home.shooter.x), int(home.shooter.y), path.x, path.y, 1f, new PVector(x,y)));
    }

  void spawnMeteors() {
      //Spawn meteors at probability 1/150 once every frame.
      if(roll(100-(LEVEL*2)) && METEORS_SPAWNED<METEORS_TO_LEVEL) {
        meteors.add(new Meteor(WIDTH, int(random(0,HEIGHT)), random(-3.5,-2.5), random(-0.5,0.5), random(7,16)));
        METEORS_SPAWNED++;
      }
      else if(meteors.size() == 0 && METEORS_SPAWNED>=METEORS_TO_LEVEL) {
        levelUp();
        meteors.add(new Meteor(WIDTH, int(random(0,HEIGHT)), random(-3,-1), random(-0.5,0.5), random(7,16)));
        METEORS_SPAWNED++;
      }
    }

  void levelUp() {

    LEVEL++; //Next level.
    METEORS_TO_LEVEL *= 1.2; //Increase the number of meteors required to complete the level.
    METEORS_SPAWNED = 0; //Reset the number of meteors spawned this wave.
    level_timeout = 1 * SECOND; //Have a short break before spawning again.
    SCORE += (10*LEVEL) + (planets.size()*10); //Give bonus score for completing levels with planets left.
    giveHealth(POINTS_PER_METEOR); //Abitrarily give health to remaining planets.
    
    //Every 10 levels regenerate a planet.
    if(LEVEL%10==0) {
      if(planets.size() < NUMBER_PLANETS) {
        if(!planets.contains(planet1)) regenPlanet(planet1);
        else if(!planets.contains(planet2)) regenPlanet(planet2);
        else println("CAN'T FIND MISSING PLANETS?");
        //If adding more planets, iterate through planets and find missing one.
        //Possible optimisation: record missing planets in a variable/variables.
      } else {
        while(plI.hasNext()) {
          Planet p = plI.next();
          p.health = p.maxHealth;
        }
        plI = planets.iterator();
      }
    }
    
    slow_wave.play();
  }

  void gameOver() {

    home.kill();
    fill(255);
    textSize(75);
    if(start) init();
  }
  
  void regenPlanet(Planet p) {
    p.health=p.maxHealth;
    p.dead=false;
    p.fireSize=2;
    planets.add(p);
  }
  
  


  /* COLLISION METHODS */
  

  // Detect collisions between meteors and missiles.
  boolean collision(Meteor mt, Missile ms) {
    if (ms.dead || mt.dead)
      return false;
    return ((abs(ms.position.x - mt.position.x) < MISSILE_SIZE + (mt.size / 2))
        && (abs(ms.position.y - mt.position.y) < MISSILE_SIZE + (mt.size / 2))) ? true : false;
  }

  // Detect collisions between meteors and planets.
  boolean collision(Meteor mt, Planet pl) {
    if (pl.dead || mt.dead)
      return false;
    if (mt.position.x <= 30)
      return true;
    return ((abs(mt.position.x - pl.position.x) < (mt.size + (pl.getRadius())) * 0.9)
        && (abs(mt.position.y - pl.position.y) < (mt.size + (pl.getRadius())) * 0.9)) ? true : false;
  }
  
  
  
  

  /* POWER-UP METHODS */

  void powerUp() {
    powerUp = (int) random(1, 6);
    power_timeout = 10 * SECOND;
    switch (powerUp) {
    case BONUS_MISSILES:
      giveMissiles();
      break;
    case BONUS_HEALTH:
      giveHealth();
      break;
    case DESTROY_METEORS:
      destroyMeteors();
      break;
    case SLOW_MO:
      slowMo();
      break;
    case SUPER_BULLETS:
      power_timeout = 15 * SECOND;
      break;
    }
  }

  private void giveMissiles() {
    MISSILES_LEFT += 10;
  }

  private void slowMo() {
    while (mtI.hasNext()) {
      Meteor m = mtI.next();
      m.velocity.mult(0.5);
    }
    mtI = meteors.iterator();
  }

  private void destroyMeteors() {
    mtI = meteors.iterator();
    while (mtI.hasNext()) {
      Meteor m = mtI.next();
      SCORE += POINTS_PER_METEOR*meteors.size();
      m.kill();
    }
    mtI = meteors.iterator();
  }

  private void giveHealth() {
    while (plI.hasNext()) {
      Planet p = plI.next();
      p.health += (0.3 * p.maxHealth);
      if (p.health > p.maxHealth)
        p.health = p.maxHealth;
    }
    plI = planets.iterator();
  }
  
  private void giveHealth(int h) {
    while (plI.hasNext()) {
      Planet p = plI.next();
      p.health += h;
      if (p.health > p.maxHealth)
        p.health = p.maxHealth;
    }
    plI = planets.iterator();
  }

  public boolean superBullets() {
    return (powerUp == SUPER_BULLETS && power_timeout > 0) ? true : false;
  }







  /* RENDERING METHODS */
  
  

  void renderMissiles() {

    while (msI.hasNext()) {

      Missile missile = msI.next();
      missile.integrate();

      if (missile.dead) {
        if (missile.fireSize >= missile.explosionSize) {
          msI.remove();
          msI = missiles.iterator();
          return;
        }
        fill(150, 220, 255);
        stroke(150, 220, 255);
        if (superBullets())
          ellipse(missile.position.x, missile.position.y, missile.fireSize * 5, missile.fireSize * 5);
        else
          ellipse(missile.position.x, missile.position.y, missile.fireSize, missile.fireSize);
        missile.fireSize += 2; // Increase size of exploision radius every frame.
      } else {

        if (missile.launchSize <= Missile.MAX_LAUNCH_SIZE && !(missile.launchSize <= 0)) {
          missile.launchSize--;
          stroke(255, 255, 255, 150);
          fill(255, 255, 255, 200);
          ellipse(home.shooter.x, home.shooter.y, missile.launchSize / 1.5, missile.launchSize);
        }
        image(missile_img, (missile.position.x - MISSILE_SIZE / 2), (missile.position.y - MISSILE_SIZE / 2),
            MISSILE_SIZE, MISSILE_SIZE);
      }
    }
    // Reset iterator after use.
    msI = missiles.iterator();
  }

  void renderLevel() {
    fill(255);
    if (level_timeout > 0) {
      double invTimeout = 1 - (1 / level_timeout);
      textSize((float) (25 + (invTimeout * 25)));
      text("LEVEL: " + LEVEL, (float) (150 + (150 * invTimeout)), (float) (25 + (5 * 25 * invTimeout)));
    } else {
      textSize(25);
      if(LEVEL%10==0) text("LEVEL: " + LEVEL + "\nPLANET REGEN!", 150, 25);
      else text("LEVEL: " + LEVEL, 150, 25);
    }
    level_timeout--;
  }

  void renderPowerUp() {
    if(power_timeout <= 0) return;
    if (power_timeout > 0) {
      textSize(20);
      fill(0, 255, 0);
      switch (powerUp) {
      case BONUS_MISSILES:
        text("POWER UP: +10 MISSILES!", WIDTH/3, HEIGHT/6);
        break;
      case BONUS_HEALTH:
        text("POWER UP: +30% HEALTH!", WIDTH/3, HEIGHT/6);
        break;
      case DESTROY_METEORS:
        text("POWER UP: DESTROY ALL METEORS!", WIDTH/3, HEIGHT/6);
        break;
      case SLOW_MO:
        text("POWER UP: SLOW-MO!", WIDTH/3, HEIGHT/6);
        break;
      case SUPER_BULLETS:
        text("POWER UP: SUPER BULLETS!", WIDTH/3, HEIGHT/6);
        break;
      }
      power_timeout--;
    }
  }

  // Render planets and/or explosions if dead.
  private void renderPlanets() {
    renderHealth(home);
    while (plI.hasNext()) {
      Planet p = plI.next();
      if (!p.dead) {
        renderHealth(p);
        image(planet_img, p.position.x-p.getRadius(), p.position.y-p.getRadius(), p.getDiameter(),p.getDiameter());
      } else {
        if (p.fireSize >= p.explosionSize) {
          plI.remove();
          plI = planets.iterator();
          return;
        }
        if(roll(2) && explosion!=null) explosion.play();
        noStroke();
        fill(int(random(0,255)), int(random(0,255)), int(random(0,255)), (255*(p.explosionSize-p.fireSize)));
        ellipse(p.position.x, p.position.y, p.fireSize/3, p.fireSize);
        ellipse(p.position.x, p.position.y, p.fireSize, p.fireSize/3);
        p.fireSize*=1.15; // Increase size of exploision radius every frame.
      }
    }
    //Reset iterator after use.
    plI = planets.iterator();
  }
  
  
   // Render meteors and handle their collisions with planets and missiles.
  void renderMeteors() {
    
    while (mtI.hasNext()) {
      Meteor meteor = mtI.next();
      meteor.integrate();
      handlePlanetCollisions(meteor);
      handleMissileCollisions(meteor);
      // Fire colours. Relevant whether rendering outer ring or explosion.
      fill(255, 175, 0);
      stroke(255, 195, 0);
      if(meteor.lucky) {
        fill(0, 255, 0);
        stroke(50, 255, 50);
      }
      if (!meteor.dead) {
        // Ellipse for outer fiery ring.
        ellipse(meteor.position.x + 3, meteor.position.y, meteor.size + 2, meteor.size - 1);
        // Inner meteor texture
        fill(0, 0, 0);
        if(meteor.lucky) stroke(50,255,50);
        else stroke(255, 150, 0);
        ellipse(meteor.position.x, meteor.position.y, meteor.size, meteor.size);
      } else {
        // If the explosion has hit its max size or is off-screen, null the object.
        if (meteor.fireSize >= meteor.explosionSize || meteor.position.x < 0) {
          mtI.remove();
          mtI = meteors.iterator();
          return;
        }
        // Otherwise render the explosion.
        stroke(int(random(75,255)), int(random(0,150)), 0);
        fill(int(random(100,255)), int(random(0,150)), 0);
        if(meteor.lucky) {
          stroke(0, 255, 0);
          fill(50, 255, 50);
        }
        ellipse(meteor.position.x, meteor.position.y, meteor.fireSize, meteor.fireSize);
        meteor.fireSize*=1.15; // Increase size of exploision radius every frame.
      }
    }
    //Reset iterator after use.
    mtI = meteors.iterator();
  }
  
  
  private void renderHealth(Planet pl) {

    if (pl.health < (pl.maxHealth / 3))
      fill(255, 0, 0);
    else if (pl.health < (pl.maxHealth / 1.5))
      fill(255, 200, 0);
    else
      fill(0, 255, 0);
    stroke(255);
    float barWidth = (pl.health / pl.maxHealth) * HEALTH_BAR_SIZE;
    if (pl == home)
      rect(10, 10, barWidth * 2, 10, 5);
    rect((pl.position.x - (barWidth / 2)), (pl.position.y - (pl.getDiameter())), barWidth, 10, 5);
  }
  
  private void renderScore() {
    
    fill(255);
    textSize(25);
    text("SCORE: " + SCORE, 550, 25);
  }

  private void renderMissilesLeft() {
    if (MISSILES_LEFT < 10)
        fill(200, 200, 0);
      if (MISSILES_LEFT < 5)
        fill(255, 0, 0);
      if (MISSILES_LEFT <= 0) {
        fill(150, 0, 0);
        if (roll(100))
          MISSILES_LEFT++;
        text("(REGENERATING): " + MISSILES_LEFT, 300, 25);
      } else text("MISSILES: " + MISSILES_LEFT, 300, 25);
  }
  
  private void renderCrosshairs() {
      stroke(200, 200, 200);
      line(mouseX - 5, mouseY, mouseX + 5, mouseY);
      line(mouseX, mouseY - 5, mouseX, mouseY + 5);
  }
  