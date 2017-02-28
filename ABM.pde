PFont myFont;

PGraphics canvas;
PImage BG;
boolean showBG = false;

Roads roads;
Agents agents;
POIs pois;
Heatmap heatmap;

boolean run = false;

void setup() {
    
    size(1000, 800, P2D);
    //fullScreen(P2D);
    pixelDensity(2);
    
    myFont = createFont("Montserrat-Light", 32);
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
    
    //debugPath = new Path(roads);
    
}


void draw() {
    
    background(#FFFFFF);
    
    if(run) agents.move();
    
    canvas.beginDraw();
    canvas.background(255, 0);
    
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
    
    /*
    fill(0);
    text("Agents moving: " + agents.count(Filters.isMoving(false)), 20, 200);
    */
    
    image(canvas, 0, 0);
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
    }
    
}


void mouseClicked() {
    
    agents.select(mouseX, mouseY);
    pois.select(mouseX, mouseY);
    //roads.select(mouseX, mouseY);
    
}