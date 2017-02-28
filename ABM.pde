PFont myFont;

WarpSurface model3D;
WarpTexture modelTexture;
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
    
    size(1000, 851, P2D);
    //fullScreen(P2D);
    pixelDensity(2);
    
    myFont = createFont("Montserrat-Light", 32);
    
    model3D = new WarpSurface(this, 900, 300, 10, 5);
    model3D.loadConfig();
    modelTexture = new WarpTexture("img/bg/ortoEPSG3857lowRes_small.jpg", 42.482114, 1.489787, 42.533772, 1.572123);
    modelTexture.setROI(roi);
    
    canvas = createGraphics(width, height, P2D);
    
    BG = loadImage("img/bg/ortoEPSG3857lowRes.jpg");
    BG.resize(width, height);
    
    roads = new Roads("json/roads.geojson");
    
    pois = new POIs(this);
    //pois.loadJSON("json/pois.json");
    pois.loadCSV("restaurants_mini.tsv", roads);
    
    agents = new Agents(this);
    agents.loadJSON("json/clusters.json", roads);
    agents.setSpeed(0.1, 5);
    
    heatmap = new Heatmap(0, 0, width, height);
    heatmap.setBrush("img/heatmap/brush_80x80.png", 40);
    heatmap.addGradient("heat", "img/heatmap/heat.png");
    heatmap.addGradient("cool", "img/heatmap/cool.png");
    
}


void draw() {
    
    background(0);
    
    if(run) agents.move();
    
    canvas.beginDraw();
    canvas.background(255);
    
    if(showBG) canvas.image(BG, 0, 0);
    else roads.draw(canvas, 1, #F0F3F5);
    pois.draw(canvas);
    agents.draw(canvas);
    heatmap.draw(canvas, width - 135, height - 50);
    
    canvas.fill( showBG ? #FFFFFF : #000000);
    canvas.textFont(myFont); canvas.textSize(10); canvas.textAlign(LEFT, TOP); canvas.textLeading(15);
    canvas.text("Agents: " + agents.count() + "\nSpeed: " + (run ? agents.getSpeed() : "[PAUSED]") + "\nFramerate: " + round(frameRate) + "fps", 20, 20);
    agents.printLegend(canvas, 20, 70);
    
    canvas.endDraw();
    image(canvas,0, 0);
    
    /*
    fill(0);
    text("Agents moving: " + agents.count(Filters.isMoving(false)), 20, 200);
    */
    
    //modelTexture.update(canvas);
    //model3D.draw(modelTexture);
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