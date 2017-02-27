/**
* POIs - Facade to simplify manipulation of Pois of Interest in simulation
* @author        Marc Vilella
* @version       1.0
* @see           Facade
*/
public class POIs extends Facade {

    /**
    * Initiate pois of interest facade and agents' Factory
    * @param roads  Roadmap where agents will be placed and move
    */
    public POIs(Roads roadmap) {
        super(roadmap);
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
        
        JSONArray clusters = loadJSONArray(JSONFile);
        for(int i = 0; i < clusters.size(); i++) {
            JSONObject cluster = clusters.getJSONObject(i);
            
            String type        = cluster.getString("type");
            String clusterName = cluster.getString("name");
            JSONObject style   = cluster.getJSONObject("style");
            String tint        = style.getString("color");
            int size           = style.getInt("size");
            
            JSONArray items   = cluster.getJSONArray("items");
            for(int j = 0; j < items.size(); j++) {
                JSONObject item = items.getJSONObject(j);
                
                int id              = item.getInt("id");
                String name         = item.getString("name");
                PVector location    = roads.toXY(
                                        item.getJSONArray("location").getFloat(1),
                                        item.getJSONArray("location").getFloat(0)
                                    );
                int capacity        = item.getInt("capacity");
                JSONArray languages = item.getJSONArray("languages");
                
                if( location.x > 0 && location.x < width && location.y > 0 && location.y < height ) {
                    pois.add( new POI(roads, count, location, name, capacity) );
                    counter.increment(clusterName);
                    count++;
                }
                
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
            
            if( location.x > 0 && location.x < width && location.y > 0 && location.y < height ) {
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
public class POI implements Placeable {

    private final int ID;
    private final String NAME;
    private final PVector POSITION;
    private final int CAPACITY;
    private Node NODE;
    
    private ArrayList<Agent> crowd = new ArrayList();
    private float occupancy;
    private boolean selected;
    
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
        ID = id;
        NAME = name;
        CAPACITY = capacity;
        POSITION = position;
        place(roads);
    }
    
    
    /**
    * Create a node in the roadmap linked to the POI and connects it to the closest lane
    * @param roads  Roadmap to add the POI
    */
    public void place(Roads roads) {
        NODE = roads.connect(POSITION);
    } 
    
    
    /**
    * Get POI position in screen
    * @return POI position
    */
    public PVector getPosition() {
        return POSITION;
    }
    
    
    /**
    * Get POI associated node
    * @return associated node
    */
    public Node getNode() {
        return NODE;
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
    */
    public void draw() {
        
        color c = lerpColor(#77DD77, #FF6666, occupancy);
        
        rectMode(CENTER); noFill(); stroke(c); strokeWeight(2);
        rect(POSITION.x, POSITION.y, size, size);
        
        if( selected ) {
            fill(0); textAlign(CENTER, BOTTOM);
            text(this.toString(), POSITION.x, POSITION.y - size / 2);
        }

    }


    /**
    * Select POI if mouse is hover
    * @param mouseX  Horizontal mouse position in screen
    * @param mouseY  Vertical mouse position in screen
    * @return true if POI is selected, false otherwise
    */
    public boolean select(int mouseX, int mouseY) {
        selected = dist(POSITION.x, POSITION.y, mouseX, mouseY) <= size;
        return selected;
    }
    
    
    /**
    * Return agent description (NAME, OCCUPANCY and CAPACITY)
    * @return POI description
    */
    public String toString() {
        return NAME + " [" + crowd.size() + " / " + CAPACITY + "]";
    }
    

}