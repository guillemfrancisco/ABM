PFont myFont;

Roads roads;

AgentFactory af;
ArrayList<Agent> agents = new ArrayList();

Heatmap heatmap;

Path mousePath;

boolean run = false;
float speed = 0.5;


POI poi;

void setup() {
    
    size(1200, 700, P2D);
    pixelDensity(2);
    
    myFont = createFont("Montserrat-Light", 32);
    
    roads = new Roads("json/roads_massive_simplified.geojson");
    //poi = new POI(roads.toXY(42.499123, 1.538010), "Test", 30);
    //roads.addPOI( poi );
    af = new AgentFactory();
    agents = af.loadFromJSON("json/clusters.json", roads);
    
    heatmap = new Heatmap(0, 0, width, height);
    heatmap.setBrush("img/brush_80x80.png", 80);
    heatmap.setGradient("img/gradient_tri.png");
    
    mousePath = new Path();
    
}


void draw() {
    
    background(255);
    
    roads.draw(1, #F0F3F5);
    
    for(Agent agent : agents) {
        if(run) agent.move(speed);
        agent.draw();
    }
    
    /*
    Edge street = roads.closestStreet( new PVector(mouseX, mouseY) );
    PVector point = roads.closestPoint(street, new PVector(mouseX, mouseY));
    stroke(#FF0000, 50);
    street.draw(1, #FF0000);
    line(mouseX, mouseY, point.x, point.y);
    */
    
    /*
    PVector point = roads.closestPoint(new PVector(mouseX, mouseY));
    stroke(#FF0000, 50);
    line(mouseX, mouseY, point.x, point.y);
    */
    
    /*
    Node endNode = roads.closestNode( new PVector(mouseX, mouseY) );
    PVector endPos = endNode.getPosition();
    PVector initPos = initNode.getPosition();
    fill(#FF0000); noStroke();
    ellipse(initPos.x, initPos.y, 7, 7);
    stroke(#FF0000); noFill();
    ellipse(endPos.x, endPos.y, 10, 10);
    
    stroke(#FF0000, 50);
    line(mouseX, mouseY, endPos.x, endPos.y);
    
    mousePath.findPath( roads.getNodes(), initNode, endNode);
    mousePath.draw(2, #FF0000);
    
    textAlign(LEFT, BOTTOM); fill(#550000);
    text( roads.toMeters( mousePath.getLength() ), endPos.x, endPos.y - 5);
    */
    
    /*
    stroke(#FF0000);
    //closest.draw(1, #FF0000);
    //PVector closest = roads.getClosestStreet( new PVector(mouseX, mouseY) );
    PVector closest = roads.closestPoint( new PVector(mouseX, mouseY) );
    line(mouseX, mouseY, closest.x, closest.y);
    */
    
    heatmap.draw();
    
    fill(0);
    textFont(myFont); textSize(12); textAlign(LEFT, TOP); textLeading(15);
    text(frameRate + "\nAgents: " + agents.size() + "\nSpeed: " + (run ? round(speed*10) : "[PAUSED]"), 20, 20);
    
    
}


void keyPressed() {

    switch(key) {
        case ' ':
            run = !run;
            break;
            
        case '+':
            speed += 0.1;
            break;
            
        case '-':
            if(speed - 0.1 >= 0) speed -= 0.1;
            break;
            
        case 'h':
            heatmap.toggleVisibility();
            heatmap.update("Agents Density", agents);
            run = !heatmap.isVisible();
            break;
            
        case 'p':
            heatmap.toggleVisibility();
            heatmap.update("Nodes Density", roads.getNodes());
            break;
    }
    
}


void mouseClicked() {
    
    for(Agent agent : agents) {
        agent.select();
    }
    
}