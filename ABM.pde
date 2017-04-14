PFont myFont;

Roads roads;
Agents agents;
POIs pois;
Heatmap heatmap;
boolean run = false;

PImage BG;
boolean showBG = true;
boolean surfaceMode = false;

// PROJECTION 3D MODEL
WarpSurface surface;
//Canvas canvas;
PGraphics canvas;

// SIMULACIÓ FONS DE VALL
int simWidth = 1000;
int simHeight = 847;
final String roadsPath = "json/roads.geojson";
final String bgPath = "img/bg/orto_small.jpg";
final PVector[] bounds = new PVector[] {
    new PVector(42.482119, 1.489794),
    new PVector(42.533768, 1.572122)
};
PVector[] roi = new PVector[] {
    new PVector(42.505086, 1.509961),
    new PVector(42.517066, 1.544024),
    new PVector(42.508161, 1.549798),
    new PVector(42.496164, 1.515728)
};


void setup() {
    
    //size(1000, 745, P2D);
    fullScreen(P2D,1);
    //pixelDensity(2);
    smooth();
    
    myFont = createFont("Montserrat-Light", 32);
    
    BG = loadImage(bgPath);
    if(surfaceMode) {
        simWidth = BG.width;
        simHeight = BG.height;
        
        surface = new WarpSurface(this, 900, 300, 10, 5);
        surface.loadConfig();
        canvas = new Canvas(this, simWidth, simHeight, bounds, roi);
        
    } else {
        BG.resize(simWidth, simHeight);
        canvas = createGraphics(simWidth, simHeight);
    }
    
    roads = new Roads(roadsPath, simWidth, simHeight, bounds);
    
    pois = new POIs();
    pois.add(new Cluster(roads, "encamp", "Encamp", new PVector(910, 120), "canillo", 300));
    pois.add(new Cluster(roads, "canillo", "Canillo", new PVector(950, 50), null, 300));
    pois.add(new Cluster(roads, "lamassana", "La Massana", new PVector(500, 30), "ordino", 300));
    pois.add(new Cluster(roads, "ordino", "Ordino", new PVector(600, 50), null, 300));
    pois.add(new Cluster(roads, "stjulia", "Sant Julià de Lòria", new PVector(100, 820), null, 300));
    //pois.loadJSON("json/pois.geojson", roads);
    pois.loadCSV("restaurants.csv", roads);
    pois.loadCSV("parkings.csv", roads);
    
    agents = new Agents();
    agents.loadJSON("json/agents.json", roads);
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
    else roads.draw(canvas, 1, #E0E3E5);
    
    agents.draw(canvas);
    heatmap.draw(canvas, width - 135, height - 50);
    
    canvas.endDraw();
    
    if(surfaceMode) surface.draw((Canvas)canvas);
    else image(canvas, 0, 0);

    fill(#000000);
    textFont(myFont); textSize(10); textAlign(LEFT, TOP); textLeading(15);
    text("Agents: " + agents.count() + "\nSpeed: " + (run ? agents.getSpeed() : "[PAUSED]") + "\nFramerate: " + round(frameRate) + "fps", 20, 20);
    agents.printLegend(canvas, 20, 70);

    /*
    fill(0);
    text("Agents moving: " + agents.count(Filters.isMoving(false)), 20, 200);
    */

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
            //if( surface.isCalibrating() ) surface.saveConfig();  // Avoid overriding tested calibration
            break;
        case 'l':
            if( surface.isCalibrating() ) surface.loadConfig();
            break;
        case 'w':
            surface.toggleCalibration();
            break;
    }
    
}


void mouseClicked() {
    agents.select(mouseX, mouseY);
    pois.select(mouseX, mouseY);
    //roads.select(mouseX, mouseY);
}