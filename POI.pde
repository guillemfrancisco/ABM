/**
* POIs - Facade to simplify manipulation of Pois of Interest in simulation
* @author        Marc Vilella
* @version       1.0
* @see           Facade
*/
public class POIs extends Facade {

    /**
    * Initiate pois of interest facade and agents' Factory
    * @param parent  Sketch applet, just put this when calling constructor
    */
    public POIs(PApplet parent) {
        super(parent);
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
            boolean cluster  = props.isNull("CLUSTER") ? false : props.getInt("CLUSTER") == 1 ? true : false;
            
            JSONArray coords = poi.getJSONObject("geometry").getJSONArray("coordinates");
            PVector location = roads.toXY( coords.getFloat(1), coords.getFloat(0) );
                
            if( roads.contains(location) ) {
                pois.add( new POI(roads, count, location, name, capacity) );
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
                pois.add( new POI(roads, count, location, name, capacity) );
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

    private final int POI_ID;
    private final String NAME;
    private final int CAPACITY;
    
    private ArrayList<Agent> crowd = new ArrayList();
    private float occupancy;
    
    private float size = 2;
    
    
    /**
    * Initiate POI with specific name and capacity, and places it in the roadmap
    * @param roads  Roadmap to place the POI
    * @param id  ID of the POI
    * @param position  Position of the POI
    * @param name  name of the POI
    * @param capacity  Customers capacity of the POI
    */
    public POI(Roads roads, int id, PVector position, String name, int capacity) {
        super(position);
        POI_ID = id;
        NAME = name;
        CAPACITY = capacity;
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
    * @param canvas  Canvas to draw POI
    */
    @Override
    public void draw(PGraphics canvas) {
        
        /*
        color c = lerpColor(#77DD77, #FF6666, occupancy);
        
        canvas.rectMode(CENTER); canvas.noFill(); canvas.stroke(c); canvas.strokeWeight(2);
        canvas.rect(position.x, position.y, size, size);
        */
        if( selected ) {
            canvas.fill(0); canvas.textAlign(CENTER, BOTTOM);
            canvas.text(this.toString(), position.x, position.y - size / 2);
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
        selected = dist(position.x, position.y, mouseX, mouseY) <= size;
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
}