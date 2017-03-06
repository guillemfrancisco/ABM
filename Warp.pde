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

    
    //public void draw(WarpTexture wt) {
    public void draw(Canvas canvas) {
        
        //PImage img = wt.getImage();
        PVector[] roi = canvas.getROI();
        
        for(int y = 0; y < rows -1; y++) {
            
            // y line anchors
            PVector y_L = PVector.lerp(roi[0], roi[3], (float)y / (rows-1));
            PVector y_R = PVector.lerp(roi[1], roi[2], (float)y / (rows-1));
            // (y+1) line anchors
            PVector y1_L = PVector.lerp(roi[0], roi[3], (float)(y+1) / (rows-1));
            PVector y1_R = PVector.lerp(roi[1], roi[2], (float)(y+1) / (rows-1));
            
            beginShape(TRIANGLE_STRIP);
            texture(canvas);
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


public class Canvas extends PGraphics2D {

    private PVector[] bounds;
    private PVector[] roi;
    
    public Canvas(PApplet parent, int w, int h, PVector[] bounds) {
        setParent(parent);
        setPrimary(false);
        setPath(parent.dataPath(""));
        setSize(w, h);
        
        setBounds(bounds);
        roi = new PVector[] {
            new PVector(0, 0),
            new PVector(this.width, 0),
            new PVector(this.width, this.height),
            new PVector(0, this.height)
        };
    }
    
    
    public void setBounds(PVector[] bounds) {
        if(bounds.length == 2) this.bounds = bounds;
    }
    
    
    public void setROI(PVector[] roi) {
        if(roi.length == 4) {
            for(int i = 0; i < 4; i++) {
                this.roi[i] = new PVector(
                    map(roi[i].y, bounds[0].y, bounds[1].y, 0, this.width),
                    map(roi[i].x, bounds[0].x, bounds[1].x, this.height, 0)
                );
            }
        }
    }
    
    
    public PVector[] getROI() {
        return roi;
    }
    
}