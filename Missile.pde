// a representation of a point mass
final class Missile {
  
  // Vectors to hold pos, vel
  // I'm allowing public access to keep things snappy.
  public PVector position, velocity, explosion;
  
  // Vector to accumulate forces prior to integration
  private PVector forceAccumulator ; 
  
  // Store inverse mass to allow simulation of infinite mass
  private float invMass = 1;
  
  // If you do need the mass, here it is:
  public float getMass() {return 1/invMass ;}
  
  public boolean dead = false;
  
  public int explosionSize = MISSILE_SIZE;
  public int fireSize = 2;
  
  public static final int MAX_LAUNCH_SIZE = 2*MISSILE_SIZE;
  public int launchSize = 2*MISSILE_SIZE;
  
  
  Missile(int x, int y, float xVel, float yVel, float invM, PVector explosion) {

    position = new PVector(x, y);
    velocity = new PVector(xVel, yVel);
    forceAccumulator = new PVector(0, 0);
    invMass = invM ;
    this.explosion = explosion;
  }
  
  // Add a force to the accumulator
  void addForce(PVector force) {
    forceAccumulator.add(force) ;
  }
  
  /* Update position and velocity
  *  Returns false if the bullet is to be rendered.
  *  Returns true if the bullet has left the screen.
  */
  boolean integrate() {
    // If infinite mass, we don't integrate
    if (invMass <= 0f) return false;
    if(position.x>WIDTH||position.x<0||position.y<0) return true;
    
    // update position
    position.add(velocity) ;
    
    // NB If you have a constant acceleration (e.g. gravity) start with
    //    that then add the accumulated force / mass to that.
    PVector resultingAcceleration = forceAccumulator.get() ;
    resultingAcceleration.mult(invMass) ;
    
    // update velocity
    velocity.add(resultingAcceleration) ;
    
    if(abs(position.x-explosion.x) < 10 && abs(position.y-explosion.y) < 10) kill();
    if(position.x > WIDTH || position.x <= 0|| position.y >= HEIGHT || position.y <= 0) kill();

    // Clear accumulator
    forceAccumulator.x = 0 ;
    forceAccumulator.y = 0 ; 
    return false;
  }
  
  //This method is only used to get inverse gravity as a pushing force for explosions.
  public PVector getGravity(Meteor meteor) {
    float distance = getDistance(new PVector(meteor.position.x-position.x, meteor.position.y-position.y));
    float fgrav = ((meteor.getMass() + getMass()) / (distance*distance));
    PVector gravity = new PVector(position.x*fgrav, position.y*fgrav);
    gravity.mult(-1);
    if(meteor.position.y-position.y < 0) gravity.y *= -1;
    return gravity;
  }
  
  public void kill() {dead=true;velocity.mult(0);small_explosion.play();}
}