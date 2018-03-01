String city = "boston";

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
final String roadsUrl = "http://localhost/rest-api/v1/gis/roads?city="+city;
final String poisUrl = "http://localhost/rest-api/v1/gis/pois?city="+city;
final String bgPath = "img/bg/orto_small.jpg";


PVector[] bounds;
PVector[] roi;

void setup() {
    
    size(1300, 740, P2D);
    //fullScreen(P2D,1);
    //pixelDensity(2);
    smooth();
    
    myFont = createFont("Montserrat-Light", 32);
    
    if(city == "taipei"){
      bounds = new PVector[] {           //taipei
        new PVector(25.028193, 121.503148),
        new PVector(25.054953, 121.533344)
      };
      roi = new PVector[] {
        new PVector(25.045735, 121.5195),
        new PVector(25.0448, 121.5234),
        new PVector(25.0387, 121.5216),
        new PVector(25.0395, 121.5177)
      };
    }else if(city == "boston"){
      bounds = new PVector[] {            //boston
        new PVector(42.351179, -71.110316),
        new PVector(42.374849, -71.065082)
      };
      roi = new PVector[] {
        new PVector(31.2877,121.5040),
        new PVector(31.2866,121.5074),
        new PVector(31.2811,121.5050),
        new PVector(31.2824,121.5013)
      };
    }else if(city == "shanghai"){
      bounds = new PVector[] {           //shanghai
        new PVector(31.254672, 121.478221),
        new PVector(31.301413, 121.544734)
      };
      roi = new PVector[] {
        new PVector(42.3688, -71.0885),
        new PVector(42.3676, -71.0733),
        new PVector(42.3589, -71.0792),
        new PVector(42.3603, -71.0908)
      }; 
    }else if(city == "andorra"){
      bounds = new PVector[] {           //andorra
        new PVector(42.483890,1.490903),
        new PVector(42.533596,1.572099)
      };
      roi = new PVector[] {
        new PVector(42.505086, 1.509961),
        new PVector(42.517066, 1.544024),
        new PVector(42.508161, 1.549798),
        new PVector(42.496164, 1.515728)
      };
    }
    
    //BG = loadImage(bgPath);
    if(surfaceMode) {
        simWidth = BG.width;
        simHeight = BG.height;
        
        surface = new WarpSurface(this, 900, 300, 10, 5);
        surface.loadConfig();
        canvas = new Canvas(this, simWidth, simHeight, bounds, roi);
        
    } else {
        //BG.resize(simWidth, simHeight);
        canvas = createGraphics(simWidth, simHeight);
    }
    
    roads = new Roads(roadsUrl, simWidth, simHeight, bounds);
    
    pois = new POIs();
   /* pois.add(new Cluster(roads, "encamp", "Encamp", new PVector(910, 120), "canillo", 300));
    pois.add(new Cluster(roads, "canillo", "Canillo", new PVector(950, 50), null, 300));
    pois.add(new Cluster(roads, "lamassana", "La Massana", new PVector(500, 30), "ordino", 300));
    pois.add(new Cluster(roads, "ordino", "Ordino", new PVector(600, 50), null, 300));
    pois.add(new Cluster(roads, "stjulia", "Sant Julià de Lòria", new PVector(100, 820), null, 300));*/
    pois.loadJSON(poisUrl, roads);
    
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
    
    /*if(showBG) canvas.image(BG, 0, 0);
    else roads.draw(canvas, 1, #E0E3E5);*/
    roads.draw(canvas, 1, #D6D7D8);
    
    agents.draw(canvas);
    heatmap.draw(canvas, width - 135, height - 50);
    
    canvas.endDraw();
    
    if(surfaceMode) surface.draw((Canvas)canvas);
    else image(canvas, 0, 0);

    fill(#000000);
    textFont(myFont); textSize(10); textAlign(LEFT, TOP); textLeading(15);
    text("Agents: " + agents.count() + "\nSpeed: " + (run ? agents.getSpeed() : "[PAUSED]") + "\nFramerate: " + round(frameRate) + "fps", 20, 20);
    agents.printLegend(canvas, 20, 70);
    
    fill(#000000);
    textFont(myFont); textSize(25); textAlign(LEFT, TOP); textLeading(15);
    text(city.toUpperCase(), 20, 700);

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