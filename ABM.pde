PFont myFont;

PImage BG;

Roads roads;

Agents agents;
PointsOfInterest pois;

Heatmap heatmap;

Path debugPath;
Node debugNode;

boolean run = false;

POI poi;

void setup() {
    
    size(1000, 851, P2D);
    //fullScreen(P2D);
    pixelDensity(2); // Reduce fps to half
    
    myFont = createFont("Montserrat-Light", 32);
    
    //BG = loadImage("img/bg/ortoEPSG3857lowRes.jpg");
    //BG.resize(width, height);
    
    roads = new Roads("json/roads.geojson");
    
    pois = new PointsOfInterest(this, roads);
    //pois.loadFromJSON("json/pois.json");
    pois.loadFromCSV("restaurants_mini.tsv");
    
    agents = new Agents(this, roads);
    agents.setSpeed(0.1, 5);
    agents.loadFromJSON("json/clusters.json");
    
    heatmap = new Heatmap(0, 0, width, height);
    heatmap.setBrush("img/heatmap/brush_80x80.png", 80);
    heatmap.addGradient("heat", "img/heatmap/heat.png");
    heatmap.addGradient("cool", "img/heatmap/cool.png");
    
    //debugPath = new Path(roads);
    
}


void draw() {
    
    background(255);
    
    if(BG != null) image(BG, 0, 0);
    
    if(run) agents.move();
    roads.draw(1, #F0F3F5);
    pois.draw();
    agents.draw();
    heatmap.draw();
    
    fill(0);
    textFont(myFont); textSize(10); textAlign(LEFT, TOP); textLeading(15);
    text("Agents: " + agents.count() + "\nSpeed: " + (run ? agents.getSpeed() : "[PAUSED]") + "\nFramerate: " + round(frameRate) + "fps", 20, 20);
    
    agents.printLegend(20, 70);
    pois.printLegend(200, 70);
    
    //if(debugPath.available()) debugPath.draw(2, #FF0000);
    
    /*
    ArrayList<Agent> farAgents = agents.filter(closeToCenter);
    for(Agent agent : farAgents) {
        stroke(#FF0000);
        PVector pos = agent.getPosition();
        line(width/2, height/2, pos.x, pos.y);
    }
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
            heatmap.update("Nodes Density", roads.getNodes(), "cool");
            break;
    }
    
}


void mouseClicked() {
    
    agents.select(mouseX, mouseY);
    pois.select(mouseX, mouseY);
    roads.select(mouseX, mouseY);
    
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