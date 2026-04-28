import processing.serial.*;
import java.awt.Robot;
import java.awt.AWTException;
import java.awt.Rectangle;
import java.awt.image.BufferedImage;
import java.awt.Dimension;
import java.awt.Toolkit;

Serial port;
Robot robot;

String portName = "COM5";
int baudRate = 9600;

// get full screen size
Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
int screenW = screenSize.width;
int screenH = screenSize.height;

// detection box
int boxW = 14;
int boxH = 14;

// place box near center of screen
int sampleX = screenW / 2 - boxW / 2;
int sampleY = screenH / 2 - boxH / 2;

// detection variables
float previousBrightness = 0;
float currentBrightness = 0;
float diff = 0;

// threshold for detecting muzzle flash
float triggerThreshold = 28;

// cooldown to avoid repeated triggers from one flash
int cooldownMs = 90;
int lastTriggerTime = 0;

void setup() {
  size(500, 260);
  port = new Serial(this, portName, baudRate);

  try {
    // Creates a Robot object
    // This lets Processing read pixels
    // from anywhere on your actual computer screen
    robot = new Robot();
  } 
  catch (AWTException e) {
    // If Robot fails to initialize,
    // print the error and stop the program
    e.printStackTrace();
    exit();
  }
  textSize(16);
}


void draw() {
  background(0);
  // sampleX, sampleY = position
  // boxW, boxH = size of detection area
  BufferedImage img =
    robot.createScreenCapture(
      new Rectangle(sampleX, sampleY, boxW, boxH)
    );
  // Calculate average brightness
  // inside that detection box
  currentBrightness = getAverageBrightness(img);
  diff = currentBrightness - previousBrightness;
  
  // If brightness jumps enough
  // AND cooldown has expired run this
  if (diff > triggerThreshold &&
      millis() - lastTriggerTime > cooldownMs) {
    // Send '1' to Arduino
    // This triggers NeoPixel strip
    port.write('1');
    // Store trigger time so one shot
    // doesn't fire repeatedly
    lastTriggerTime = millis();
  }
  // Save brightness for next frame comparison
  previousBrightness = currentBrightness;


  //  DEBUG INFO
  // Displays live values in Processing window
  fill(255); // white text
  text("Screen: " + screenW + " x " + screenH, 20, 30);
  text("Sample Box: " + sampleX + ", " + sampleY, 20, 60);
  text("Box Size: " + boxW + " x " + boxH, 20, 90);
  text("Brightness: " + nf(currentBrightness, 0, 2),20, 120);
  text("Difference: " + nf(diff, 0, 2),20, 150);
  text("Threshold: " + triggerThreshold,20, 180);
  text("Cooldown: " + cooldownMs + " ms",20, 210);
  text("Move box with arrow keys",20, 240);
}
// Function that calculates average brightness
// inside sampled pixel region
float getAverageBrightness(BufferedImage img) {

  float total = 0;

  // Loop through every pixel
  // in detection box
  for (int x = 0; x < img.getWidth(); x++) {
    for (int y = 0; y < img.getHeight(); y++) {
      // Get RGB value of one pixel
      int rgb = img.getRGB(x, y);
      // Extract RED value
      int r = (rgb >> 16) & 0xFF;
      // Extract GREEN value
      int g = (rgb >> 8) & 0xFF;
      // Extract BLUE value
      int b = rgb & 0xFF;
      // Compute brightness of this pixel
      // using average of RGB channels
      total += (r + g + b) / 3.0;
    }
  }
  // Return average brightness
  // across all pixels in box
  return total /(img.getWidth() * img.getHeight());
}
void keyPressed() {

  //  MOVE DETECTION BOX 
  // Arrow keys move detection area
  // so you can line it up
  // with muzzle flash

  if (keyCode == LEFT)
    sampleX -= 2;

  if (keyCode == RIGHT)
    sampleX += 2;

  if (keyCode == UP)
    sampleY -= 2;

  if (keyCode == DOWN)
    sampleY += 2;
    
  //  RESIZE DETECTION BOX 

  // W makes box taller
  if (key == 'w')
    boxH++;

  // S makes box shorter
  // but never below 2 pixels
  if (key == 's')
    boxH = max(2, boxH - 1);

  // D makes box wider
  if (key == 'd')
    boxW++;

  // A makes box narrower
  if (key == 'a')
    boxW = max(2, boxW - 1);

  //  ADJUST SENSITIVITY 

  // = increases threshold
  // harder to trigger
  if (key == '=')
    triggerThreshold++;

  // - lowers threshold
  // easier to trigger
  if (key == '-')
    triggerThreshold =
      max(1, triggerThreshold - 1);
}
