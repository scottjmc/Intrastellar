// a representation of a point mass
 class Meteor {
  
  // Vectors to hold pos, vel
  // I'm allowing public access to keep things snappy.
  public PVector position, velocity ;
  
  // Vector to accumulate forces prior to integration
  private PVector forceAccumulator ; 
  
  // damping factor to simulate drag, as per Millington
  // Disabled when using Drag Force Generator
  private static final float DAMPING = 0.998f ;
  
  // Store inverse mass to allow simulation of infinite mass
  private float invMass ;
  
  // If you do need the mass, here it is:
  public float getMass() {return 1/invMass ;}
  
  private boolean dead = false;
  
  public float fireSize = 2;
  public float explosionSize = 40;
  
  public int size;
  
  public boolean lucky;
  
  Meteor(int x, int y, float xVel, float yVel, float invM) {

    position = new PVector(x, y);
    velocity = new PVector(xVel, yVel);
    forceAccumulator = new PVector(0, 0);
    invMass = invM ;
    size = int(2*invM);
    
    if(roll(32)) lucky = true;
    if(powerUp == 4 && power_timeout>0) velocity.mult(0.5);
  }
  
  // Add a force to the accumulator
  void addForce(PVector force) {
    forceAccumulator.add(force) ;
  }
  
  // update position and velocity
  boolean integrate() {
    // If infinite mass, we don't integrate
    if (invMass <= 0f) return false;
    
    if(position.y > HEIGHT || position.y < 0) return true;
    
    // update position
    position.add(velocity) ;
    
    // NB If you have a constant acceleration (e.g. gravity) start with
    //    that then add the accumulated force / mass to that.
    PVector resultingAcceleration = forceAccumulator.get() ;
    resultingAcceleration.mult(invMass) ;
    
    // update velocity
    velocity.add(resultingAcceleration) ;
    // apply damping - disabled when Drag force present
    velocity.mult(DAMPING) ;
   
    if((position.y >= HEIGHT|| position.x < 0 || position.x > WIDTH || position.y <= 0) && !dead) {
      kill();
      SCORE += POINTS_PER_METEOR;
      MISSILES_LEFT+=2;
      if(lucky) powerUp();
    }
    
    // Clear accumulator
    forceAccumulator.x = 0 ;
    forceAccumulator.y = 0 ;
    
    return false;
  }
  
  public void kill() {dead=true;deep_boom.play();}
  public boolean isDead() {return dead;}
  
  @Override
  public String toString() {
    
    return "METEOR: (" + int(position.x) + ", " + int(position.y) + ")";
    
  }
}