PFont myFont;

/*
final int simWidth = 1000;
final int simHeight = 851;
final PVector[] bounds = new PVector[] {
    new PVector(42.482114, 1.489787),
    new PVector(42.533772, 1.572123)
};
final String roadsPath = "json/roads.geojson";
final String bgPath = "img/bg/ortoEPSG3857_small.jpg";
*/

final int simWidth = 1000;
final int simHeight = 745;
final PVector[] bounds = new PVector[] {
    new PVector(42.4955, 1.5095),
    new PVector(42.5180, 1.5505)
};
final String roadsPath = "json/roads_cityscope.geojson";
final String bgPath = "img/bg/orto_cityscope_small.jpg";

WarpSurface model3D;
WarpTexture texture;

final PVector[] roi = new PVector[] {
    new PVector(42.505086, 1.509961),
    new PVector(42.517066, 1.544024),
    new PVector(42.508161, 1.549798),
    new PVector(42.496164, 1.515728)
};

PGraphics canvas;
PImage BG;
boolean showBG = true;

Roads roads;
Agents agents;
POIs pois;
Heatmap heatmap;

boolean run = false;

void setup() {
    
    //size(1000, 848, P2D);
    fullScreen(P2D);
    pixelDensity(2);
    smooth();
    
    myFont = createFont("Montserrat-Light", 32);
    
    model3D = new WarpSurface(this, 900, 300, 10, 5);
    model3D.loadConfig();
    texture = new WarpTexture(bgPath, simWidth, simHeight, bounds[0].x, bounds[0].y, bounds[1].x, bounds[1].y);
    texture.setROI(roi);
    
    canvas = createGraphics(simWidth, simHeight, P2D);
    
    BG = loadImage(bgPath);
    BG.resize(simWidth, simHeight);
    
    roads = new Roads(roadsPath, simWidth, simHeight, bounds);
    
    pois = new POIs(this);
    //pois.loadJSON("json/pois.json");
    pois.loadCSV("restaurants_mini.tsv", roads);
    
    agents = new Agents(this);
    agents.loadJSON("json/clusters.json", roads);
    agents.setSpeed(0.1, 5);
    
    heatmap = new Heatmap(0, 0, simWidth, simHeight);
    heatmap.setBrush("img/heatmap/brush_80x80.png", 40);
    heatmap.addGradient("heat", "img/heatmap/heat.png");
    heatmap.addGradient("cool", "img/heatmap/cool.png");
    
}


void draw() {
    
    background(255);
    
    if(run) agents.move();
    
    canvas.beginDraw();
    canvas.background(255);
    
    if(showBG) canvas.image(BG, 0, 0);
    else roads.draw(canvas, 1, #F0F3F5);
    
    pois.draw(canvas);
    agents.draw(canvas);
    heatmap.draw(canvas, width - 135, height - 50);
    
    canvas.fill(#000000);
    canvas.textFont(myFont); canvas.textSize(10); canvas.textAlign(LEFT, TOP); canvas.textLeading(15);
    canvas.text("Agents: " + agents.count() + "\nSpeed: " + (run ? agents.getSpeed() : "[PAUSED]") + "\nFramerate: " + round(frameRate) + "fps", 20, 20);
    agents.printLegend(canvas, 20, 70);
    
    /*
    fill(0);
    text("Agents moving: " + agents.count(Filters.isMoving(false)), 20, 200);
    */
    
    canvas.endDraw();
    //image(canvas, 0, 0, simWidth, simHeight);
    
    texture.update(canvas);
    //texture.draw();
    model3D.draw(texture);
    
    fill(0);
    text(frameRate, 20, 20);
    
}


void keyPressed() {

    switch(key) {
        case ' ':
            run = !run;
            break;
            
        case '+':
            agents.changeSpeed(0.1);
            break;
            
        case '-':
            agents.changeSpeed(-0.1);
            break;
            
        case 'a':
            heatmap.visible(Visibility.TOGGLE);
            heatmap.update("Agents Density", agents.getAll(), "heat");
            run = !heatmap.isVisible();
            break;
            
        case 'p':
            heatmap.visible(Visibility.TOGGLE);
            heatmap.update("Points of interest", pois.getAll(), "cool");
            break;
            
        case 'n':
            heatmap.visible(Visibility.TOGGLE);
            heatmap.update("Nodes Density", roads.getAll(), "cool");
            break;
            
        case 'b':
            showBG = !showBG;
            break;
        
        case 's':
            //if( model3D.isCalibrating() ) model3D.saveConfig();  // Avoid overriding tested calibration
            break;
        case 'l':
            if( model3D.isCalibrating() ) model3D.loadConfig();
            break;
        case 'w':
            model3D.toggleCalibration();
            break;
    }
    
}


void mouseClicked() {
    agents.select(mouseX, mouseY);
    pois.select(mouseX, mouseY);
    //roads.select(mouseX, mouseY);
}