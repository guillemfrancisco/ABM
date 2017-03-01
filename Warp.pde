public class WarpTexture {

    private PVector[] bounds;
    private PVector[] roi = new PVector[4];
    private PImage image;
    
    public WarpTexture(String imagePath, int w, int h, float TLy, float TLx, float BRy, float BRx) {
        image = loadImage(imagePath);
        image.resize(w, h);
        bounds = new PVector[] { new PVector(TLx, TLy), new PVector(BRx, BRy) };
        roi = new PVector[] {
            new PVector(0, 0),
            new PVector(image.width, 0),
            new PVector(image.width, image.height),
            new PVector(0, image.height)
        };
    }
    
    public void setROI(PVector[] roiLatLon) {
        if(roiLatLon.length == 4) {
            for(int i = 0; i < 4; i++) {
                roi[i] = new PVector(
                    map(roiLatLon[i].y, bounds[0].x, bounds[1].x, 0, image.width),
                    map(roiLatLon[i].x, bounds[0].y, bounds[1].y, image.height, 0)
                );
            }
        }
    }
    
    
    public void update(String imagePath) {
        image = loadImage(imagePath);
    }
    
    public void update(PGraphics graphics) {
        image = graphics;
    }
    
    
    public PImage getImage() {
        return image;
    }
    
    public PVector[] getROI() {
        return roi;
    }
    
    public void draw() {
        pushMatrix();
        scale(0.4);
        image(image,0,0);
        beginShape();
        stroke(#FF0000); noFill();
        for(PVector vertex : roi) {
            vertex(vertex.x, vertex.y);
        }
        endShape(CLOSE);
        popMatrix();
    }
    
}



public class WarpSurface {
    
    private PVector[][] points;
    private int cols, rows;
    
    private boolean calibrateMode;
    
    public WarpSurface(PApplet parent, float width, float height, int cols, int rows) {
        
        this.cols = cols;
        this.rows = rows;
        
        float initX = parent.width / 2 - width / 2;
        float initY = parent.height / 2 - height / 2;
        float dX = width / (cols - 1);
        float dY = height / (rows - 1);
        
        points = new PVector[rows][cols];
        for(int x = 0; x < cols; x++) {
            for(int y = 0; y < rows; y++) {
                points[y][x] = new PVector(initX + x * dX, initY + y * dY);
            }
        }
    }

    
    public void draw(WarpTexture wt) {
        
        PImage img = wt.getImage();
        PVector[] roi = wt.getROI();
        
        for(int y = 0; y < rows -1; y++) {
            
            // y line anchors
            PVector y_L = PVector.lerp(roi[0], roi[3], (float)y / (rows-1));
            PVector y_R = PVector.lerp(roi[1], roi[2], (float)y / (rows-1));
            // (y+1) line anchors
            PVector y1_L = PVector.lerp(roi[0], roi[3], (float)(y+1) / (rows-1));
            PVector y1_R = PVector.lerp(roi[1], roi[2], (float)(y+1) / (rows-1));
            
            beginShape(TRIANGLE_STRIP);
            texture(img);
            for(int x = 0; x < cols; x++) {
                
                PVector x_y = PVector.lerp(y_L, y_R, (float)x / (cols-1));
                PVector x_y1 = PVector.lerp(y1_L, y1_R, (float)x / (cols-1));
                
                if(calibrateMode) {
                    stroke(#FF0000);
                    strokeWeight(0.5);
                } else noStroke();
                
                vertex(points[y][x].x, points[y][x].y, x_y.x, x_y.y);
                vertex(points[y+1][x].x, points[y+1][x].y, x_y1.x, x_y1.y);
            }
            endShape();
        }
        
        if(calibrateMode) {
           stroke(#FF0000); strokeWeight(1);
           for(int y = 0; y < rows; y++) {
                for(int x = 0; x < cols; x++) {
                    int size = 7;
                    if( dist(points[y][x].x, points[y][x].y, mouseX, mouseY) < 7 ) {
                        fill(#FF0000, 100);
                        size = 14;
                        if(mousePressed) {
                            points[y][x].x = mouseX;
                            points[y][x].y = mouseY;
                        }
                    } else noFill();
                    ellipse(points[y][x].x, points[y][x].y, size, size);
                }
            }
        }
    }
    
    public void toggleCalibration() {
        calibrateMode = !calibrateMode;
    }
    
    public boolean isCalibrating() {
        return calibrateMode;
    }
    
    
    public void loadConfig() {
        XML settings = loadXML(sketchPath("warp.xml"));
        XML size = settings.getChild("size");
        rows = size.getInt("rows");
        cols = size.getInt("cols");
        XML[] xmlPoints = settings.getChild("points").getChildren("point");
        points = new PVector[rows][cols];
        for(int i = 0; i < xmlPoints.length; i++) {
            int x = i % cols;
            int y = i / cols;
            points[y][x] = new PVector(xmlPoints[i].getFloat("x"), xmlPoints[i].getFloat("y"));
        }
    }
    
    public void saveConfig() {
        XML settings = new XML("settings");
        XML size = settings.addChild("size");
        size.setInt("cols", cols);
        size.setInt("rows", rows);
        XML xmlPoints = settings.addChild("points");
        for(int y = 0; y < rows; y++) {
            for(int x = 0; x < cols; x++) {
                XML point = xmlPoints.addChild("point");
                point.setFloat("x", points[y][x].x);
                point.setFloat("y", points[y][x].y);
            }
        }
        saveXML(settings, "warp.xml");
    }
    
}