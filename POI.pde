/**
* POIs - Facade to simplify manipulation of Pois of Interest in simulation
* @author        Marc Vilella
* @version       1.0
* @see           Facade
*/
public class POIs extends Facade<POI> {

    /**
    * Initiate pois of interest facade and agents' Factory
    * @param parent  Sketch applet, just put this when calling constructor
    */
    public POIs() {
        factory = new POIFactory();
    }
    
}



/**
* POIFactory - Factory to generate diferent Points of Interest from diferent sources 
* @author        Marc Vilella
* @version       1.0
* @see           Factory
*/
private class POIFactory extends Factory {
    
    /**
    * Load POIs form JSON file
    */
    public ArrayList<POI> loadJSON(File JSONFile, Roads roads) {
        
        print("Loading POIs... ");
        ArrayList<POI> pois = new ArrayList();
        int count = count();
        
        JSONArray JSONPois = loadJSONObject(JSONFile).getJSONArray("features");
        for(int i = 0; i < JSONPois.size(); i++) {
            JSONObject poi = JSONPois.getJSONObject(i);
            
            JSONObject props = poi.getJSONObject("properties");
            
            String name      = props.isNull("NAME") ? "null" : props.getString("NAME");
            int capacity  = props.isNull("CAPACITY") ? null : props.getInt("CAPACITY");
            
            JSONArray coords = poi.getJSONObject("geometry").getJSONArray("coordinates");
            PVector location = roads.toXY( coords.getFloat(1), coords.getFloat(0) );
                
            if( roads.contains(location) ) {
                pois.add( new POI(roads, str(count), name, location, capacity) );
                counter.increment("restaurant");
                count++;
            }
             
        }
        println("LOADED");
        return pois;  
    }
      
    
    /**
    * Load POIs form CSV file
    */
    public ArrayList<POI> loadCSV(String path, Roads roads) {
        
        print("Loading POIs... ");
        ArrayList<POI> pois = new ArrayList();
        int count = count();
        
        Table table = loadTable(path, "header, tsv");
        for(TableRow row : table.rows()) {
            
            String name         = row.getString("NAME");
            PVector location    = roads.toXY(row.getFloat("LAT"), row.getFloat("LNG"));
            int capacity        = row.getInt("CAPACITY");
            int size            = 3;
            
            if( roads.contains(location) ) {
                pois.add( new POI(roads, str(count), name, location, capacity) );
                counter.increment(path); 
                count++;
            }
        }
        println("LOADED");
        return pois;
    }
     
}



/**
* POI -  Abstract class describing a Point of Interest, that is a destination for agents in simulation
* @author        Marc Vilella
* @version       2.0
*/
public class POI extends Node {

    protected final String ID;
    protected final String NAME;
    protected final int CAPACITY;
    
    protected ArrayList<Agent> crowd = new ArrayList();
    protected float occupancy;
    
    private float size = 2;
    
    
    /**
    * Initiate POI with specific name and capacity, and places it in the roadmap
    * @param roads      Roadmap to place the POI
    * @param id         ID of the POI
    * @param position   Position of the POI
    * @param name       Name of the POI
    * @param capacity   Customers capacity of the POI
    */
    public POI(Roads roads, String id, String name, PVector position, int capacity) {
        super(position);
        ID = id;
        NAME = name;
        CAPACITY = capacity;
        
        place(roads);
    }
    
    
    /**
    * Place POI into roadmap, connected to closest point
    * @param roads    Roadmap to place the POI
    */
    @Override
    public void place(Roads roads) {
        roads.connect(this);
    }
    
    
    /**
    * Get POI drawing size
    * @return POI size
    */
    public float getSize() {
        return size;
    }
    
    
    /**
    * Add agent to the hosted list as long as POI's crowd is under its maximum capacity, meaning agent is staying in POI
    * @param agent  Agent to host
    * @return true if agent is hosted, false otherwise
    */
    public boolean host(Agent agent) {
        if(crowd.size() < CAPACITY) {
            crowd.add(agent);
            update();
            return true;
        }
        return false;
    }
    
    
    /**
    * Remove agent from hosted list, meaning agent has left the POI
    * @param agent  Agent to host
    */
    public void unhost(Agent agent) {
        crowd.remove(agent);
        update();
    }
    
    
    /**
    * Update POIs variables: occupancy and drawing size
    */
    protected void update() {
        occupancy = (float)crowd.size() / CAPACITY;
        size = (5 + 10 * occupancy);
    }
    
    
    /**
    * Draw POI in screen, with different effects depending on its status
    * @param canvas  Canvas to draw node
    * @param stroke  Lane width in pixels
    * @param c  Lanes color
    */
    @Override
    public void draw(PGraphics canvas, int stroke, color c) {
        
        color occColor = lerpColor(#77DD77, #FF6666, occupancy);
        
        canvas.rectMode(CENTER); canvas.noFill(); canvas.stroke(occColor); canvas.strokeWeight(2);
        canvas.rect(POSITION.x, POSITION.y, size, size);
        
        if( selected ) {
            canvas.fill(0); canvas.textAlign(CENTER, BOTTOM);
            canvas.text(this.toString(), POSITION.x, POSITION.y - size / 2);
        }

    }


    /**
    * Select POI if mouse is hover
    * @param mouseX  Horizontal mouse position in screen
    * @param mouseY  Vertical mouse position in screen
    * @return true if POI is selected, false otherwise
    */
    @Override
    public boolean select(int mouseX, int mouseY) {
        selected = dist(POSITION.x, POSITION.y, mouseX, mouseY) <= size;
        return selected;
    }
    
    
    /**
    * Return agent description (NAME, OCCUPANCY and CAPACITY)
    * @return POI description
    */
    @Override
    public String toString() {
        return NAME + " [" + crowd.size() + " / " + CAPACITY + "]";
    }
    
}


/**
* Cluster - Agrupation of POIs, that combines all their characteristics and has a bigger attraction effect. Its position in canvas
* is not defined in geographic files (GeoJSON) but by the user, and connect not the closest roadmap point but to a specific node that
* has a defined "direction" field that matchs with cluster id. Clusters can be chained with other Clusters.
* @author    Marc Vilella
* @version   1.0
* @see       POI
*/
public class Cluster extends POI {
    
    /**
    * Initiate Cluster with specific POI characteristics plus an id to connect to a specific node
    * @param roads     Roadmap to place the Cluster
    * @param id        ID of the Cluster
    * @param name      Name of the Cluster
    * @param position  Position of the Cluster
    * @param direction Next cluster to connect (if any)   
    * @param capacity  Customers capacity of the Cluster
    */
    public Cluster(Roads roads, String id, String name, PVector position, String direction, int capacity) {
        super(roads, id, name, position, capacity);
        setDirection(direction);
    }
    
    
    /**
    * Place Cluster into roadmap, connected to specific node
    * @param roads    Roadmap to place the POI
    */
    @Override
    public void place(Roads roads) {
        for(Node node : roads.nodes) {
            if(node.direction != null && ID.equals(node.direction)) {
                node.connectBoth(this, null, "Connection");
                roads.add(this);
                break;
            }
        }
    }
    
    
    /**
    * Draw CLuster in screen
    * @param canvas  Canvas to draw node
    * @param stroke  Lane width in pixels
    * @param c  Lanes color
    */
    @Override
    public void draw(PGraphics canvas, int stroke, color c) {
        canvas.ellipseMode(CENTER); canvas.noFill(); canvas.stroke(c); canvas.strokeWeight(2);
        canvas.ellipse(POSITION.x, POSITION.y, 75, 75);
        canvas.textAlign(CENTER, TOP); canvas.textSize(9); canvas.fill(c);
        canvas.text(NAME, POSITION.x, POSITION.y);
        for(Lane lane : lanes) {
            lane.draw(canvas, stroke, c);
        }
    }
    
}