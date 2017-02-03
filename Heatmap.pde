public enum Visibility { HIDE, SHOW, TOGGLE; }

public class Heatmap {
    
    private String title = "TITLE";
    private final PVector POSITION;
    private final int WIDTH, HEIGHT;
    
    private PImage heatmap, heatmapBrush;
    private HashMap<String, PImage> gradients = new HashMap<String, PImage>();               
                   
    private float maxValue = 0;
    private boolean visible = false;
  
    Heatmap(int x, int y, int _width, int _height) {
        POSITION = new PVector(x, y);
        WIDTH = _width;
        HEIGHT = _height;
        
        // Default B/W gradient
        PImage defaultGradient = createImage(255, 1, RGB);
        //defaultGradient.loadPixels();
        for(int i = 0; i < defaultGradient.pixels.length; i++) defaultGradient.pixels[i] = color(i, i, i); 
        //defaultGradient.updatePixels();
        gradients.put("default", defaultGradient);
        
    }
    
    
    public void setBrush(String imagePath, int brushSize) {
        heatmapBrush = loadImage(imagePath);
        heatmapBrush.resize(brushSize, brushSize);
    }
    
    
    public void addGradient(String name, String imagePath) {
        File file = new File(dataPath(imagePath));
        if( file.exists() ) gradients.put(name, loadImage(imagePath));
    }
  
  
    public void visible(Visibility v) {
        switch(v) {
            case HIDE:
                visible = false;
                break;
            case SHOW:
                visible = true;
                break;
            case TOGGLE:
                visible = !visible;
                break;
        }
    }
    
    
    public boolean isVisible() {
        return visible;
    }
  
  
    public void update(String title, ArrayList objects) {
        update(title, objects, "default");
    }
    
    
    public void update(String _title, ArrayList objects, String gradient) {
        maxValue = 0;
        title = _title;
        if(visible) {
            PImage gradientMap = createImage(WIDTH, HEIGHT, ARGB);
            gradientMap.loadPixels();
            for(int i = 0; i < objects.size(); i++) {
                Placeable obj = (Placeable) objects.get(i);
                PVector position = obj.getPosition();
                gradientMap = addGradientPoint(gradientMap, position.x, position.y);
            }
            gradientMap.updatePixels();
            PImage gradientColors = gradients.containsKey(gradient) ? gradients.get(gradient) : gradients.get("default");
            heatmap = colorize(gradientMap, gradientColors);
        }
    }
    
  
    public PImage addGradientPoint(PImage img, float x, float y) {
        int startX = int(x - heatmapBrush.width / 2);
        int startY = int(y - heatmapBrush.height / 2);
        for(int pY = 0; pY < heatmapBrush.height; pY++) {
            for(int pX = 0; pX < heatmapBrush.width; pX++) {
                int hmX = startX + pX;
                int hmY = startY + pY;
                if( hmX < 0 || hmY < 0 || hmX >= img.width || hmY >= img.height ) continue;
                int c = heatmapBrush.pixels[pY * heatmapBrush.width + pX] & 0xff;
                int i = hmY * img.width + hmX;
                if(img.pixels[i] < 0xffffff - c) {
                    img.pixels[i] += c;
                    if(img.pixels[i] > maxValue) maxValue = img.pixels[i];
                }
            }
        }
        return img;
    }
  
  
    public PImage colorize(PImage gradientMap, PImage heatmapColors) {
        PImage heatmap = createImage(width, height, ARGB);
        heatmap.loadPixels();
        for(int i=0; i< gradientMap.pixels.length; i++) {
            int c = heatmapColors.pixels[ (int) map(gradientMap.pixels[i], 0, maxValue, 0, heatmapColors.pixels.length-1) ];
            heatmap.pixels[i] = c;
        }    
        heatmap.updatePixels();
        return heatmap;
    }
  
  
    public void draw() {
        if(visible && heatmap != null) {
            pushStyle();
            blendMode(MULTIPLY);
            image(heatmap, POSITION.x, POSITION.y);
            popStyle();
            // Legend
            //fill(#FFFFFF); noStroke(); textSize(10); textAlign(LEFT,BOTTOM);
            //text(title, width - 135, height - 60);
            //rect(width - 136, height - 56, 102, 22);
            //image(heatmapColors, width - 135, height - 55, 100, 20);
        }
    }  
  
}