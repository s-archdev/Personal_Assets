void setup() {
  size(400, 200);
  textAlign(CENTER, CENTER);
  textSize(48);
}

void draw() {
  background(20, 20, 30);  // Dark blue background
  
  // Get current time
  int h = hour();
  int m = minute();
  int s = second();
  
  // Format time with leading zeros
  String timeString = nf(h, 2) + ":" + nf(m, 2) + ":" + nf(s, 2);
  
  // Draw the time
  fill(0, 255, 150);  // Green digital clock color
  text(timeString, width/2, height/2);
  
  // Optional: Add blinking colon effect
  if (millis() % 1000 < 500) {
    fill(0, 255, 150, 150);  // Semi-transparent for blink effect
  } else {
    fill(0, 255, 150);
  }
  
  // Draw date below
  String dateString = nf(day(), 2) + "/" + nf(month(), 2) + "/" + year();
  textSize(24);
  fill(150, 150, 255);  // Light blue for date
  text(dateString, width/2, height/2 + 60);
}