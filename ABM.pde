PFont myFont;

PImage BG;
boolean showBG = false;

Roads roads;

Agents agents;
POIs pois;

Heatmap heatmap;

Path debugPath;
Node debugNode;

boolean run = false;

POI poi;

void setup() {
    
    size(1000, 800, P2D);
    //fullScreen(P2D);
    pixelDensity(2);
    
    myFont = createFont("Montserrat-Light", 32);
    
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
    
    background(255);
    
    if(run) agents.move();
    
    if(showBG) image(BG, 0, 0);
    else roads.draw(1, #F0F3F5);
    
    pois.draw();
    agents.draw();
    
    heatmap.draw(width - 135, height - 50);
    
    fill( showBG ? #FFFFFF : #000000);
    textFont(myFont); textSize(10); textAlign(LEFT, TOP); textLeading(15);
    text("Agents: " + agents.count() + "\nSpeed: " + (run ? agents.getSpeed() : "[PAUSED]") + "\nFramerate: " + round(frameRate) + "fps", 20, 20);
    
    agents.printLegend(20, 70);
    
    //if(debugPath.available()) debugPath.draw(2, #FF0000);
    
    /*
    PVector mousePoint = new PVector(mouseX, mouseY);
    ArrayList<Agent> mouseAgents = agents.filter(Filters.closeToPoint(mousePoint, 200));
    for(Agent agent : mouseAgents) {
        PVector pos = agent.getPosition();
        stroke(#FF0000);
        line(mousePoint.x, mousePoint.y, pos.x, pos.y);
    }
    */
    
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
    }
    
}


void mouseClicked() {
    
    agents.select(mouseX, mouseY);
    pois.select(mouseX, mouseY);
    //roads.select(mouseX, mouseY);
    
    /*
    for(Node node : roads.nodes) {
        if(node.selected) {
            if(debugNode != null) {
                debugPath.findPath(roads.nodes, debugNode, node);
                debugNode = node;
            }
            else debugNode = node;
            break;
        }
    }
    */
}