// a representation of a large mass
final class Planet {
  
  // Vectors to hold pos, vel
  // I'm allowing public access to keep things snappy.
  public PVector position, shooter;
  
  // Store inverse mass to allow simulation of infinite mass
  private float invMass = 100;
  
  // If you do need the mass, here it is:
  public float getMass() {return 1/invMass ;}
  
  public float fireSize = 2;
  public float explosionSize;
  
  public boolean dead = false;
  private float diameter;
 
  public float maxHealth = 100; //Default to 100 health.
  public float health = maxHealth; //Start at full health.

  //Used for declaring smaller orbiting planets/moons.
  Planet(int x, int y, int diameter) {
    
    float shooterX = (x<(WIDTH/2))? (x+(diameter/3)):(x-(diameter/3));
    
    shooter = new PVector(shooterX,y);
    
    position = new PVector(x, y);
    this.diameter = diameter;
    explosionSize = 3*diameter;
  }
  
  //Used exclusively for declaring home planet.
  Planet(int x, int y, int width, int height, float invM) {
    
    shooter = new PVector(30,float(HEIGHT)/2);
    
    position = new PVector(x, y);
    this.diameter = 30;
    explosionSize = int(diameter);
    invMass = invM;
  }
 
  public void kill() {dead=true;}
  
  
  public PVector getGravity(Meteor meteor) {
    float distance = getDistance(new PVector(meteor.position.x-position.x, meteor.position.y-position.y));
    float fgrav = ((meteor.getMass() + getMass()) / (distance*distance));
    PVector gravity = new PVector(position.x*fgrav, position.y*fgrav);
    gravity.mult(-1);
    if(meteor.position.y-position.y < 0) gravity.y *= -1;
    return gravity;
  }
  
  public float getRadius() {
    return diameter/2;
  }
  
  public float getDiameter() {
    return diameter;
  }
  
  private void setHealth(int h) {
    
    maxHealth = h;
    health = h;
  }

  
  @Override
  public String toString() {
    return "PARTICLE: (" + int(position.x) + ", " + int(position.y) + ")";
    
  }
}