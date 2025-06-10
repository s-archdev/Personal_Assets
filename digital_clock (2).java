// Organic Digital Clock with Shaders and Physics
PShader organicShader;
PGraphics clockLayer;
ArrayList<Particle> particles;
float time = 0;
String currentTime = "";
String previousTime = "";
boolean transitioning = false;
float transitionTime = 0;

void setup() {
  size(800, 600, P3D);
  
  // Create shader for organic effects
  organicShader = createShader(vertexShaderSource(), fragmentShaderSource());
  clockLayer = createGraphics(width, height, P3D);
  
  // Initialize particle system
  particles = new ArrayList<Particle>();
  for (int i = 0; i < 200; i++) {
    particles.add(new Particle());
  }
  
  textAlign(CENTER, CENTER);
}

void draw() {
  time += 0.02;
  
  // Update time
  updateTime();
  
  // Clear and prepare for rendering
  background(5, 10, 20);
  
  // Draw organic background with particles
  drawOrganicBackground();
  
  // Draw the clock with shader effects
  drawOrganicClock();
  
  // Update particles
  updateParticles();
}

void updateTime() {
  String newTime = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  
  if (!newTime.equals(currentTime)) {
    previousTime = currentTime;
    currentTime = newTime;
    transitioning = true;
    transitionTime = 0;
    
    // Spawn particles on time change
    spawnTransitionParticles();
  }
  
  if (transitioning) {
    transitionTime += 0.05;
    if (transitionTime >= 1.0) {
      transitioning = false;
    }
  }
}

void drawOrganicBackground() {
  // Create neon-style flowing background
  loadPixels();
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      float n = noise(x * 0.008, y * 0.008, time * 0.3);
      
      // Random neon background colors
      colorMode(HSB, 360, 100, 100);
      float bgHue = (n * 360 + time * 50) % 360;
      float[] neonBgHues = {180, 300, 60, 120, 270, 30};
      int bgIndex = (int)(n * neonBgHues.length);
      float neonBgHue = neonBgHues[bgIndex];
      
      color neonBg = color(neonBgHue, 60 + n * 40, 15 + n * 25);
      pixels[y * width + x] = neonBg;
    }
  }
  updatePixels();
  colorMode(RGB, 255);
}

void drawOrganicClock() {
  pushMatrix();
  translate(width/2, height/2);
  
  // Apply organic pulsing scale
  float pulseScale = 1.0 + sin(time * 2) * 0.1;
  scale(pulseScale);
  
  // Draw main time with organic distortion
  textSize(80);
  
  for (int i = 0; i < currentTime.length(); i++) {
    char c = currentTime.charAt(i);
    
    pushMatrix();
    
    // Position each character
    float charX = (i - currentTime.length()/2.0 + 0.5) * 60;
    translate(charX, 0);
    
    // Add organic movement to each character
    float offsetX = sin(time * 3 + i) * 8;
    float offsetY = cos(time * 2 + i * 0.5) * 6;
    translate(offsetX, offsetY);
    
    // Rotation based on noise
    float rotation = noise(i, time * 0.5) * 0.3 - 0.15;
    rotate(rotation);
    
    // Random neon color shifts
    colorMode(HSB, 360, 100, 100);
    float randomHue = (noise(i * 10, time * 0.3) * 360) % 360;
    
    // Limit to neon colors: cyan, magenta, yellow, green, purple, orange
    float[] neonHues = {180, 300, 60, 120, 270, 30}; // Cyan, Magenta, Yellow, Green, Purple, Orange
    int neonIndex = (int)(noise(i * 5, time * 0.2) * neonHues.length);
    float baseHue = neonHues[neonIndex];
    
    // Add some variation around the base neon color
    float finalHue = baseHue + (noise(time * 0.4 + i) - 0.5) * 40;
    
    // Bright neon saturation and brightness
    float saturation = 90 + noise(time * 0.5 + i) * 10;
    float brightness = 85 + noise(time * 0.3 + i * 2) * 15;
    
    // Multi-layer neon glow effect
    for (int glow = 5; glow > 0; glow--) {
      float glowSat = saturation - glow * 10;
      float glowBright = brightness - glow * 5;
      float glowAlpha = 30 + glow * 10;
      fill(finalHue, max(glowSat, 30), max(glowBright, 50), glowAlpha);
      textSize(80 + glow * 6);
      text(c, 0, 0);
    }
    
    // Main neon character - super bright
    fill(finalHue, saturation, 100, 255);
    textSize(80);
    text(c, 0, 0);
    
    // Add electric spark effect
    if (random(100) < 5) { // 5% chance per frame
      fill(255, 255, 255, 200); // White spark
      textSize(82);
      text(c, random(-2, 2), random(-2, 2));
    }
    
    popMatrix();
  }
  
  // Draw date with neon flowing effect
  pushMatrix();
  translate(0, 100);
  String dateString = nf(day(), 2) + "/" + nf(month(), 2) + "/" + year();
  textSize(24);
  
  for (int i = 0; i < dateString.length(); i++) {
    char c = dateString.charAt(i);
    float charX = (i - dateString.length()/2.0 + 0.5) * 18;
    float waveY = sin(time * 4 + i * 0.8) * 8;
    
    colorMode(HSB, 360, 100, 100);
    
    // Random neon colors for date
    float[] dateNeonHues = {180, 300, 60, 120, 270, 30};
    int dateIndex = (int)(noise(i * 3, time * 0.15) * dateNeonHues.length);
    float dateHue = dateNeonHues[dateIndex];
    
    // Date glow effect
    for (int glow = 2; glow > 0; glow--) {
      fill(dateHue, 80, 70, 40);
      textSize(24 + glow * 3);
      text(c, charX, waveY);
    }
    
    // Main date text
    fill(dateHue, 90, 95);
    textSize(24);
    text(c, charX, waveY);
  }
  popMatrix();
  
  popMatrix();
  colorMode(RGB, 255);
}

void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    
    if (p.isDead()) {
      particles.remove(i);
    }
  }
}

void spawnTransitionParticles() {
  for (int i = 0; i < 50; i++) {
    particles.add(new Particle(width/2, height/2, true));
  }
}

class Particle {
  PVector pos, vel, acc;
  float life, maxLife;
  color col;
  boolean isTransition;
  
  Particle() {
    pos = new PVector(random(width), random(height));
    vel = new PVector(random(-1, 1), random(-1, 1));
    acc = new PVector(0, 0);
    life = maxLife = random(100, 300);
    
    // Random neon colors for ambient particles
    colorMode(HSB, 360, 100, 100);
    float[] ambientNeonHues = {180, 300, 60, 120, 270, 30};
    int ambientIndex = (int)(random(ambientNeonHues.length));
    float ambientHue = ambientNeonHues[ambientIndex];
    col = color(ambientHue, 70, 80, 120);
    colorMode(RGB, 255);
    isTransition = false;
  }
  
  Particle(float x, float y, boolean transition) {
    pos = new PVector(x, y);
    vel = PVector.random2D();
    vel.mult(random(2, 8));
    acc = new PVector(0, 0);
    life = maxLife = random(60, 120);
    
    // Random neon colors for particles
    colorMode(HSB, 360, 100, 100);
    float[] particleNeonHues = {180, 300, 60, 120, 270, 30};
    int particleIndex = (int)(random(particleNeonHues.length));
    float particleHue = particleNeonHues[particleIndex];
    col = color(particleHue, 85, 95, 180);
    colorMode(RGB, 255);
    isTransition = transition;
  }
  
  void update() {
    // Physics
    vel.add(acc);
    pos.add(vel);
    vel.mult(0.98); // Damping
    
    // Organic forces
    float noiseForce = noise(pos.x * 0.01, pos.y * 0.01, time);
    acc.x = cos(noiseForce * TWO_PI) * 0.1;
    acc.y = sin(noiseForce * TWO_PI) * 0.1;
    
    life--;
    
    // Wrap around screen
    if (pos.x < 0) pos.x = width;
    if (pos.x > width) pos.x = 0;
    if (pos.y < 0) pos.y = height;
    if (pos.y > height) pos.y = 0;
  }
  
  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    
    float alpha = map(life, 0, maxLife, 0, 100);
    fill(red(col), green(col), blue(col), alpha);
    noStroke();
    
    float size = map(life, 0, maxLife, 1, 6);
    if (isTransition) size *= 2;
    
    ellipse(0, 0, size, size);
    popMatrix();
  }
  
  boolean isDead() {
    return life <= 0;
  }
}

// Vertex shader source
String vertexShaderSource() {
  return """
#ifdef GL_ES
precision mediump float;
#endif

attribute vec4 position;
attribute vec2 texCoord;

varying vec2 vTexCoord;

void main() {
  vTexCoord = texCoord;
  gl_Position = position;
}
""";
}

// Fragment shader source  
String fragmentShaderSource() {
  return """
#ifdef GL_ES
precision mediump float;
#endif

varying vec2 vTexCoord;
uniform float time;

void main() {
  vec2 uv = vTexCoord;
  
  // Create organic distortion
  float distortion = sin(uv.x * 10.0 + time) * 0.01;
  distortion += cos(uv.y * 8.0 + time * 0.7) * 0.01;
  
  uv += distortion;
  
  // Organic color shifting
  vec3 color = vec3(
    0.5 + 0.5 * sin(time + uv.x * 3.0),
    0.5 + 0.5 * sin(time + uv.y * 3.0 + 2.0),
    0.5 + 0.5 * sin(time + (uv.x + uv.y) * 2.0 + 4.0)
  );
  
  gl_FragColor = vec4(color * 0.3, 1.0);
}
""";
}