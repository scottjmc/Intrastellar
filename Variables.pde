  
  import java.util.concurrent.ConcurrentLinkedQueue;

  
  PImage background_img;
  PImage planet_img;
  PImage base_img;
  PImage missile_img;
  
  SoundFile explosion;
  SoundFile small_explosion;
  SoundFile deep_boom;
  SoundFile slow_wave;
  SoundFile discharge;
  
  final static int WIDTH = 800;
  final static int HEIGHT = 600;
  final static int MISSILE_SIZE = 15;
  final static int SECOND = 60;
  final static int FIRE_RATE = 300;
  final static int POINTS_PER_METEOR = 10;
  final static int NUMBER_PLANETS = 2;

  static long SCORE;
  static int LEVEL;  
  static int MISSILES_LEFT;
  static long METEORS_TO_LEVEL;
    
  static int LAST_FIRE = 0;
  static int TEXT_TIMEOUT = 1200;
  static int MISSILE_SPEED = 10;
  static int METEORS_SPAWNED = 0;
  
  
  final static int HOME_RADIUS = 800;
  final static int HOME_DIAMETER = 1600;
  final static int HOME_OFFSET = 750;
  
  //POWER-UP VALUES
  final static int BONUS_MISSILES = 1;
  final static int BONUS_HEALTH = 2;
  final static int DESTROY_METEORS = 3;
  final static int SLOW_MO = 4;
  final static int SUPER_BULLETS = 5;
  
  
  final static float HEALTH_BAR_SIZE = 50;
  
  
  ConcurrentLinkedQueue<Meteor> meteors; 
  ConcurrentLinkedQueue<Missile> missiles;
  ConcurrentLinkedQueue<Planet> planets;
  
  
  static float getDistance(PVector v) {
    
    return sqrt((v.x*v.x) + (v.y*v.y));
  }