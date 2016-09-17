public class Heatmap {
  
    private String title = "TITLE";
    private PVector position;
    private int width,
                height;
    
    private PImage heatmap,
                   //gradientMap,
                   heatmapBrush,
                   heatmapColors;
    private float maxValue = 0;
    private boolean visible = false;
  
    Heatmap(int x, int y, int width, int height) {
        this.position = new PVector(x, y);
        this.width = width;
        this.height = height;
    }
    
    
    public void setBrush(String brush, int brushSize) {
        heatmapBrush = loadImage(brush);
        heatmapBrush.resize(brushSize, brushSize);
    }
    
    
    public void setGradient(String gradient) {
        heatmapColors = loadImage(gradient);
    }
  
    public void setVisibility(boolean v) {
        visible = v;
    }
    
    
    public void toggleVisibility() {
        visible = !visible;
    }
    
    
    public boolean isVisible() {
        return visible;
    }
  
  
    public void update(String title, ArrayList objects) {
        this.title = title;
        if(visible) {
            PImage gradientMap = createImage(width, height, ARGB);
            gradientMap.loadPixels();
            for(int i = 0; i < objects.size(); i++) {
                Placeable obj = (Placeable) objects.get(i);
                PVector position = obj.getPosition();
                gradientMap = addGradientPoint(gradientMap, position.x, position.y);
            }
            heatmap = colorize(gradientMap);
            gradientMap.updatePixels();
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
  
  
    public PImage colorize(PImage gradientMap) {
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
        if(heatmap != null && visible) {
            image(heatmap, position.x, position.y);
            fill(#FFFFFF); noStroke(); textSize(10); textAlign(LEFT,BOTTOM);
            text(title, width - 135, height - 60);
            rect(width - 136, height - 56, 102, 22);
            image(heatmapColors, width - 135, height - 55, 100, 20);
        }
    }  
  
}